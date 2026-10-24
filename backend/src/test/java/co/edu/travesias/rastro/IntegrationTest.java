package co.edu.travesias.rastro;

import com.fasterxml.jackson.databind.JsonNode;
import org.apache.catalina.startup.Tomcat;
import org.junit.jupiter.api.*;
import java.net.URI;
import java.net.http.*;
import java.nio.file.*;
import java.sql.*;
import java.time.*;
import java.util.*;
import static org.junit.jupiter.api.Assertions.*;

/** HTTP real sobre Tomcat; MySQL si TEST_DB_URL estÃ¡ definido, H2 solo como respaldo de pruebas. */
class IntegrationTest {
    static Tomcat tomcat;
    static String base;
    static HttpClient client = HttpClient.newHttpClient();
    static JsonNode json(HttpResponse<String> response) throws Exception {return Json.MAPPER.readTree(response.body());}
    static HttpResponse<String> call(String method,String path,Object data,String token) throws Exception {
        var request=HttpRequest.newBuilder(URI.create(base+path));
        if(token!=null)request.header("Authorization","Bearer "+token);
        if(data!=null)request.header("Content-Type","application/json");
        request.method(method,data==null?HttpRequest.BodyPublishers.noBody():HttpRequest.BodyPublishers.ofString(Json.MAPPER.writeValueAsString(data)));
        return client.send(request.build(),HttpResponse.BodyHandlers.ofString());
    }
    @BeforeAll static void start() throws Exception {
        System.setProperty("APP_ENV","development");
        System.setProperty("DB_URL",System.getenv().getOrDefault("TEST_DB_URL","jdbc:h2:mem:rastro;MODE=MySQL;DATABASE_TO_LOWER=TRUE;DB_CLOSE_DELAY=-1"));
        System.setProperty("DB_USER",System.getenv().getOrDefault("TEST_DB_USER","sa"));
        System.setProperty("DB_PASSWORD",System.getenv().getOrDefault("TEST_DB_PASSWORD","test-only"));
        String sql=Files.readString(Path.of("../database/001_schema.sql")).replaceAll("(?m)^--.*$", "");
        if(Config.required("DB_URL").startsWith("jdbc:h2:"))sql=sql.replace(" COLLATE utf8mb4_bin","").replace(" ENGINE=InnoDB DEFAULT CHARSET=utf8mb4","");
        try(Connection c=DriverManager.getConnection(Config.required("DB_URL"),Config.required("DB_USER"),Config.required("DB_PASSWORD"))) {
            for(String statement:sql.split(";")){if(!statement.isBlank())try(var st=c.createStatement()){st.execute(statement);}}
        }
        tomcat=new Tomcat();tomcat.setBaseDir("target/tomcat-tests");tomcat.setPort(0);tomcat.getConnector();
        var context=tomcat.addWebapp("/rastro-rural",Path.of("src/main/webapp").toAbsolutePath().toString());
        context.setAltDDName(Path.of("src/main/webapp/WEB-INF/web.xml").toAbsolutePath().toString());
        context.setParentClassLoader(IntegrationTest.class.getClassLoader());
        tomcat.start();base="http://localhost:"+tomcat.getConnector().getLocalPort()+"/rastro-rural/api";
    }
    @AfterAll static void stop() throws Exception {if(tomcat!=null){tomcat.stop();tomcat.destroy();}}
    static Map<String,Object> report() {
        return new HashMap<>(Map.of("especie_id",1,"sector_id",1,"nombre_animal","Lucero","senas","Mancha blanca en la frente","descripcion","Visto por Ãºltima vez cerca del camino.","fecha_perdida",LocalDate.now(Validation.ZONE).minusDays(1).toString()));
    }
    static long create() throws Exception {var response=call("POST","/reportes",report(),"dev-vecino-1");assertEquals(201,response.statusCode(),response.body());return json(response).path("id").asLong();}
    @Test void trustedProfileDoesNotCreateLocalAccounts() throws Exception {
        var first=call("GET","/me?nombre_visible=Suplantado&usuario_id=vecino-2",null,"dev-vecino-1");
        assertEquals(200,first.statusCode());
        assertEquals("Vecino 1",json(first).path("usuario").path("nombre_visible").asText());
        assertEquals("vecino-1",json(first).path("usuario").path("usuario_id").asText());
        try(Connection c=Database.connection()) {
            for(String table:List.of("login","usuario_referencia")) {
                try(var rs=c.getMetaData().getTables(c.getCatalog(),null,table,new String[]{"TABLE"})) {assertFalse(rs.next());}
            }
        }
    }
    @Test void reportStoresTrustedIdentityAndIssuerControlsOwnership() throws Exception {
        var body=report();body.put("usuario_id","falso");body.put("usuario_nombre","Falso");body.put("usuario_emisor","falso");
        var response=call("POST","/reportes",body,"dev-vecino-1");assertEquals(201,response.statusCode());
        long id=json(response).path("id").asLong();
        try(Connection c=Database.connection()) {
            var row=Repository.query(c,"SELECT usuario_id,usuario_emisor,usuario_nombre FROM reporte WHERE id=?",id).get(0);
            assertEquals("vecino-1",row.get("usuario_id"));assertEquals("urn:rastro:development",row.get("usuario_emisor"));assertEquals("Vecino 1",row.get("usuario_nombre"));
        }
        var other=new Identity.Principal("vecino-1","https://other.test","otro","Otro");
        assertFalse((Boolean)new ReportService().detail(id,other).get("es_autor"));
        assertThrows(ApiException.class,()->new ReportService().change(id,other,Json.MAPPER.valueToTree(Map.of("estado","ENCONTRADO","version",0)),true));
        assertEquals(0,((Number)new ReportService().list(other,true,null,0,0,1).get("total")).intValue());
    }
    @Test void publicBoardAndSecurityHeaders() throws Exception {
        var response=call("GET","/reportes",null,null);assertEquals(200,response.statusCode());
        assertTrue(response.headers().firstValue("Cache-Control").orElse("").contains("no-store"));
        assertTrue(response.headers().firstValue("Content-Security-Policy").isPresent());
        assertEquals(401,call("POST","/reportes",report(),null).statusCode());
        assertEquals(401,call("GET","/reportes?mine=true",null,null).statusCode());
        assertEquals(401,call("GET","/me",null,"false-identity").statusCode());
    }
    @Test void fullLifecycleAndOwnership() throws Exception {
        long id=create();
        assertTrue(json(call("GET","/reportes/"+id,null,"dev-vecino-1")).path("es_autor").asBoolean());
        assertFalse(json(call("GET","/reportes/"+id,null,"dev-vecino-2")).path("es_autor").asBoolean());
        assertFalse(json(call("GET","/reportes/"+id,null,null)).has("usuario_id"));
        assertEquals(403,call("PATCH","/reportes/"+id+"/estado",Map.of("estado","ENCONTRADO","version",0),"dev-vecino-2").statusCode());
        var sighting=Map.of("sector_id",2,"fecha_avistamiento",LocalDateTime.now(Validation.ZONE).minusMinutes(1).toString(),"observacion","Cerca del puente.");
        assertEquals(201,call("POST","/reportes/"+id+"/avistamientos",sighting,"dev-vecino-2").statusCode());
        assertEquals(1,json(call("GET","/reportes/"+id,null,null)).path("avistamientos").size());
        var edit=report();edit.put("version",0);edit.put("nombre_animal","Lucerito");
        assertEquals(200,call("PUT","/reportes/"+id,edit,"dev-vecino-1").statusCode());
        assertEquals(409,call("PUT","/reportes/"+id,edit,"dev-vecino-1").statusCode());
        assertEquals(200,call("PATCH","/reportes/"+id+"/estado",Map.of("estado","ENCONTRADO","version",1),"dev-vecino-1").statusCode());
        assertEquals(409,call("POST","/reportes/"+id+"/avistamientos",sighting,"dev-vecino-2").statusCode());
        assertEquals("ENCONTRADO",json(call("GET","/reportes/"+id,null,null)).path("estado").asText());
    }
    @Test void validationAndIdentityCannotBeSpoofed() throws Exception {
        var body=report();body.put("usuario_id","vecino-2");
        long id=json(call("POST","/reportes",body,"dev-vecino-1")).path("id").asLong();
        assertTrue(json(call("GET","/reportes/"+id,null,"dev-vecino-1")).path("es_autor").asBoolean());
        body.put("especie_id",9);assertEquals(422,call("POST","/reportes",body,"dev-vecino-1").statusCode());
        body.put("especie_otro","Alpaca");assertEquals(201,call("POST","/reportes",body,"dev-vecino-1").statusCode());
        body.put("fecha_perdida",LocalDate.now(Validation.ZONE).plusDays(1).toString());assertEquals(422,call("POST","/reportes",body,"dev-vecino-1").statusCode());
        body=report();body.put("sector_id",999);assertEquals(422,call("POST","/reportes",body,"dev-vecino-1").statusCode());
        body=report();body.put("foto","data:text/html;base64,PHNjcmlwdD4=");assertEquals(422,call("POST","/reportes",body,"dev-vecino-1").statusCode());
        assertEquals(0,json(call("GET","/reportes?q=%27%20OR%201%3D1--",null,null)).path("total").asInt());
        assertEquals(422,call("GET","/reportes?page=-1",null,null).statusCode());
        assertEquals(404,call("GET","/reportes/999999",null,null).statusCode());
    }
    @Test void cancellationRemovesPublicReport() throws Exception {
        long id=create();assertEquals(200,call("PATCH","/reportes/"+id+"/estado",Map.of("estado","CANCELADO","version",0),"dev-vecino-1").statusCode());
        for(var item:json(call("GET","/reportes",null,null)).path("items"))assertNotEquals(id,item.path("id").asLong());
        assertEquals("CANCELADO",json(call("GET","/reportes/"+id,null,null)).path("estado").asText());
    }
    @Test void surveyEnforcesScaleAndUniqueResponse() throws Exception {
        var answers=new HashMap<String,Object>();for(int i=1;i<=5;i++)answers.put("respuesta_"+i,5);
        var body=Map.of("subproyecto_id","rastro-rural","version_encuesta",1,"respuestas",answers);
        answers.put("respuesta_1",0);assertEquals(422,call("POST","/v1/encuestas/usabilidad",body,"dev-vecino-2").statusCode());
        answers.put("respuesta_1",4);assertEquals(201,call("POST","/v1/encuestas/usabilidad",body,"dev-vecino-2").statusCode());
        assertEquals(409,call("POST","/v1/encuestas/usabilidad",body,"dev-vecino-2").statusCode());
    }
    @Test void validPhotoIsServedAndCanBeRemoved() throws Exception {
        var picture=new java.awt.image.BufferedImage(2,2,java.awt.image.BufferedImage.TYPE_INT_RGB);
        var bytes=new java.io.ByteArrayOutputStream();javax.imageio.ImageIO.write(picture,"png",bytes);
        var body=report();body.put("foto","data:image/png;base64,"+Base64.getEncoder().encodeToString(bytes.toByteArray()));
        var saved=call("POST","/reportes",body,"dev-vecino-1");assertEquals(201,saved.statusCode(),saved.body());
        long id=json(saved).path("id").asLong();var photo=call("GET","/reportes/"+id+"/foto",null,null);
        assertEquals(200,photo.statusCode());assertEquals("image/png",photo.headers().firstValue("Content-Type").orElse(""));
        body.put("foto",null);body.put("version",0);assertEquals(200,call("PUT","/reportes/"+id,body,"dev-vecino-1").statusCode());
        assertEquals(404,call("GET","/reportes/"+id+"/foto",null,null).statusCode());
    }
}
