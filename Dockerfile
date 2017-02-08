##
##  HHVM - http://hhvm.com/
##  ----------------------------------------------------------------------
##  Docker file creates a HHVM service that supports PHP processing.
##  HHVM is an open-source virtual machine designed for executing
##  programs written in Hack and PHP. HHVM uses a just-in-time (JIT)
##  compilation approach to achieve superior performance while maintaining the
##  development flexibility that PHP provides.HHVM supports Hack, PHP 5 and the
##  major features of PHP 7.
##  -------------------------------------------------------------
##  Copyright (C) 2015 Openbridge, Inc. - All Rights Reserved
##  Permission to copy and modify is granted under the Apache license 2.0
##  Last revised 02/08/2017
##  version 0.3
##

###################
# OPERATING SYTSEM
###################

# The container uses CentOS 7.x
FROM centos:latest
MAINTAINER Thomas Spicer (thomas@openbridge.com)

###################
# STORAGE
###################

# Set the volume to to store activity
# /ebs is a standard mount point from the host
VOLUME ["/ebs"]

###################
# YUM PACKAGES
###################

# Add the latests EPEL 7 Repo
RUN yum install epel-release -y

# Run the update with the EPEL 7 Repo
RUN yum update -y

    # Install the required packages
RUN yum install -y \
    cpp gcc-c++ cmake git psmisc {binutils,boost,jemalloc,numactl}-devel \
    {ImageMagick,sqlite,tbb,bzip2,openldap,readline,elfutils-libelf,gmp,lz4,pcre}-devel \
    lib{xslt,event,yaml,vpx,png,zip,icu,mcrypt,memcached,cap,dwarf}-devel \
    {unixODBC,expat,mariadb}-devel lib{edit,curl,xml2,xslt}-devel \
    glog-devel oniguruma-devel ocaml gperf enca libjpeg-turbo-devel openssl-devel \
    mariadb mariadb-server make \
    inotify-tools \
    geoip \
    zeromq-devel \
    inotify-tools-devel \
    {fribidi,libc-client}-devel

###################
# HHVM
###################

RUN rpm -Uvh http://mirrors.linuxeye.com/hhvm-repo/7/x86_64/hhvm-3.15.3-1.el7.centos.x86_64.rpm

# Compile directly
# RUN    cd /tmp ;\
#       git clone https://github.com/facebook/hhvm -b master  hhvm  --recursive ;\
#       cd hhvm ;\
#       cmake . ;\
#       make -j$(($(nproc)+1)) ;\
#       ./hphp/hhvm/hhvm --version ;\
#       make install ;\
#       mkdir -p /var/run/hhvm ;\
#       hhvm --version

ADD etc/hhvm/server.ini /etc/hhvm/server.ini
ADD etc/hhvm/php.ini /etc/hhvm/php.ini

###################
# NETWORK
###################

# For HHVM
EXPOSE 8000

# For MONIT
EXPOSE 2879

###################
# MONIT
###################

ENV MONIT_VERSION 5.20.0

# Add Monit binary
RUN mkdir -p /tmp/monit ;\
    yum install wget -y ;\
    cd /tmp/monit ;\
    wget https://bitbucket.org/tildeslash/monit/downloads/monit-${MONIT_VERSION}-linux-x64.tar.gz ;\
    tar -xf monit* && cd monit* ;\
    rm -Rf /usr/local/bin/mont ;\
    mv bin/monit /usr/local/bin ;\
    chmod u+x /usr/local/bin/monit ;\
    ln /usr/local/bin/monit /usr/bin/monit

ADD etc/monitrc /etc/monitrc
COPY etc/monit.d/* /etc/monit.d/

###################
# CLEANUP
###################

RUN ln -sf /usr/share/zoneinfo/UTC /etc/localtime

# Tidy up everything before we launch the container
RUN rm -rf /tmp/*

###################
# STARTUP
###################

# Add users for programs that need them
RUN groupadd nginx ;\
    groupmod -g 2011 nginx ;\
    useradd -u 2011 -s /bin/false -d /bin/null -c "nginx user" -g nginx nginx

# When this is present it prevents crond from running
#RUN sed -i '/session    required   pam_loginuid.so/d' /etc/pam.d/crond

# Setup the Init services
COPY etc/init.d/* /etc/init.d/

# Auto start services
RUN chmod +x /etc/init.d/crond ;\
    chkconfig crond --add ;\
    chkconfig crond on

RUN chmod +x /etc/init.d/hhvm ;\
    chkconfig hhvm --add ;\
    chkconfig hhvm on

ADD usr/local/bin/startup.sh /usr/local/bin/startup.sh

RUN chmod +x /usr/local/bin/startup.sh

CMD ["/usr/local/bin/startup.sh"]
