FROM maven:3.9.11-eclipse-temurin-17 AS build
WORKDIR /build
COPY pom.xml .
RUN mvn -B dependency:go-offline
COPY src ./src
COPY database ./database
RUN mvn -B clean verify

FROM tomcat:10.1-jdk17-temurin
RUN groupadd --system rastro && useradd --system --gid rastro rastro
COPY --from=build /build/target/rastro-rural.war /usr/local/tomcat/webapps/rastro-rural.war
RUN chown -R rastro:rastro /usr/local/tomcat
USER rastro
EXPOSE 8080
CMD ["catalina.sh", "run"]
