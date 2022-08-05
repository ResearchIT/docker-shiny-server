FROM registry.fedoraproject.org/f35/s2i-core:latest
LABEL maintainer="ISU LAS IRIS <las-iris@iastate.edu>"

ENV \
    SHINYSRVPKG=shiny-server-1.5.19.995-x86_64.rpm \
    STI_SCRIPTS_URL=image:///usr/libexec/s2i \
    STI_SCRIPTS_PATH=/usr/libexec/s2i \
    APP_ROOT=/opt/app-root \
    HOME=/opt/app-root/ \
    PATH=/opt/app-root/:/opt/spack/bin:$PATH

# package installation
RUN \
    dnf -y update && \
    dnf -y install \
      R libxml2-devel libcurl-devel openssl-devel v8-devel fribidi-devel \
      nss_wrapper mariadb-devel udunits2-devel geos-devel gdal-devel \
      proj-devel cairo-devel jq-devel protobuf-devel protobuf-compiler \
      sqlite-devel wget geos gdal git file libXt-devel harfbuzz-devel \
      freetype-devel libpng-devel libtiff-devel libjpeg-turbo-devel && \
    dnf clean all;

# configure R
RUN \
    echo -e '\noptions(repos = c(CRAN="https://mirror.las.iastate.edu/CRAN"))' >> /usr/lib64/R/library/base/R/Rprofile && \
    mkdir -p /opt/app-root/src/R_libs /opt/app-root/.R && \
    chmod -R g+w /opt/app-root/src && \
    echo "R_LIBS=/opt/app-root/src/R_libs" > /opt/app-root/.Renviron && \
    echo "MAKEFLAGS = -j3" > /opt/app-root/.R/Makevars;

# install and configure shiny server
RUN \
    Rscript -e "install.packages(c('shiny','devtools','stringr','BiocManager'))" && \
    Rscript -e "install.packages(c('shinythemes','dplyr','ggplot2','leaflet'))" && \
    Rscript -e "install.packages(c('lubridate','raster','spData','geojsonio'))" && \
    Rscript -e "install.packages(c('sf','plotly','tidyr','wesanderson'))" && \
    wget https://download3.rstudio.org/centos7/x86_64/$SHINYSRVPKG && \
    dnf -y --nogpgcheck install $SHINYSRVPKG && \
    dnf clean all && \
    rm -f $SHINYSRVPKG && \
    chmod -R o+w /var/log/shiny-server && \
    chmod g+w /var/lib/shiny-server && \
    sed -i -e 's|/srv/shiny-server|/opt/app-root/src|g' /etc/shiny-server/shiny-server.conf && \
    sed -i -e 's/run_as shiny;/run_as openshift;/g' /etc/shiny-server/shiny-server.conf && \
    echo "app_init_timeout 300;" >> /etc/shiny-server/shiny-server.conf && \
    echo "app_idle_timeout 300;" >> /etc/shiny-server/shiny-server.conf;

# Copy in installdeps.R to set cran mirror & handle package installs
COPY ./installdeps.R /opt/app-root/src

# Copy the S2I scripts from the specific language image to $STI_SCRIPTS_PATH
COPY ./s2i/bin/ $STI_SCRIPTS_PATH

# Copy the passwd template for nss_wrapper
COPY passwd.template /tmp/passwd.template

USER 1001

EXPOSE 3838

STOPSIGNAL SIGTERM

CMD ["/usr/libexec/s2i/run"]
