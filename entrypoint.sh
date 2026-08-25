#!/bin/sh
# Renders /opt/traccar/conf/traccar.xml from environment variables, then starts
# Traccar. Traccar 6.x reads config ONLY from the XML file (no env-var override),
# so we generate the file at container start. This keeps the DB password out of
# the image — inject it via ECS Secrets Manager as DB_PASSWORD.
#
# Required env: DB_HOST, DB_DATABASE, DB_USERNAME, DB_PASSWORD
# Optional env: DB_PORT (default 3306)
set -e

: "${DB_HOST:?DB_HOST is required}"
: "${DB_DATABASE:?DB_DATABASE is required}"
: "${DB_USERNAME:?DB_USERNAME is required}"
: "${DB_PASSWORD:?DB_PASSWORD is required}"
DB_PORT="${DB_PORT:-3306}"

JDBC_URL="jdbc:mysql://${DB_HOST}:${DB_PORT}/${DB_DATABASE}?serverTimezone=UTC&useSSL=true&allowPublicKeyRetrieval=true"

# XML-escape &, <, > so values (the JDBC URL's & separators, etc.) are valid XML.
esc() { printf '%s' "$1" | sed -e 's/&/\&amp;/g' -e 's/</\&lt;/g' -e 's/>/\&gt;/g'; }

XML_URL=$(esc "$JDBC_URL")
XML_USER=$(esc "$DB_USERNAME")
XML_PASS=$(esc "$DB_PASSWORD")

cat > /opt/traccar/conf/traccar.xml <<EOF
<?xml version='1.0' encoding='UTF-8'?>
<!DOCTYPE properties SYSTEM 'http://java.sun.com/dtd/properties.dtd'>
<properties>
    <entry key='config.default'>./conf/default.xml</entry>
    <entry key='database.driver'>com.mysql.cj.jdbc.Driver</entry>
    <entry key='database.url'>${XML_URL}</entry>
    <entry key='database.user'>${XML_USER}</entry>
    <entry key='database.password'>${XML_PASS}</entry>
    <entry key='web.port'>8082</entry>
</properties>
EOF

echo "Generated traccar.xml -> ${DB_HOST}:${DB_PORT}/${DB_DATABASE} as ${DB_USERNAME}"
exec java -Xms1g -Xmx1g -Djava.net.preferIPv4Stack=true -jar tracker-server.jar conf/traccar.xml
