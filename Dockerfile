FROM centos:7

LABEL maintainer="Levi Baber <baber@iastate.edu>"

#package installation
RUN yum -y install epel-release && \
	yum -y install R && \
	Rscript -e "install.packages('shiny', repos='https://cran.rstudio.com/')" && \
	yum -y install wget && \
	wget https://download3.rstudio.org/centos5.9/x86_64/shiny-server-1.5.6.875-rh5-x86_64.rpm && \
	yum -y install --nogpgcheck shiny-server-1.5.6.875-rh5-x86_64.rpm

EXPOSE 3838

STOPSIGNAL SIGTERM

CMD ["/opt/shiny-server/bin/shiny-server", "-g", "daemon off;"]
