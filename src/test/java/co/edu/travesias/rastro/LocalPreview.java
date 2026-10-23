package co.edu.travesias.rastro;

import org.apache.catalina.startup.Tomcat;
import java.nio.file.Path;

/** Lanzador de desarrollo; no se incluye en el WAR. Requiere una base MySQL inicializada. */
public final class LocalPreview {
    public static void main(String[] args) throws Exception {
        Tomcat server=new Tomcat();server.setBaseDir("target/local-tomcat");server.setPort(Integer.parseInt(Config.get("PORT","8080")));server.getConnector();
        var context=server.addWebapp("/rastro-rural",Path.of("src/main/webapp").toAbsolutePath().toString());
        context.setParentClassLoader(LocalPreview.class.getClassLoader());
        server.start();server.getServer().await();
    }
}
