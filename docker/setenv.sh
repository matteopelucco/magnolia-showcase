#!/bin/sh
# Sourced by catalina.sh. Maps container environment variables to the JVM system properties
# read by WEB-INF/config/repo-conf/jackrabbit-showcase-postgres.xml.
: "${MGNL_DB_URL:?MGNL_DB_URL is required (e.g. jdbc:postgresql://postgres:5432/magnolia_author)}"
: "${MGNL_DB_USER:?MGNL_DB_USER is required}"
: "${MGNL_DB_PASSWORD:?MGNL_DB_PASSWORD is required}"

CATALINA_OPTS="$CATALINA_OPTS -Dmgnl.db.url=$MGNL_DB_URL -Dmgnl.db.user=$MGNL_DB_USER -Dmgnl.db.password=$MGNL_DB_PASSWORD"
export CATALINA_OPTS
