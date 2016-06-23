#!/bin/bash
set -xe

bundle install
git submodule update --init
cd amphtml
npm install
cd validator
npm install
