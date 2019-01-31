FROM centos/s2i-core-centos7
LABEL maintainer="Levi Baber <baber@iastate.edu>"

ENV \
    STI_SCRIPTS_URL=image:///usr/libexec/s2i \
    # Path to be used in other layers to place s2i scripts into
    STI_SCRIPTS_PATH=/usr/libexec/s2i \
    APP_ROOT=/opt/app-root \
    # The $HOME is not set by default, but some applications needs this variable
    HOME=/opt/app-root/ \
    PATH=/opt/app-root/:$PATH

#package installation
RUN yum -y install epel-release && \
        yum -y install R libxml2-devel libcurl-devel openssl-devel v8-devel nss_wrapper && \
        Rscript -e "install.packages('shiny', repos='https://cran.rstudio.com/')" && \
        yum -y install wget && \
        wget https://download3.rstudio.org/centos6.3/x86_64/shiny-server-1.5.9.923-x86_64.rpm && \
	yum -y install --nogpgcheck shiny-server-1.5.9.923-x86_64.rpm && \
	yum -y install git && \
	sed -i -e 's|/srv/shiny-server|/opt/app-root|g' /etc/shiny-server/shiny-server.conf && \
	sed -i -e 's/run_as shiny;/run_as 1001;/g' /etc/shiny-server/shiny-server.conf; 

#shiny-server config file changes
RUN sed -i -e 's/run_as 1001;/run_as openshift;/g' /etc/shiny-server/shiny-server.conf;
RUN sed -i -e 's|/opt/app-root|/opt/app-root/src|g' /etc/shiny-server/shiny-server.conf

#perms
RUN chmod -R o+w /var/log/shiny-server
RUN chmod g+w /var/lib/shiny-server

# Copy the S2I scripts from the specific language image to $STI_SCRIPTS_PATH
COPY ./s2i/bin/ $STI_SCRIPTS_PATH

# Copy the passwd template for nss_wrapper
COPY passwd.template /tmp/passwd.template

USER 1001

EXPOSE 3838

STOPSIGNAL SIGTERM

CMD ["/usr/libexec/s2i/run"]