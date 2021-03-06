FROM registry.fedoraproject.org/f33/s2i-core:latest
LABEL maintainer="Levi Baber <baber@iastate.edu>"

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
        dnf -y install R libxml2-devel libcurl-devel openssl-devel v8-devel \
        nss_wrapper mariadb-devel udunits2-devel \
        geos-devel gdal-devel proj-devel cairo-devel && \
        Rscript -e "install.packages('shiny', repos='https://cran.rstudio.com/')" && \
        Rscript -e "install.packages('devtools', repos='https://cran.rstudio.com/')" && \     
        Rscript -e "install.packages('stringr', repos='https://cran.rstudio.com/')" && \
        Rscript -e "install.packages('BiocManager', repos='https://cran.rstudio.com/')" && \
        dnf -y install wget geos gdal && \
        wget https://download3.rstudio.org/centos7/x86_64/shiny-server-1.5.16.958-x86_64.rpm && \
	dnf -y --nogpgcheck install shiny-server-1.5.16.958-x86_64.rpm && \
	dnf -y install git && \
	sed -i -e 's|/srv/shiny-server|/opt/app-root|g' /etc/shiny-server/shiny-server.conf && \
	sed -i -e 's/run_as shiny;/run_as 1001;/g' /etc/shiny-server/shiny-server.conf; 

# shiny-server config file changes
RUN sed -i -e 's/run_as 1001;/run_as openshift;/g' /etc/shiny-server/shiny-server.conf;
RUN sed -i -e 's|/opt/app-root|/opt/app-root/src|g' /etc/shiny-server/shiny-server.conf

# R_LIBS location in .Renviron
RUN mkdir -p /opt/app-root/src/R_libs
RUN chmod -R g+w /opt/app-root/src
RUN echo "R_LIBS=/opt/app-root/src/R_libs" > /opt/app-root/.Renviron

# Copy in installdeps.R to set cran mirror & handle package installs
COPY ./installdeps.R /opt/app-root/src

# perms
RUN chmod -R o+w /var/log/shiny-server && chmod g+w /var/lib/shiny-server

# Copy the S2I scripts from the specific language image to $STI_SCRIPTS_PATH
COPY ./s2i/bin/ $STI_SCRIPTS_PATH

# Copy the passwd template for nss_wrapper
COPY passwd.template /tmp/passwd.template

RUN dnf -y install jq-devel protobuf-devel protobuf-compiler

RUN Rscript -e "install.packages('shinythemes', repos='https://mirror.las.iastate.edu/CRAN')" && \
    Rscript -e "install.packages('dplyr', repos='https://mirror.las.iastate.edu/CRAN')" && \
    Rscript -e "install.packages('ggplot2', repos='https://mirror.las.iastate.edu/CRAN')" && \
    Rscript -e "install.packages('leaflet', repos='https://mirror.las.iastate.edu/CRAN')" && \
    Rscript -e "install.packages('lubridate', repos='https://mirror.las.iastate.edu/CRAN')" && \
    Rscript -e "install.packages('raster', repos='https://mirror.las.iastate.edu/CRAN')" && \
    Rscript -e "install.packages('spData', repos='https://mirror.las.iastate.edu/CRAN')" && \
    Rscript -e "install.packages('geojsonio', repos='https://mirror.las.iastate.edu/CRAN')" && \
    Rscript -e "install.packages('sf', repos='https://mirror.las.iastate.edu/CRAN')" && \
    Rscript -e "install.packages('plotly', repos='https://mirror.las.iastate.edu/CRAN')" && \
    Rscript -e "install.packages('tidyr', repos='https://mirror.las.iastate.edu/CRAN')" && \
    Rscript -e "install.packages('wesanderson', repos='https://mirror.las.iastate.edu/CRAN')" ;

USER 1001

EXPOSE 3838

STOPSIGNAL SIGTERM

CMD ["/usr/libexec/s2i/run"]
