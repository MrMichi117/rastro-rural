FROM ubuntu:24.04 AS frontend
ARG FLUTTER_VERSION=3.47.5
RUN apt-get update && apt-get install -y --no-install-recommends curl git unzip xz-utils ca-certificates libglu1-mesa && rm -rf /var/lib/apt/lists/*
RUN git clone --depth 1 --branch ${FLUTTER_VERSION} https://github.com/flutter/flutter.git /opt/flutter
ENV PATH="/opt/flutter/bin:${PATH}"
RUN flutter config --no-analytics && flutter precache --web
WORKDIR /frontend
COPY frontend/pubspec.* ./
RUN flutter pub get
COPY frontend ./
RUN flutter analyze && flutter test && flutter build web --release --base-href /rastro-rural/ --no-web-resources-cdn

FROM maven:3.9.11-eclipse-temurin-17 AS build
WORKDIR /build
COPY pom.xml .
COPY backend/pom.xml backend/pom.xml
RUN mvn -B dependency:go-offline
COPY backend/src ./backend/src
COPY --from=frontend /frontend/build/web ./frontend/build/web
COPY database ./database
RUN mvn -B clean verify

FROM tomcat:10.1-jdk17-temurin
RUN groupadd --system rastro && useradd --system --gid rastro rastro
COPY --from=build /build/backend/target/rastro-rural.war /usr/local/tomcat/webapps/rastro-rural.war
RUN chown -R rastro:rastro /usr/local/tomcat
USER rastro
EXPOSE 8080
CMD ["catalina.sh", "run"]
