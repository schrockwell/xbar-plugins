#! /bin/bash

which gh >> /dev/null

if [ $? -ne 0 ]; then
    echo "GitHub client 'gh' is not installed; install with 'brew install gh' and try again"
    exit 1
fi

set -e

dest_dir="/Users/$(whoami)/Library/Application Support/xbar/plugins/github-prs.rb"

ln -vs "$(pwd)/github-prs.rb" "$dest_dir"