#!/bin/bash
set -e

PROJECT=$1
MODE=$2

echo "Running mode is [ $MODE ]"

cd /app

if [ -e $PROJECT ]; then
  cd $PROJECT
fi

function wait_file_exist() {
  check_file=$1
  for i in {0..180}; do [ -e $check_file ] && break; sleep 1; done
  [ -e $check_file ] || exit 100
}

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
        touch /share/done-build
        echo "Finished build";;
    "server" )
        hugo server --bind 0.0.0.0;;
    "bash" )
        bash;;
    "deploy" )
        echo "Wait for build."
        wait_file_exist /share/done-build 
        echo "Start deploy."
        rm /share/done-build
        az storage blob upload-batch -d '$web' -s /app/$STATIC_CONTENT_DIR --account-name $BLOB_ACCOUNT_NAME --sas-token $BLOB_SAS
        touch /share/done-deploy
        echo "Finished deploy";;
    "pdf" )
        echo "Wait for site."
        for i in {0..120}; do
          [ $i -ge 120 ] && exit 100
          [ $(curl -LI $DOCSY_URL -o /dev/null -s -w '%{http_code}\n') -eq 200 ] && break
          sleep 1
        done
        echo "Start creating PDF."
        pdf_file=/app/$STATIC_CONTENT_DIR/$PDF_FILE
        mkdir -p $(dirname $pdf_file)
        /usr/local/bin/entrypoint --include-background --url $DOCSY_URL --pdf $pdf_file
        echo "Finished pdf";;
    "deploy-with-pdf" )
        MODE="deploy"
        run_main
        echo "Wait for pdf."
        wait_file_exist /share/done-pdf
        echo "Start deploy for PDF."
        pdf_dir=$(dirname $PDF_FILE)
        az storage blob upload-batch -d '$web/'$pdf_dir -s /app/$STATIC_CONTENT_DIR/$pdf_dir --account-name $BLOB_ACCOUNT_NAME --sas-token $BLOB_SAS
        touch /share/done-deploy-pdf
        echo "Finished deploy-with-pdf";;
    "deploy-after-pdf" )
        echo "Wait for deploy."
        wait_file_exist /share/done-deploy
        MODE="pdf"
        run_main
        touch /share/done-pdf
        echo "Finished deploy-after-pdf";;
    *)
        echo "Unknown mode."
  esac
}

run_main
