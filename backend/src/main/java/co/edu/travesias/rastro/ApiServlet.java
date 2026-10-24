package co.edu.travesias.rastro;

import jakarta.servlet.http.*;
import java.io.IOException;
import java.sql.*;
import java.util.Map;
import static co.edu.travesias.rastro.Repository.query;

public final class ApiServlet extends HttpServlet {
    private final ReportService service = new ReportService();
    @Override protected void service(HttpServletRequest req,HttpServletResponse res) throws IOException {
        try { route(req,res); }
        catch(ApiException e) {Json.error(res,e.status,e.getMessage());}
        catch(SQLException e) {
            getServletContext().log("Fallo de persistencia",e);
            Json.error(res,503,"No fue posible confirmar la operación en la base de datos. Consulta el reporte antes de reenviar.");
        }
        catch(Exception e) {getServletContext().log("Error de API",e);Json.error(res,500,"No fue posible completar la solicitud.");}
    }
    private int number(String raw,int fallback) {
        if(raw==null || raw.isBlank()) return fallback;
        try {int value=Integer.parseInt(raw);if(value<1 || value>1_000_000) throw new NumberFormatException();return value;}
        catch(NumberFormatException e) {throw new ApiException(422,"Filtro o página no válido.");}
    }
    private void route(HttpServletRequest req,HttpServletResponse res) throws Exception {
        String path=req.getPathInfo()==null?"/":req.getPathInfo(),method=req.getMethod();
        Identity.Principal user=(Identity.Principal)req.getAttribute("identity");
        if(method.equals("GET")) {
            if(path.equals("/config")) {Json.send(res,200,Map.of("development","development".equals(Config.get("APP_ENV","production")),"platform_origin",Config.get("PLATFORM_ORIGIN",""),"central_login_url",Config.get("CENTRAL_LOGIN_URL",""),"central_dashboard_url",Config.get("CENTRAL_DASHBOARD_URL","")));return;}
            if(path.equals("/me")) {Json.send(res,200,Map.of("authenticated",true,"usuario",user.profile()));return;}
            if(path.equals("/health")) {try(Connection c=Database.connection()){query(c,"SELECT 1");}Json.send(res,200,Map.of("status","ok"));return;}
            if(path.equals("/catalogos")) {
                try(Connection c=Database.connection()) {Json.send(res,200,Map.of("especies",query(c,"SELECT id,nombre FROM especie ORDER BY id"),"sectores",query(c,"SELECT id,nombre FROM sector ORDER BY nombre")));}return;
            }
            if(path.equals("/estadisticas")) {
                try(Connection c=Database.connection()) {
                    Json.send(res,200,Map.of("buscando",query(c,"SELECT COUNT(*) total FROM reporte WHERE estado='BUSCANDO'").get(0).get("total"),"encontrados",query(c,"SELECT COUNT(*) total FROM reporte WHERE estado='ENCONTRADO'").get(0).get("total"),"avistamientos",query(c,"SELECT COUNT(*) total FROM avistamiento").get(0).get("total")));
                }return;
            }
            if(path.equals("/reportes")) {Json.send(res,200,service.list(user,"true".equals(req.getParameter("mine")),req.getParameter("q"),number(req.getParameter("especie"),0),req.getParameter("sector"),number(req.getParameter("page"),1)));return;}
            if(path.matches("/reportes/\\d+")) {Json.send(res,200,service.detail(Long.parseLong(path.split("/")[2]),user));return;}
            if(path.matches("/reportes/\\d+/foto")) {
                try(Connection c=Database.connection();PreparedStatement st=c.prepareStatement("SELECT foto,foto_tipo FROM reporte WHERE id=?")) {
                    st.setLong(1,Long.parseLong(path.split("/")[2]));
                    try(ResultSet rs=st.executeQuery()) {
                        if(!rs.next() || rs.getBytes(1)==null) throw new ApiException(404,"No hay fotografía.");
                        res.setContentType(rs.getString(2));res.getOutputStream().write(rs.getBytes(1));
                    }
                }return;
            }
        }
        if(method.equals("POST") && path.equals("/reportes")) {Json.send(res,201,Map.of("id",service.create(user,Json.read(req))));return;}
        if(method.equals("POST") && path.matches("/reportes/\\d+/avistamientos")) {Json.send(res,201,Map.of("id",service.sighting(Long.parseLong(path.split("/")[2]),user,Json.read(req))));return;}
        if(method.equals("PUT") && path.matches("/reportes/\\d+")) {service.change(Long.parseLong(path.split("/")[2]),user,Json.read(req),false);Json.send(res,200,Map.of("guardado",true));return;}
        if(method.equals("PATCH") && path.matches("/reportes/\\d+/estado")) {service.change(Long.parseLong(path.split("/")[2]),user,Json.read(req),true);Json.send(res,200,Map.of("guardado",true));return;}
        if(method.equals("POST") && path.equals("/v1/encuestas/usabilidad")) {Json.send(res,201,Map.of("id",service.survey(user,Json.read(req)),"guardado",true,"subproyecto_id","rastro-rural","version_encuesta",1));return;}
        throw new ApiException(404,"Ruta no encontrada.");
    }
}
