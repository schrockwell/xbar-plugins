#! /bin/bash

set -e

dest_dir="/Users/$(whoami)/Library/Application Support/xbar/plugins/utc-time.rb"

ln -vs "$(pwd)/utc-time.rb" "$dest_dir"