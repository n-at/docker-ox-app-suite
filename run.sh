#!/bin/bash

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
    --configdb-pass=${OX_CONFIG_DATABASE_PASSWORD} \
    -a

#Create server instance config
/opt/open-xchange/sbin/oxinstaller \
    --no-license \
    --servername=${OX_SERVER_NAME} \
    --configdb-pass=${OX_CONFIG_DATABASE_PASSWORD} \
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
sleep 10

#Server instance registration
/opt/open-xchange/sbin/registerserver \
    -n ${OX_SERVER_NAME} \
    -A ${OX_ADMIN_MASTER_LOGIN} \
    -P ${OX_ADMIN_MASTER_PASSWORD}

#Register filestore
/opt/open-xchange/sbin/registerfilestore \
    -A ${OX_ADMIN_MASTER_LOGIN} \
    -P ${OX_ADMIN_MASTER_PASSWORD} \
    -t file:/ox/store \
    -s 1000000

#Create groupware database
/opt/open-xchange/sbin/registerdatabase \
    -A ${OX_ADMIN_MASTER_LOGIN} \
    -P ${OX_ADMIN_MASTER_PASSWORD} \
    -n oxdatabase \
    -p ${OX_CONFIG_DATABASE_PASSWORD} \
    -m true

#Create context
/opt/open-xchange/sbin/createcontext \
    -A ${OX_ADMIN_MASTER_LOGIN} \
    -P ${OX_ADMIN_MASTER_PASSWORD} \
    -c ${OX_CONTEXT_ID} \
    -u ${OX_CONTEXT_ADMIN_LOGIN} \
    -p ${OX_CONTEXT_ADMIN_PASSWORD} \
    -e ${OX_CONTEXT_ADMIN_EMAIL} \
    -d "Context Admin" \
    -g Admin \
    -s Admin \
    -L defaultcontext \
    -q 1024 \
    --access-combination-name=groupware_standard

#Start Apache2
service apache2 start
