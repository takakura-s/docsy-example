#!/bin/bash
set -e

PROJECT=$1
shift
MODE=$1

echo "Running mode is [ $MODE ]"

cd /app

if [ -e $PROJECT ]; then
  cd $PROJECT
fi

function run_main() {
  case $MODE in
    "build" )
        path=$(pwd)
        if [ ! -e public ]; then
          mkdir public
        fi
        cd /temp
        ln -s $path/.* ./ &>/dev/null
        ln -s $path/* ./ &>/dev/null
        ln -s /node/node_modules/ ./ &>/dev/null
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
        touch /share/done-deploy;;
    "pdf" )
        until [ $(curl -LI $DOCSY_URL -o /dev/null -s -w '%{http_code}\n') -eq 200 ]; do sleep 1; done;
        mkdir -p $(dirname $PDF_FILE)
        /usr/local/bin/entrypoint --include-background --url $DOCSY_URL --pdf /app/$STATIC_CONTENT_DIR/$PDF_FILE;;
    "deploy-with-pdf" )
        MODE="deploy"
        run_main
        until [ -e /share/done-pdf ]; do sleep 1; done;
        pdf_dir=$(dirname $PDF_FILE)
        az storage blob upload-batch -d '$web/$pdf_dir' -s /app/$STATIC_CONTENT_DIR/$pdf_dir --account-name $BLOB_ACCOUNT_NAME --sas-token $BLOB_SAS
        touch /share/done-deploy-pdf;;
    "deploy-after-pdf" )
        until [ -e /share/done-deploy ]; do sleep 1; done;
        MODE="pdf"
        run_main
        touch /share/done-pdf;;
    *)
        echo "Unknown mode."
  esac
}

run_main
