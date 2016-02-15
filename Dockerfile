FROM centos:7

RUN yum install -y \
        gcc \
        autoconf \
        automake \
        curl \
        gettext-devel \
        libev-devel \
        pcre-devel \
        perl \
        pkgconfig \
        rpm-build \
        udns-devel \
        git && \
    yum clean all

ADD . /opt/sniproxy

RUN cd /opt/sniproxy && \
        ./autogen.sh && \
        ./configure && \
        make dist && \
        rpmbuild --define "_sourcedir $(pwd)" -ba redhat/sniproxy.spec && \
    yum install -y /root/rpmbuild/RPMS/x86_64/sniproxy-0.4.0-1.el7.centos.x86_64.rpm && \
    yum clean all

