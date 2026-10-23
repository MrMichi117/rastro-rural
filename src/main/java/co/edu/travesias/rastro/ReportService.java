package co.edu.travesias.rastro;

import com.fasterxml.jackson.databind.JsonNode;
import java.sql.*;
import java.util.*;
import static co.edu.travesias.rastro.Repository.*;
import static co.edu.travesias.rastro.Validation.*;

public final class ReportService {
    private static final String SELECT = "SELECT r.id,r.especie_id,e.nombre especie,r.especie_otro,r.nombre_animal,r.identificador_campo,r.senas,r.descripcion,r.sector_id,s.nombre sector,r.fecha_perdida,r.creado_en,r.estado,r.version,(r.foto IS NOT NULL) tiene_foto FROM reporte r JOIN especie e ON e.id=r.especie_id JOIN sector s ON s.id=r.sector_id ";
    public Map<String,Object> list(String user, boolean mine, String q, int species, int sector, int page) throws SQLException {
        String where=mine ? " WHERE r.usuario_id=?" : " WHERE r.estado='BUSCANDO'";
        List<Object> args=new ArrayList<>();
        if(mine) args.add(user);
        if(species>0) {where+=" AND r.especie_id=?";args.add(species);}
        if(sector>0) {where+=" AND r.sector_id=?";args.add(sector);}
        if(q!=null && !q.isBlank()) {
            if(q.length()>100) throw invalid("búsqueda");
            where+=" AND (LOCATE(?,COALESCE(r.nombre_animal,''))>0 OR LOCATE(?,r.senas)>0 OR LOCATE(?,COALESCE(r.identificador_campo,''))>0 OR LOCATE(?,r.descripcion)>0)";
            for(int i=0;i<4;i++) args.add(q.strip());
        }
        try(Connection c=Database.connection()) {
            Object total=query(c,"SELECT COUNT(*) total FROM reporte r"+where,args.toArray()).get(0).get("total");
            args.add(12);args.add((page-1)*12);
            var items=query(c,SELECT+where+" ORDER BY r.creado_en DESC,r.id DESC LIMIT ? OFFSET ?",args.toArray());
            return Map.of("items",items,"total",total,"page",page,"page_size",12);
        }
    }
    public Map<String,Object> detail(long id,String user) throws SQLException {
        try(Connection c=Database.connection()) {
            var rows=query(c,SELECT+" WHERE r.id=?",id);
            if(rows.isEmpty()) throw new ApiException(404,"El reporte no existe.");
            var row=rows.get(0);
            Object owner=query(c,"SELECT usuario_id FROM reporte WHERE id=?",id).get(0).get("usuario_id");
            row.put("es_autor",owner.equals(user));
            row.put("avistamientos",query(c,"SELECT a.id,a.fecha_avistamiento,a.observacion,s.nombre sector FROM avistamiento a JOIN sector s ON s.id=a.sector_id WHERE a.reporte_id=? ORDER BY a.fecha_avistamiento DESC,a.id DESC",id));
            return row;
        }
    }
    private Object[] fields(Connection c,JsonNode body) throws SQLException {
        int species=integer(body,"especie_id",1,Integer.MAX_VALUE),sector=integer(body,"sector_id",1,Integer.MAX_VALUE);
        var catalog=query(c,"SELECT nombre FROM especie WHERE id=?",species);
        if(catalog.isEmpty()) throw invalid("especie_id");
        checkSector(c,sector);
        String other=text(body,"especie_otro",80,"Otro".equals(catalog.get(0).get("nombre")));
        if(!"Otro".equals(catalog.get(0).get("nombre"))) other=null;
        return new Object[]{species,other,text(body,"nombre_animal",100,false),text(body,"identificador_campo",100,false),text(body,"senas",1000,true),text(body,"descripcion",2000,true),sector,java.sql.Date.valueOf(date(body,"fecha_perdida"))};
    }
    private void checkSector(Connection c,int sector) throws SQLException {
        if(query(c,"SELECT id FROM sector WHERE id=?",sector).isEmpty()) throw invalid("sector_id");
    }
    public long create(String user,JsonNode body) throws SQLException {
        Photo photo=photo(body);
        try(Connection c=Database.connection()) {
            c.setAutoCommit(false);
            try {
                Object[] f=fields(c,body);ensureUser(c,user);
                List<Object> args=new ArrayList<>(Arrays.asList(f)); args.add(user);args.add(photo.bytes());args.add(photo.type());
                long id=insert(c,"INSERT INTO reporte(especie_id,especie_otro,nombre_animal,identificador_campo,senas,descripcion,sector_id,fecha_perdida,usuario_id,foto,foto_tipo) VALUES (?,?,?,?,?,?,?,?,?,?,?)",args.toArray());
                c.commit();return id;
            } catch(Exception e) {c.rollback();throw e;}
        }
    }
    private Map<String,Object> lock(Connection c,long id) throws SQLException {
        var rows=query(c,"SELECT usuario_id,estado,version,fecha_perdida FROM reporte WHERE id=? FOR UPDATE",id);
        if(rows.isEmpty()) throw new ApiException(404,"El reporte no existe.");
        return rows.get(0);
    }
    public void change(long id,String user,JsonNode body,boolean statusOnly) throws SQLException {
        try(Connection c=Database.connection()) {
            c.setAutoCommit(false);
            try {
                var row=lock(c,id);
                if(!row.get("usuario_id").equals(user)) throw new ApiException(403,"Solo el autor puede modificar este reporte.");
                if(!"BUSCANDO".equals(row.get("estado"))) throw new ApiException(409,"El reporte ya está cerrado.");
                int version=integer(body,"version",0,Integer.MAX_VALUE);
                if(((Number)row.get("version")).intValue()!=version) throw new ApiException(409,"El reporte cambió. Actualiza el detalle antes de continuar.");
                if(statusOnly) {
                    String state=text(body,"estado",16,true);
                    if(!Set.of("ENCONTRADO","CANCELADO").contains(state)) throw invalid("estado");
                    update(c,"UPDATE reporte SET estado=?,version=version+1 WHERE id=?",state,id);
                } else {
                    var f=fields(c,body);
                    var earlier=query(c,"SELECT MIN(fecha_avistamiento) primera FROM avistamiento WHERE reporte_id=?",id).get(0).get("primera");
                    if(earlier!=null && java.time.LocalDate.parse(earlier.toString().substring(0,10)).isBefore(((java.sql.Date)f[7]).toLocalDate())) throw invalid("fecha_perdida (posterior a un avistamiento)");
                    List<Object> args=new ArrayList<>(Arrays.asList(f));
                    String photoSql="";
                    if(body.has("foto")) {Photo photo=photo(body);photoSql=",foto=?,foto_tipo=?";args.add(photo.bytes());args.add(photo.type());}
                    args.add(id);
                    update(c,"UPDATE reporte SET especie_id=?,especie_otro=?,nombre_animal=?,identificador_campo=?,senas=?,descripcion=?,sector_id=?,fecha_perdida=?,version=version+1"+photoSql+" WHERE id=?",args.toArray());
                }
                c.commit();
            } catch(Exception e) {c.rollback();throw e;}
        }
    }
    public long sighting(long id,String user,JsonNode body) throws SQLException {
        int sector=integer(body,"sector_id",1,Integer.MAX_VALUE);
        var date=dateTime(body,"fecha_avistamiento");
        String note=text(body,"observacion",2000,true);
        try(Connection c=Database.connection()) {
            c.setAutoCommit(false);
            try {
                var row=lock(c,id);
                if(!"BUSCANDO".equals(row.get("estado"))) throw new ApiException(409,"Este reporte ya está cerrado.");
                if(date.toLocalDate().isBefore(java.time.LocalDate.parse(row.get("fecha_perdida").toString()))) throw invalid("fecha_avistamiento (anterior a la pérdida)");
                checkSector(c,sector);ensureUser(c,user);
                long result=insert(c,"INSERT INTO avistamiento(reporte_id,usuario_id,sector_id,fecha_avistamiento,observacion) VALUES (?,?,?,?,?)",id,user,sector,Timestamp.valueOf(date),note);
                c.commit();return result;
            } catch(Exception e) {c.rollback();throw e;}
        }
    }
    public long survey(String user,JsonNode body) throws SQLException {
        if(!"rastro-rural".equals(text(body,"subproyecto_id",40,true))) throw new ApiException(403,"Subproyecto no autorizado.");
        integer(body,"version_encuesta",1,1);
        JsonNode answers=body.path("respuestas");
        if(!answers.isObject() || answers.size()!=5) throw invalid("respuestas");
        Object[] args=new Object[6];args[0]=user;
        for(int i=1;i<=5;i++) args[i]=integer(answers,"respuesta_"+i,1,5);
        try(Connection c=Database.connection()) {
            c.setAutoCommit(false);
            try {
                ensureUser(c,user);
                long id=insert(c,"INSERT INTO encuesta(usuario_id,respuesta_1,respuesta_2,respuesta_3,respuesta_4,respuesta_5) VALUES (?,?,?,?,?,?)",args);
                c.commit();return id;
            } catch(SQLException e) {
                c.rollback();
                if(e.getErrorCode()==1062 || "23505".equals(e.getSQLState())) throw new ApiException(409,"Ya respondiste esta versión de la encuesta.");
                throw e;
            } catch(RuntimeException e) {c.rollback();throw e;}
        }
    }
}
