# syntax=docker/dockerfile:1.7

# ---- build: WAR with JDK 21 (Magnolia 6.4 certified on 17/21/25) ----
FROM maven:3.9-eclipse-temurin-21 AS build
WORKDIR /build
COPY pom.xml ./
COPY webapp ./webapp
RUN --mount=type=cache,target=/root/.m2 \
    mvn -B -ntp -DskipTests -pl webapp -am package

# ---- runtime: Tomcat 10.1 (the only certified app server, Jakarta EE 10) ----
FROM tomcat:10.1-jre21-temurin AS runtime
RUN rm -rf /usr/local/tomcat/webapps/* \
 && groupadd -r magnolia && useradd -r -g magnolia -d /data magnolia \
 && mkdir -p /data/magnolia /opt/light-modules \
 && chown -R magnolia:magnolia /data /opt/light-modules /usr/local/tomcat
COPY --from=build --chown=magnolia:magnolia /build/webapp/target/showcase.war /usr/local/tomcat/webapps/ROOT.war
COPY --chown=magnolia:magnolia light-modules /opt/light-modules
COPY --chown=magnolia:magnolia --chmod=755 docker/setenv.sh /usr/local/tomcat/bin/setenv.sh

# One image, two roles: MAGNOLIA_INSTANCE_TYPE=author|public selects the role at runtime.
# MAGNOLIA_PROFILE=showcase loads WEB-INF/config/showcase (PostgreSQL repository).
# Required at runtime: MGNL_DB_URL, MGNL_DB_USER, MGNL_DB_PASSWORD (see docker-compose.yml).
ENV MAGNOLIA_PROFILE=showcase \
    MAGNOLIA_INSTANCE_TYPE=author \
    CATALINA_OPTS="-Xms512m -Xmx1536m \
      -Dmagnolia.home=/data/magnolia \
      -Dmagnolia.resources.dir=/opt/light-modules \
      -Dmagnolia.update.auto=true"
USER magnolia
VOLUME /data/magnolia
EXPOSE 8080
