# syntax=docker/dockerfile:1
# Candidatos inmovilizados para el spike; no declaran compatibilidad funcional probada.
ARG PG_BASE=postgres:16-bookworm@sha256:e92e17ca202da4bb205f6f4a6c8cb30539edfbaa04987b506630f5d5851ff3c8
FROM ${PG_BASE} AS fdw-build
SHELL ["/bin/bash", "-o", "pipefail", "-c"]

RUN apt-get update && apt-get install -y --no-install-recommends \
    build-essential ca-certificates curl cmake pkg-config freetds-dev \
    libssl-dev libsasl2-dev zlib1g-dev "postgresql-server-dev-16=${PG_VERSION}" \
    && rm -rf /var/lib/apt/lists/*

WORKDIR /src
RUN curl -fsSL --retry 3 https://codeload.github.com/tds-fdw/tds_fdw/tar.gz/5830577908683cb35c760079ec0f105ef7e3ff98 -o tds.tar.gz \
    && echo '03c644bae1e40131e8974884d7aa41c8e6023aceb299ed33ba83bf1474f6d4d6  tds.tar.gz' | sha256sum -c - \
    && mkdir tds_fdw && tar -xzf tds.tar.gz --strip-components=1 -C tds_fdw \
    && make -C tds_fdw USE_PGXS=1 PG_CONFIG=/usr/lib/postgresql/16/bin/pg_config -j2 \
    && make -C tds_fdw USE_PGXS=1 PG_CONFIG=/usr/lib/postgresql/16/bin/pg_config DESTDIR=/out install

RUN curl -fsSL --retry 3 https://github.com/mongodb/mongo-c-driver/releases/download/1.30.2/mongo-c-driver-1.30.2.tar.gz -o mongoc.tar.gz \
    && echo '56224101eccd24bd71e42f806df8332b1280c2294b21b32c2da2d0f77cfa5cbe  mongoc.tar.gz' | sha256sum -c - \
    && mkdir mongo-c-driver && tar -xzf mongoc.tar.gz --strip-components=1 -C mongo-c-driver \
    && cmake -S mongo-c-driver -B mongoc-build -DCMAKE_INSTALL_PREFIX=/opt/mongo \
       -DCMAKE_INSTALL_LIBDIR=lib -DENABLE_AUTOMATIC_INIT_AND_CLEANUP=OFF \
       -DENABLE_SSL=OPENSSL -DENABLE_SASL=CYRUS -DENABLE_TESTS=OFF \
       -DENABLE_EXAMPLES=OFF -DENABLE_STATIC=OFF \
    && cmake --build mongoc-build --parallel 2 \
    && cmake --install mongoc-build

RUN curl -fsSL --retry 3 https://codeload.github.com/EnterpriseDB/mongo_fdw/tar.gz/27aa7b04af197129bf10069c4b512a326c94f3f8 -o mongo_fdw.tar.gz \
    && echo '375ebf5fd85a201a968c8895944f038720b49a17009607b6cbf50143f2648873  mongo_fdw.tar.gz' | sha256sum -c - \
    && mkdir mongo_fdw && tar -xzf mongo_fdw.tar.gz --strip-components=1 -C mongo_fdw \
    && curl -fsSL --retry 3 https://codeload.github.com/json-c/json-c/tar.gz/refs/tags/json-c-0.18-20240915 -o json-c.tar.gz \
    && echo '3112c1f25d39eca661fe3fc663431e130cc6e2f900c081738317fba49d29e298  json-c.tar.gz' | sha256sum -c - \
    && mkdir mongo_fdw/json-c && tar -xzf json-c.tar.gz --strip-components=1 -C mongo_fdw/json-c \
    && cmake -S mongo_fdw/json-c -B mongo_fdw/json-c -DDISABLE_EXTRA_LIBS=ON -DBUILD_TESTING=OFF \
    && cmake --build mongo_fdw/json-c --parallel 2 \
    && PKG_CONFIG_PATH=/opt/mongo/lib/pkgconfig make -C mongo_fdw USE_PGXS=1 PG_CONFIG=/usr/lib/postgresql/16/bin/pg_config -j2 \
    && PKG_CONFIG_PATH=/opt/mongo/lib/pkgconfig make -C mongo_fdw USE_PGXS=1 PG_CONFIG=/usr/lib/postgresql/16/bin/pg_config DESTDIR=/out install

FROM ${PG_BASE}
RUN apt-get update && apt-get install -y --no-install-recommends \
    ca-certificates libsybdb5 libssl3 libsasl2-2 zlib1g \
    && rm -rf /var/lib/apt/lists/*
COPY --from=fdw-build /opt/mongo/lib/ /usr/local/lib/
COPY --from=fdw-build /out/ /
RUN ldconfig \
    && ldd /usr/lib/postgresql/16/lib/tds_fdw.so /usr/lib/postgresql/16/lib/mongo_fdw.so > /tmp/fdw-libs.txt \
    && cat /tmp/fdw-libs.txt && ! grep -q 'not found' /tmp/fdw-libs.txt
COPY docker/postgres/postgresql.conf /etc/postgresql/postgresql.conf
COPY docker/postgres/pg_hba.conf /etc/postgresql/pg_hba.conf
COPY docker/postgres/freetds.conf /etc/freetds/freetds.conf
COPY docker/postgres/initdb/00_fdw.sql /docker-entrypoint-initdb.d/00_fdw.sql
ENV FREETDSCONF=/etc/freetds/freetds.conf
LABEL org.opencontainers.image.description="PostgreSQL 16 + tds_fdw 2.0.5 + mongo_fdw 5.5.3; candidato de validacion Joseph"