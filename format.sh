#!/bin/sh

ROOT=$(dirname $0)
cd $ROOT
find . -name '*.nix' | xargs nixfmt
cd - > /dev/null
