#!/bin/bash

PROJECT=$1
shift
MODE=$1

echo "Running mode is [ $MODE ]"

cd /app

if [ -e $PROJECT ]; then
  cd $PROJECT
  git submodule update
fi

case $MODE in
  "build" )
      path=$(pwd)
      if [ ! -e public ]; then
        mkdir public
      fi
      cd /temp
      ln -s $path/.* ./ &>/dev/null
      ln -s $path/* ./ &>/dev/null
      ln -s /node/node_modules/ ./
      hugo
      touch /share/done-build;;
  "server" )
      hugo server --bind 0.0.0.0;;
  "bash" )
      bash;;
  "deploy" )
      until [ -e /share/done-build ]; do sleep 1; done;
      rm /share/done-build
      az storage blob upload-batch -d '$web' -s /app/$STATIC_CONTENT_DIR --account-name $BLOB_ACCOUNT_NAME --sas-token $BLOB_SAS
      echo "OK!!";;
  "pdf" )
      until [ $(curl -LI $DOCSY_URL -o /dev/null -s -w '%{http_code}\n') -eq 200 ]; do sleep 1; done;
      /usr/local/bin/entrypoint --include-background --url $DOCSY_URL --pdf out.pdf;;
  *)
      echo "Unknown mode."
esac
