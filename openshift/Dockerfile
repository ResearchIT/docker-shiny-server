FROM researchit/shiny-server
LABEL maintainer="Levi Baber <baber@iastate.edu>"

#application directory
#openshift apps are deployed in /opt/app-root
RUN yum -y install git && \
sed -i -e 's|/srv/shiny-server|/opt/app-root|g' /etc/shiny-server/shiny-server.conf && \
chown -R 1001:0 /opt/app-root ;

USER 1001
