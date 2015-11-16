FROM debian:wheezy

MAINTAINER Alexey Nurgaliev <atnurgaliev@gmail.com>

ENV DEBIAN_FRONTEND=noninteractive

RUN apt-get update && \
    apt-get upgrade -y && \
    apt-get install -y apt-transport-https wget

ADD open-xchange.list /etc/apt/sources.list.d/open-xchange.list

RUN wget http://software.open-xchange.com/oxbuildkey.pub -O - | apt-key add - && \
    apt-get update && \
    apt-get install --force-yes -y \
        vim \
        mysql-server \
        calcengine \
        open-xchange \
        open-xchange-authentication-database \
        open-xchange-grizzly \
        open-xchange-admin \
        open-xchange-appsuite \
        open-xchange-appsuite-backend \
        open-xchange-appsuite-manifest \
        open-xchange-l10n-* \
        open-xchange-lang-community-* \
        open-xchange-appsuite-l10n-* \
        open-xchange-documents-backend \
        open-xchange-documentconverter-api \
        open-xchange-documents-ui \
        open-xchange-documents-ui-static

ADD proxy_http.conf /etc/apache2/conf.d/proxy_http.conf
ADD open-xchange /etc/apache2/sites-available/open-xchange

RUN a2enmod proxy proxy_http proxy_balancer expires \
        deflate headers rewrite mime setenvif && \
    a2dissite default && \
    a2ensite open-xchange && \
    mkdir -p -m 0777 /ox /ox/store && \
    chown open-xchange:open-xchange /ox/store

ADD run.sh /ox/run.sh

VOLUME ["/ox/store", "/var/lib/mysql"]

EXPOSE 80

CMD /ox/run.sh; bash
