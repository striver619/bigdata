FROM openeuler-20.09-x86:latest

LABEL org.opencontainers.image.source="https://github.com/liusheng/dockerfile"
LABEL maintainer="liusheng2048@gmail.com"

SHELL ["/bin/bash", "-o", "pipefail", "-c"]

RUN sed -i s'/TMOUT=300/TMOUT=3000000000/' /etc/bashrc

######
# Install common dependencies from packages
######
RUN yum update -y \
    && yum install -y \
        autoconf \
        automake \
        libtool \
        cmake \
        pkg-config \
        curl \
        sudo \
        git \
        bind-utils \
        openssh-server \
        snappy \
        snappy-devel \
        bzip2 \
        libzip-devel \
        java-1.8.0-openjdk \
        java-1.8.0-openjdk-devel \
        maven

ENV JAVA_HOME /usr/lib/jvm/java-1.8.0-openjdk-1.8.0.265.b01-6.oe1.x86_64

RUN groupadd hadoop
RUN useradd -m -d /home/hadoop -s /bin/bash hadoop -g hadoop
RUN echo "hadoop ALL=(ALL) NOPASSWD: ALL" >> /etc/sudoers

USER hadoop
WORKDIR /home/hadoop

RUN curl -L https://downloads.apache.org/hadoop/common/hadoop-3.3.0/hadoop-3.3.0.tar.gz | tar zx

ENV HADOOP_HOME /home/hadoop/hadoop-3.3.0
COPY --chown=hadoop:hadoop core-site.xml hdfs-site.xml mapred-site.xml yarn-site.xml $HADOOP_HOME/etc/hadoop/
ENV PATH "${PATH}:$HADOOP_HOME/bin:$HADOOP_HOME/sbin"

COPY --chown=hadoop:hadoop entrypoint.sh /home/hadoop/
RUN chmod +x /home/hadoop/entrypoint.sh

ENTRYPOINT ["/home/hadoop/entrypoint.sh"]
