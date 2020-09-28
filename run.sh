#!/bin/bash
set -e

PROJECT=$1
MODE=$2

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
        set +e
        ln -s $path/.* ./ &>/dev/null
        ln -s $path/* ./ &>/dev/null
        ln -s /node/node_modules/ ./ &>/dev/null
        set -e
        hugo
        touch /share/done-build;;
    "server" )
        hugo server --bind 0.0.0.0;;
    "bash" )
        bash;;
    "deploy" )
        echo "Wait for build."
        until [ -e /share/done-build ]; do sleep 1; done;
        echo "Start deploy."
        rm /share/done-build
        az storage blob upload-batch -d '$web' -s /app/$STATIC_CONTENT_DIR --account-name $BLOB_ACCOUNT_NAME --sas-token $BLOB_SAS
        touch /share/done-deploy;;
    "pdf" )
        echo "Wait for site."
        until [ $(curl -LI $DOCSY_URL -o /dev/null -s -w '%{http_code}\n') -eq 200 ]; do sleep 1; done;
        echo "Start creating PDF."
        pdf_file=/app/$STATIC_CONTENT_DIR/$PDF_FILE
        mkdir -p $(dirname $pdf_file)
        /usr/local/bin/entrypoint --include-background --url $DOCSY_URL --pdf $pdf_file;;
    "deploy-with-pdf" )
        MODE="deploy"
        run_main
        echo "Wait for pdf."
        until [ -e /share/done-pdf ]; do sleep 1; done;
        echo "Start deploy for PDF."
echo "PDF_FILE = [$PDF_FILE]"
echo "STATIC_CONTENT_DIR = [$STATIC_CONTENT_DIR]"
        pdf_dir=$(dirname $PDF_FILE)
echo "pdf_dir = [$pdf_dir]"
        az storage blob upload-batch -d '$web/$pdf_dir' -s /app/$STATIC_CONTENT_DIR/$pdf_dir --account-name $BLOB_ACCOUNT_NAME --sas-token $BLOB_SAS
        touch /share/done-deploy-pdf;;
    "deploy-after-pdf" )
        echo "Wait for deploy."
        until [ -e /share/done-deploy ]; do sleep 1; done;
        MODE="pdf"
        run_main
        touch /share/done-pdf;;
    *)
        echo "Unknown mode."
  esac
}

run_main
