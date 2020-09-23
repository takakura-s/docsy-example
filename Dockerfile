FROM node:14.10.1-stretch
WORKDIR /hugo
WORKDIR /node
WORKDIR /temp

RUN apt-get update
RUN apt-get -y install locales-all

ENV LANG ja_JP.UTF-8
ENV LANGUAGE ja_JP:ja
ENV LC_ALL ja_JP.UTF-8

RUN cd /hugo \
&& wget -q https://github.com/gohugoio/hugo/releases/download/v0.74.3/hugo_extended_0.74.3_Linux-64bit.tar.gz \
&& tar xvf hugo_extended_0.74.3_Linux-64bit.tar.gz \
&& rm hugo_extended_0.74.3_Linux-64bit.tar.gz \
&& install hugo /usr/bin

COPY package*.json /node/

RUN cd /node \
&& npm i

ENV PROJECT docsy-example
ENV GIT https://github.com/google/docsy-example.git

RUN cd /temp \
&& echo "\
cd /app \n\
if [ ! -e .git ]; then \n\
  if [ -e $PROJECT ]; then \n\
    cd $PROJECT \n\
    git pull \n\
  else \n\
    git clone --recurse-submodules --depth 1 $GIT \n\
    cd $PROJECT \n\
  fi \n\
fi \n\
bash run.sh "'$PROJECT $@'" \n\
" > boot.sh


ENTRYPOINT ["sh", "/temp/boot.sh"]

CMD ["build"]
