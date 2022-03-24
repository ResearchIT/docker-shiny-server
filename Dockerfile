FROM registry.fedoraproject.org/f35/s2i-core:latest
LABEL maintainer="ISU LAS IRIS <las-iris@iastate.edu>"

ENV \
    STI_SCRIPTS_URL=image:///usr/libexec/s2i \
    # Path to be used in other layers to place s2i scripts into
    STI_SCRIPTS_PATH=/usr/libexec/s2i \
    APP_ROOT=/opt/app-root \
    # The $HOME is not set by default, but some applications needs this variable
    HOME=/opt/app-root/ \
    PATH=/opt/app-root/:/opt/spack/bin:$PATH

# package installation
RUN \
        dnf -y update && \
        dnf -y install R libxml2-devel libcurl-devel openssl-devel v8-devel \
        nss_wrapper mariadb-devel udunits2-devel geos-devel gdal-devel \
        proj-devel cairo-devel jq-devel protobuf-devel protobuf-compiler \
        wget geos gdal git file;

# configure R
RUN \
        echo -e '\noptions(repos = c(CRAN="https://mirror.las.iastate.edu/CRAN"))' >> /usr/lib64/R/library/base/R/Rprofile && \
        mkdir -p /opt/app-root/src/R_libs && \
        chmod -R g+w /opt/app-root/src && \
        echo "R_LIBS=/opt/app-root/src/R_libs" > /opt/app-root/.Renviron;

# install and configure shiny server
RUN \
        Rscript -e "install.packages(c('shiny','devtools','stringr','BiocManager'))" && \
        wget https://download3.rstudio.org/centos7/x86_64/shiny-server-1.5.17.973-x86_64.rpm && \
	dnf -y --nogpgcheck install shiny-server-1.5.17.973-x86_64.rpm && \
        chmod -R o+w /var/log/shiny-server && chmod g+w /var/lib/shiny-server && \
	sed -i -e 's|/srv/shiny-server|/opt/app-root|g' /etc/shiny-server/shiny-server.conf && \
        sed -i -e 's|/opt/app-root|/opt/app-root/src|g' /etc/shiny-server/shiny-server.conf && \
	sed -i -e 's/run_as shiny;/run_as 1001;/g' /etc/shiny-server/shiny-server.conf && \
        sed -i -e 's/run_as 1001;/run_as openshift;/g' /etc/shiny-server/shiny-server.conf;

# Copy in installdeps.R to set cran mirror & handle package installs
COPY ./installdeps.R /opt/app-root/src

# Copy the S2I scripts from the specific language image to $STI_SCRIPTS_PATH
COPY ./s2i/bin/ $STI_SCRIPTS_PATH

# Copy the passwd template for nss_wrapper
COPY passwd.template /tmp/passwd.template

RUN Rscript -e "install.packages(c('shinythemes','dplyr','ggplot2','leaflet'), repos='https://mirror.las.iastate.edu/CRAN')" && \
    Rscript -e "install.packages(c('lubridate','raster','spData','geojsonio'), repos='https://mirror.las.iastate.edu/CRAN')" && \
    Rscript -e "install.packages(c('sf','plotly','tidyr','wesanderson'), repos='https://mirror.las.iastate.edu/CRAN')";

USER 1001

EXPOSE 3838

STOPSIGNAL SIGTERM

CMD ["/usr/libexec/s2i/run"]
