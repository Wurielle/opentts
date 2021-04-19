# -----------------------------------------------------------------------------
# Dockerfile for OpenTTS (https://github.com/synesthesiam/opentts)
# Requires Docker buildx: https://docs.docker.com/buildx/working-with-buildx/
# See scripts/build-docker.sh
#
# The IFDEF statements are handled by docker/preprocess.sh. These are just
# comments that are uncommented if the environment variable after the IFDEF is
# not empty.
#
# The build-docker.sh script will optionally add apt/pypi proxies running locally:
# * apt - https://docs.docker.com/engine/examples/apt-cacher-ng/
# * pypi - https://github.com/jayfk/docker-pypi-cache
# -----------------------------------------------------------------------------

FROM ubuntu:eoan
ARG TARGETARCH
ARG TARGETVARIANT

ENV LANG C.UTF-8

# IFDEF PROXY
#! RUN echo 'Acquire::http { Proxy "http://${PROXY}"; };' >> /etc/apt/apt.conf.d/01proxy
# ENDIF

RUN cat /etc/apt/sources.list
RUN echo '\n\
# See http://help.ubuntu.com/community/UpgradeNotes for how to upgrade to \n\
# newer versions of the distribution. \n\
deb http://archive.ubuntu.com/ubuntu/ eoan main restricted \n\
# deb-src http://archive.ubuntu.com/ubuntu/ eoan main restricted \n\
## Major bug fix updates produced after the final release of the \n\
## distribution. \n\
deb http://archive.ubuntu.com/ubuntu/ eoan-updates main restricted \n\
# deb-src http://archive.ubuntu.com/ubuntu/ eoan-updates main restricted \n\
## N.B. software from this repository is ENTIRELY UNSUPPORTED by the Ubuntu \n\
## team. Also, please note that software in universe WILL NOT receive any \n\
## review or updates from the Ubuntu security team. \n\
deb http://archive.ubuntu.com/ubuntu/ eoan universe \n\
# deb-src http://archive.ubuntu.com/ubuntu/ eoan universe \n\
deb http://archive.ubuntu.com/ubuntu/ eoan-updates universe \n\
# deb-src http://archive.ubuntu.com/ubuntu/ eoan-updates universe \n\
## N.B. software from this repository is ENTIRELY UNSUPPORTED by the Ubuntu \n\
## team, and may not be under a free licence. Please satisfy yourself as to \n\
## your rights to use the software. Also, please note that software in \n\
## multiverse WILL NOT receive any review or updates from the Ubuntu \n\
## security team. \n\
deb http://archive.ubuntu.com/ubuntu/ eoan multiverse \n\
# deb-src http://archive.ubuntu.com/ubuntu/ eoan multiverse \n\
deb http://archive.ubuntu.com/ubuntu/ eoan-updates multiverse \n\
# deb-src http://archive.ubuntu.com/ubuntu/ eoan-updates multiverse \n\
## N.B. software from this repository may not have been tested as \n\
## extensively as that contained in the main release, although it includes \n\
## newer versions of some applications which may provide useful features. \n\
## Also, please note that software in backports WILL NOT receive any review \n\
## or updates from the Ubuntu security team. \n\
deb http://archive.ubuntu.com/ubuntu/ eoan-backports main restricted universe multiverse \n\
# deb-src http://archive.ubuntu.com/ubuntu/ eoan-backports main restricted universe multiverse \n\
## Uncomment the following two lines to add software from Canonical\'s \n\
## \'partner\' repository. \n\
## This software is not part of Ubuntu, but is offered by Canonical and the \n\
## respective vendors as a service to Ubuntu users. \n\
# deb http://archive.canonical.com/ubuntu eoan partner \n\
# deb-src http://archive.canonical.com/ubuntu eoan partner \n\
deb http://security.ubuntu.com/ubuntu/ eoan-security main restricted \n\
# deb-src http://security.ubuntu.com/ubuntu/ eoan-security main restricted \n\
deb http://security.ubuntu.com/ubuntu/ eoan-security universe \n\
# deb-src http://security.ubuntu.com/ubuntu/ eoan-security universe \n\
deb http://security.ubuntu.com/ubuntu/ eoan-security multiverse \n\
# deb-src http://security.ubuntu.com/ubuntu/ eoan-security multiverse \n\
\n\
deb http://archive.ubuntu.com/ubuntu bionic main universe multiverse restricted \n\
deb http://security.ubuntu.com/ubuntu/ bionic-security main multiverse universe restricted \n\
deb http://archive.ubuntu.com/ubuntu bionic-updates main multiverse universe restricted \n\
' > /etc/apt/sources.list
RUN cat /etc/apt/sources.list
RUN apt update

RUN apt-get update && \
    apt-get install --yes --no-install-recommends \
        python3 python3-pip python3-venv \
        sox wget ca-certificates \
        flite espeak-ng festival \
        festvox-ca-ona-hts \
        festvox-czech-dita \
        festvox-czech-krb \
        festvox-czech-machac \
        festvox-czech-ph \
        festvox-don \
        festvox-ellpc11k \
        festvox-en1 \
        festvox-kallpc16k \
        festvox-kdlpc16k \
        festvox-rablpc16k \
        festvox-us1 \
        festvox-us2 \
        festvox-us3 \
        festvox-us-slt-hts \
        festvox-ru \
        festvox-suopuhe-lj \
        festvox-suopuhe-mv

# Install prebuilt nanoTTS
RUN wget -O - --no-check-certificate \
    "https://github.com/synesthesiam/prebuilt-apps/releases/download/v1.0/nanotts-20200520_${TARGETARCH}${TARGETVARIANT}.tar.gz" | \
    tar -C /usr -xzf -

# IFDEF PYPI
#! ENV PIP_INDEX_URL=http://${PYPI}/simple/
#! ENV PIP_TRUSTED_HOST=${PYPI_HOST}
# ENDIF

COPY requirements.txt /app/
COPY scripts/create-venv.sh /app/scripts/

# Install web server
RUN cd /app && \
    scripts/create-venv.sh

# Copy other files
COPY voices/ /app/voices/
COPY img/ /app/img/
COPY css/ /app/css/
COPY app.py tts.py swagger.yaml /app/
COPY templates/index.html /app/templates/

WORKDIR /app

EXPOSE 5500

ENTRYPOINT ["/app/.venv/bin/python3", "/app/app.py"]
