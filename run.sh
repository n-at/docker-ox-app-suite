#!/bin/bash

OX_CONFIG_DATABASE_USER=${OX_CONFIG_DATABASE_USER:-"openxchange"}
OX_CONFIG_DATABASE_PASSWORD=${OX_CONFIG_DATABASE_PASSWORD:-"db_password"}

OX_ADMIN_MASTER_LOGIN=${OX_ADMIN_MASTER_LOGIN:-"oxadminmaster"}
OX_ADMIN_MASTER_PASSWORD=${OX_ADMIN_MASTER_PASSWORD:-"admin_master_password"}

OX_SERVER_NAME=${OX_SERVER_NAME:-"oxserver"}
OX_SERVER_MEMORY=${OX_SERVER_MEMORY:-"1024"}

OX_CONTEXT_ADMIN_LOGIN=${OX_CONTEXT_ADMIN_LOGIN:-"oxadmin"}
OX_CONTEXT_ADMIN_PASSWORD=${OX_CONTEXT_ADMIN_PASSWORD:-"oxadmin"}
OX_CONTEXT_ADMIN_EMAIL=${OX_CONTEXT_ADMIN_EMAIL:-"admin@example.com"}
OX_CONTEXT_ID=${OX_CONTEXT_ID:-"1"}

echo "CONFIG_DATABASE_PASSWORD=${OX_CONFIG_DATABASE_PASSWORD}"
echo "ADMIN_MASTER_LOGIN=${OX_ADMIN_MASTER_LOGIN}"
echo "ADMIN_MASTER_PASSWORD=${OX_ADMIN_MASTER_PASSWORD}"
echo "SERVER_NAME=${OX_SERVER_NAME}"
echo "SERVER_MEMORY=${OX_SERVER_MEMORY}"
echo "CONTEXT_ADMIN_LOGIN=${OX_CONTEXT_ADMIN_LOGIN}"
echo "CONTEXT_ADMIN_PASSWORD=${OX_CONTEXT_ADMIN_PASSWORD}"
echo "CONTEXT_ADMIN_EMAIL=${OX_CONTEXT_ADMIN_EMAIL}"
echo "CONTEXT_ID=${OX_CONTEXT_ID}"

#Start MySQL
service mysql start

#Create config database
/opt/open-xchange/sbin/initconfigdb \
    --configdb-user=${OX_CONFIG_DATABASE_USER} \
    --configdb-pass=${OX_CONFIG_DATABASE_PASSWORD} \
    --configdb-dbname=configdb \
    --configdb-host=localhost \
    --configdb-port=3306 \
    -a -i

#Create server instance config
/opt/open-xchange/sbin/oxinstaller \
    --no-license \
    --servername=${OX_SERVER_NAME} \
    --configdb-user=${OX_CONFIG_DATABASE_USER} \
    --configdb-pass=${OX_CONFIG_DATABASE_PASSWORD} \
    --configdb-readhost=localhost \
    --configdb-readport=3306 \
    --configdb-writehost=localhost \
    --configdb-writeport=3306 \
    --configdb-dbname=configdb \
    --master-pass=${OX_ADMIN_MASTER_PASSWORD} \
    --network-listener-host=localhost \
    --servermemory ${OX_SERVER_MEMORY}

#Enable OX Text and OX Spreadsheets
sed -i 's/# com.openexchange.capability.text/com.openexchange.capability.text/1' \
    /opt/open-xchange/etc/documents.properties
sed -i 's/# com.openexchange.capability.spreadsheet/com.openexchange.capability.spreadsheet/1' \
    /opt/open-xchange/etc/documents.properties

#Start OX
service open-xchange start

#Server instance registration
while ! /opt/open-xchange/sbin/registerserver \
            --name=${OX_SERVER_NAME} \
            --adminuser=${OX_ADMIN_MASTER_LOGIN} \
            --adminpass=${OX_ADMIN_MASTER_PASSWORD}
do
    echo "Waiting OX to start..."
    sleep 5
done;

#Register filestore
/opt/open-xchange/sbin/registerfilestore \
    --adminuser=${OX_ADMIN_MASTER_LOGIN} \
    --adminpass=${OX_ADMIN_MASTER_PASSWORD} \
    --storepath=file:/ox/store \
    --storesize=1000000

#Create groupware database
/opt/open-xchange/sbin/registerdatabase \
    --adminuser=${OX_ADMIN_MASTER_LOGIN} \
    --adminpass=${OX_ADMIN_MASTER_PASSWORD} \
    --name=oxdatabase \
    --hostname=localhost \
    --dbuser=${OX_CONFIG_DATABASE_USER} \
    --dbpasswd=${OX_CONFIG_DATABASE_PASSWORD} \
    --master=true

#Create context
while ! /opt/open-xchange/sbin/createcontext \
    --adminuser=${OX_ADMIN_MASTER_LOGIN} \
    --adminpass=${OX_ADMIN_MASTER_PASSWORD} \
    --contextid=${OX_CONTEXT_ID} \
    --username=${OX_CONTEXT_ADMIN_LOGIN} \
    --password=${OX_CONTEXT_ADMIN_PASSWORD} \
    --email=${OX_CONTEXT_ADMIN_EMAIL} \
    --displayname="Context Admin" \
    --givenname=Admin \
    --surname=Admin \
    --addmapping=defaultcontext \
    --quota=1024 \
    --access-combination-name=groupware_standard
do
    echo "Waiting for mysql..."
    sleep 5
done

#Start Apache2
service apache2 start
