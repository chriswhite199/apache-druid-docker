ARG JRE_MAJOR=11
FROM eclipse-temurin:${JRE_MAJOR}-jre

# Install python3 & perl
RUN apt update && apt install -y python3 perl gettext && apt clean

# Install apache druid
ARG DRUID_VERSION=25.0.0
ENV DRUID_HOME=/opt/druid
RUN curl -# https://archive.apache.org/dist/druid/${DRUID_VERSION}/apache-druid-${DRUID_VERSION}-bin.tar.gz | tar -xzf - -C /opt/ \
    && ln -s /opt/apache-druid-${DRUID_VERSION} ${DRUID_HOME}

ADD auth.properties ${DRUID_HOME}/templates/auth.properties
ADD tls.properties ${DRUID_HOME}/templates/tls.properties
ADD entrypoint.sh /

WORKDIR /opt/druid
EXPOSE 8888
EXPOSE 9088

ENTRYPOINT [ "/entrypoint.sh" ]