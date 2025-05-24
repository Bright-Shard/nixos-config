#!/bin/sh

ROOT=$(dirname $0)
cd $ROOT
find . -name '*.nix' | xargs nixfmt -s
cd - > /dev/null
