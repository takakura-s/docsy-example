#!/bin/bash

PROJECT=$1
shift
MODE=$1

echo "Running mode is [ $MODE ]."

cd /app

if [ -e $PROJECT ]; then
  cd $PROJECT
  git submodule update
fi

if [ $MODE = "build" ]; then
  path=$(pwd)
  if [ ! -e public ]; then
    mkdir public
  fi
  cd /temp
  ln -s $path/.* ./ &>/dev/null
  ln -s $path/* ./ &>/dev/null
  ln -s /node/node_modules/ ./
  hugo
elif [ $MODE = "bash" ]; then
  bash
elif [ $MODE = "server" ]; then
  hugo server --bind 0.0.0.0
fi
