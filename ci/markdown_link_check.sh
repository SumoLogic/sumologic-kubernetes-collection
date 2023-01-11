#!/usr/bin/env bash

if ! markdown-link-check --help >/dev/null 2>&1 ; then
    echo "markdown-link-check not found, please install it with 'npm install -g markdown-link-check'"
    exit 1
fi

# Get all markdown files
ALL_FILES=$(find . -type f -name '*.md')
readonly ALL_FILES

# Use the files passed as command line arguments if provided, otherwise all of them
readonly FILES=${*:-${ALL_FILES}}

for file in ${FILES}; do
    markdown-link-check --progress --verbose --retry \
        --config .markdown_link_check.json "${file}"
done
