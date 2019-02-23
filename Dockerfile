FROM ubuntu:bionic-20190204

ARG BUILD_DATE
ARG VCS_REF

# https://github.com/saltstack/salt/releases
ENV SALT_VERSION="2018.3.4" \
    PYTHON_VERSION="3.6" \
    LIBSSH2_VERSION="1.8.0" \
    LIBGIT2_VERSION="0.27.7" \
    PYGIT2_VERSION="0.27.2" \
    GITPYTHON_VERSION="2.1.11" \
    M2CRYPTO_VERSION="0.31.0" \
    MAKO_VERSION="1.0.7" \
    PYCRYPTODOME_VERSION="3.7.2" \
    LIBNACL_VERSION="1.6.1" \
    RAET_VERSION="0.6.8" \
    CHERRYPY_VERSION="18.0.1" \
    TIMELIB_VERSION="0.2.4" \
    DOCKERPY_VERSION="1.10.6" \
    MSGPACKPURE_VERSION="0.1.3"

ENV SALT_DOCKER_DIR="/etc/docker-salt" \
    SALT_ROOT_DIR="/etc/salt" \
    SALT_CACHE_DIR='/var/cache/salt' \
    SALT_USER="salt" \
    SALT_HOME="/home/salt"

ENV SALT_BUILD_DIR="${SALT_DOCKER_DIR}/build" \
    SALT_RUNTIME_DIR="${SALT_DOCKER_DIR}/runtime" \
    SALT_DATA_DIR="${SALT_HOME}/data"

ENV SALT_CONFS_DIR="${SALT_DATA_DIR}/config" \
    SALT_KEYS_DIR="${SALT_DATA_DIR}/keys" \
    SALT_BASE_DIR="${SALT_DATA_DIR}/srv" \
    SALT_LOGS_DIR="${SALT_DATA_DIR}/logs"

# Set non interactive mode
ENV DEBIAN_FRONTEND=noninteractive

RUN mkdir -p ${SALT_BUILD_DIR}
WORKDIR ${SALT_BUILD_DIR}

# Install packages
RUN apt-get update
RUN apt-get install --yes --quiet --no-install-recommends \
    sudo ca-certificates wget locales pkg-config openssh-client \
    python${PYTHON_VERSION} python${PYTHON_VERSION}-dev \
    python3-pip python3-setuptools python3-wheel gettext-base \
    supervisor logrotate

# Configure locales
RUN update-locale LANG=C.UTF-8 LC_MESSAGES=POSIX \
    locale-gen en_US.UTF-8 \
    dpkg-reconfigure locales

# Install saltstack
COPY assets/build ${SALT_BUILD_DIR}
RUN bash ${SALT_BUILD_DIR}/install.sh

# Shared resources
EXPOSE 4505/tcp 4506/tcp
RUN mkdir -p ${SALT_DATA_DIR} ${SALT_BASE_DIR} ${SALT_KEYS_DIR} ${SALT_CONFS_DIR} ${SALT_LOGS_DIR}
VOLUME [ "${SALT_BASE_DIR}" "${SALT_KEYS_DIR}" "${SALT_CONFS_DIR}" "${SALT_LOGS_DIR}" ]

COPY assets/runtime ${SALT_RUNTIME_DIR}
RUN chmod -R +x ${SALT_RUNTIME_DIR}

# Cleaning tasks
RUN apt-get clean --yes
RUN rm -rf /var/lib/apt/lists/*
RUN rm -rf ${SALT_BUILD_DIR}/*

# Entrypoint
COPY entrypoint.sh /sbin/entrypoint.sh
RUN chmod +x /sbin/entrypoint.sh

LABEL \
    maintainer="github@cdalvaro.io" \
    org.label-schema.vendor=cdalvaro \
    org.label-schema.name="SaltStack Master" \
    org.label-schema.version=${SALT_VERSION} \
    org.label-schema.description="Dockerized SaltStack Master" \
    org.label-schema.url="https://github.com/cdalvaro/saltstack-master" \
    org.label-schema.vcs-url="https://github.com/cdalvaro/saltstack-master.git" \
    org.label-schema.vcs-ref=${VCS_REF} \
    org.label-schema.build-date=${BUILD_DATE} \
    org.label-schema.docker.schema-version="1.0" \
    com.cdalvaro.saltstack-master.license=MIT

WORKDIR ${SALT_HOME}
ENTRYPOINT [ "/sbin/entrypoint.sh" ]
CMD [ "app:start" ]
