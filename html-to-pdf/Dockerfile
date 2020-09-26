FROM node:14.11.0-alpine3.12

RUN apk update \
    && apk add --no-cache \
      chromium \
      nodejs \
      npm \
      sed \
      bash \
      procps

# RUN apk add --no-cache curl fontconfig font-noto-cjk \
#   && fc-cache -fv

RUN apk add --no-cache curl fontconfig \
  && curl -O https://noto-website.storage.googleapis.com/pkgs/NotoSansCJKjp-hinted.zip \
  && mkdir -p /usr/share/fonts/NotoSansCJKjp \
  && unzip NotoSansCJKjp-hinted.zip -d /usr/share/fonts/NotoSansCJKjp/ \
  && rm NotoSansCJKjp-hinted.zip \
  && fc-cache -fv

RUN npm install -g \
      chrome-headless-render-pdf \
      node-static

COPY entrypoint.bash /usr/local/bin/entrypoint
COPY chrome-wrapper.bash /usr/local/bin/chrome-wrapper

RUN mkdir /tmp/html-to-pdf \
    && chmod +x /usr/local/bin/*

ARG WORKDIR="/app"
ENV WORKDIR="${WORKDIR}"

# WORKDIR "${WORKDIR}"
WORKDIR /temp

RUN echo -e "\
cd /app \n\
until [ -e /share/updated-git ]; do sleep 1; done; \n\
bash run.sh "'dummy $@'" \n\
" > boot.sh

ENTRYPOINT ["bash", "/temp/boot.sh"]

# ENTRYPOINT [ "/usr/local/bin/entrypoint" ]

CMD ["pdf"]
