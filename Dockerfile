FROM node:14.11.0-alpine3.12
WORKDIR /hugo
WORKDIR /node
WORKDIR /temp

RUN apk add bash

# RUN cd /hugo \
# && wget -q https://github.com/gohugoio/hugo/releases/download/v0.74.3/hugo_extended_0.74.3_Linux-64bit.tar.gz \
# && tar xvf hugo_extended_0.74.3_Linux-64bit.tar.gz \
# && rm hugo_extended_0.74.3_Linux-64bit.tar.gz \
# && mv ./hugo /usr/bin/hugo

ENV HUGO_VERSION='0.74.3'
ENV HUGO_NAME="hugo_extended_${HUGO_VERSION}_Linux-64bit"
ENV HUGO_BASE_URL="https://github.com/gohugoio/hugo/releases/download"
ENV HUGO_URL="${HUGO_BASE_URL}/v${HUGO_VERSION}/${HUGO_NAME}.tar.gz"
ENV HUGO_CHECKSUM_URL="${HUGO_BASE_URL}/v${HUGO_VERSION}/hugo_${HUGO_VERSION}_checksums.txt"

SHELL ["/bin/ash", "-eo", "pipefail", "-c"]
RUN apk add --no-cache --virtual .build-deps wget && \
    apk add --no-cache \
    git \
    ca-certificates \
    libc6-compat \
    libstdc++ && \
    wget --quiet "${HUGO_URL}" && \
    wget --quiet "${HUGO_CHECKSUM_URL}" && \
    grep "${HUGO_NAME}.tar.gz" "./hugo_${HUGO_VERSION}_checksums.txt" | sha256sum -c - && \
    tar -zxvf "${HUGO_NAME}.tar.gz" && \
    mv ./hugo /usr/bin/hugo && \
    apk del .build-deps && \
    rm -rf /hugo

COPY package*.json /node/

RUN cd /node \
&& npm i

ENV PROJECT docsy-example
ENV GIT https://github.com/takakura-s/docsy-example.git

RUN cd /temp \
&& git config --global user.email "you@example.com" \
&& git config --global user.name "Your Name" \
&& echo -e "\
cd /app \n\
if [ ! -e .git ]; then \n\
  if [ -e $PROJECT ]; then \n\
    cd $PROJECT \n\
    git fetch \n\
    git reset --hard origin/master \n\
  else \n\
    git clone --recurse-submodules --depth 1 $GIT \n\
    cd $PROJECT \n\
  fi \n\
fi \n\
bash run.sh "'$PROJECT $@'" \n\
" > boot.sh


ENTRYPOINT ["bash", "/temp/boot.sh"]

CMD ["build"]
