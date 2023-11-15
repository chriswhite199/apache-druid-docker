#!/usr/bin/env bash

set -e

DRUID_HOME=/opt/druid
DRUID_PROFILE=nano
DRUID_CONF=${DRUID_CONF:-$DRUID_HOME/conf/druid/single-server/$DRUID_PROFILE-quickstart/_common/common.runtime.properties}


declare -a EXTENSIONS=( "druid-hdfs-storage" "druid-kafka-indexing-service" "druid-datasketches" "druid-multi-stage-query" )

echo >> $DRUID_CONF

if test "${ENABLE_AUTH:-false}" != "false"; then
    if [ -z "${ADMIN_PASSWORD}" ]; then
        export ADMIN_PASSWORD="$(dd if=/dev/urandom count=32 bs=1 | sha1sum  | cut -f1 -d' ')
        echo "Admin password: $ADMIN_PASSWORD
    fi

    if [ -z "$USER_NAME" ]; then
        export USER_NAME=druid_system
    fi

    if [ -z "${USER_PASSWORD}" ]; then
        export USER_PASSWORD="$(dd if=/dev/urandom count=32 bs=1 | sha1sum  | cut -f1 -d' ')
        echo "$USER_NAME password: $USER_PASSWORD
    fi

    EXTENSIONS=( "druid-basic-security" "${EXTENSIONS[@]}" )
    cat $DRUID_HOME/templates/auth.properties | envsubst >> "$DRUID_CONF"
    echo >> $DRUID_CONF
fi

if test "${ENABLE_TLS:-false}" != "false"; then
    export TLS_VALIDATE_HOSTNAMES=${TLS_VALIDATE_HOSTNAMES:-false}

    export ENABLE_HTTP="${ENABLE_HTTP:-false}"
    export ENABLE_HTTPS="${ENABLE_HTTPS:-true}"

    if [ -z "${TLS_KEYSTORE_PATH}" ]; then
        echo "Creating self-sign TLS keystore for localhost"

        export TLS_KEYSTORE_PATH=$DRUID_HOME/tls.jks
        export TLS_KEYSTORE_TYPE=jks
        export TLS_KEYSTORE_ALIAS=${TLS_KEYSTORE_ALIAS:-tomcat}
        export TLS_KEYSTORE_PASSWORD="${TLS_KEYSTORE_PASSWORD:-changeit}"

        export TLS_TRUSTSTORE_PATH="${TLS_KEYSTORE_PATH}"
        export TLS_TRUSTSTORE_TYPE=jks
        export TLS_TRUSTSTORE_PASSWORD="${TLS_TRUSTSTORE_PASSWORD:-changeit}"
        
        


        keytool -genkey -keyalg RSA \
            -alias "${TLS_KEYSTORE_ALIAS}" \
            -keystore "${TLS_KEYSTORE_PATH}" \
            -validity 365 \
            -keysize 2048 \
            -keypass "${TLS_KEYSTORE_PASSWORD}" \
            -storepass "${TLS_TRUSTSTORE_PASSWORD}" \
            -dname 'CN=localhost'
    fi

    EXTENSIONS=( "simple-client-sslcontext" "${EXTENSIONS[@]}" )
    cat $DRUID_HOME/templates/tls.properties | envsubst >> "$DRUID_CONF"
    echo >> $DRUID_CONF
fi

echo "druid.extensions.loadList=[$(printf "\"%s\", " "${EXTENSIONS[@]}" | sed 's/, $//')]" >> "$DRUID_CONF"

$DRUID_HOME/bin/start-$DRUID_PROFILE-quickstart "$@"
