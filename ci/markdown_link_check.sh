#!/usr/bin/env bash

if ! markdown-link-check --help >/dev/null 2>&1 ; then
    echo "markdown-link-check not found, please install it with 'npm install -g markdown-link-check'"
    exit 1
fi

# Get all markdown files
readonly FILES=$(find . -type f -name '*.md')

for file in ${FILES}; do
    markdown-link-check --progress --config .markdown_link_check.json "${file}"
done
