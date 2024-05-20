FROM almalinux:8 as build
RUN dnf -y update && dnf -y groupinstall "Development Tools" && \ 
    dnf -y install wget cmake openssl-devel  ncurses-devel libtirpc-devel  \
    gcc-toolset-12-gcc gcc-toolset-12-gcc-c++ gcc-toolset-12-binutils \
    gcc-toolset-12-annobin-annocheck gcc-toolset-12-annobin-plugin-gcc
WORKDIR /mysql
RUN wget https://github.com/thkukuk/rpcsvc-proto/releases/download/v1.4/rpcsvc-proto-1.4.tar.gz && \
    tar -xvzf rpcsvc-proto-1.4.tar.gz && \
    cd rpcsvc-proto-1.4/ && \
    ./configure && \
    make && \
    make install && cd .. && \
    wget https://dev.mysql.com/get/Downloads/MySQL-8.4/mysql-8.4.0.tar.gz && \
    tar -xzf mysql-8.4.0.tar.gz && \
    cd mysql-8.4.0 && mkdir build && cd build && mkdir -p /dist /var/run/mysqld /var/lib/mysql && \
    cmake .. \
    -DWITH_BOOST=../extra/boost/boost_1_84_0/boost \
    -DCMAKE_INSTALL_PREFIX=/dist \
    -DMYSQL_UNIX_ADDR=/var/run/mysqld/mysql.sock \
    -DMYSQLX_UNIX_ADDR=/var/run/mysqld/mysqlx.sock \
    -DSYSCONFDIR=/etc/mysql \
    -DSYSTEMD_PID_DIR=/var/run/mysqld \
    -DMYSQL_DATADIR=/var/lib/mysql \
    -DDEFAULT_CHARSET=utf8  \
    -DDEFAULT_COLLATION=utf8_general_ci \
    -DWITH_INNOBASE_STORAGE_ENGINE=1 \
    -DWITH_ARCHIVE_STORAGE_ENGINE=1 \
    -DWITH_BLACKHOLE_STORAGE_ENGINE=1 \
    -DWITH_PERFSCHEMA_STORAGE_ENGINE=1 \
    -DFORCE_INSOURCE_BUILD=1 && \
    make -j `grep processor /proc/cpuinfo | wc -l` && make install

FROM almalinux:8
RUN dnf -y update
RUN groupadd -r mysql && useradd -r -g mysql mysql
RUN mkdir -p /var/run/mysqld /etc/mysql /var/lib/mysql /usr/local/mysql && \
    chown -R mysql:mysql /var/lib/mysql /var/run/mysqld /etc/mysql /usr/local/mysql && \ 
    chmod 1777 /var/run/mysqld /var/lib/mysql /etc/mysql /usr/local/mysql
COPY --from=build /dist /usr/local/mysql
COPY config/ /etc/mysql/
COPY docker-entrypoint.sh /usr/local/bin/
RUN ln -s /usr/local/bin/docker-entrypoint.sh /entrypoint.sh 
ENV PATH="/usr/local/mysql:/usr/local/bin:${PATH}"
ENTRYPOINT ["docker-entrypoint.sh"]

EXPOSE 3306 33060
CMD ["mysqld"]
