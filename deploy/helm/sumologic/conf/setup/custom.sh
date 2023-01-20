#!/bin/bash
#
# This script copies files from /customer-scripts to /scripts/<dirname> basing on the filename
#
# Example file structure:
#
# /customer-scripts
# ├── dir1_main.tf
# ├── dir1_setup.sh
# ├── dir2_list.txt
# └── dir2_setup.sh
#
# Expected structure:
#
# /scripts
# ├── dir1
# │   ├── main.tf
# │   └── setup.sh
# └── dir2
#     ├── list.txt
#     └── setup.sh
#
# shellcheck disable=SC2010
# extract target directory names from the file names using _ as separator

set -euo pipefail

err_report() {
    echo "Custom script error on line $1"
    exit 1
}
trap 'err_report $LINENO' ERR

declare -a dirs
ls -1 /customer-scripts 2>/dev/null | grep _ | grep -oE '^.*?_' | sed 's/_//g' | sort | uniq | read -ar dirs || true
for dir in "${dirs[@]}"; do
  target="/scripts/${dir}"
  mkdir "${target}"
  # Get files for given directory and take only filename part (after first _)
  declare -a files
  ls -1 /customer-scripts 2>/dev/null | grep _ | grep -oE '^.*?_' | sed 's/_//g' | sort | uniq | read -ar files || true
  for file in "${files[@]}"; do
    cp "/customer-scripts/${dir}_${file}" "${target}/${file}"
  done

  if [[ ! -f setup.sh ]]; then
    echo "You're missing setup.sh script in custom scripts directory: '${dir}'"
    continue
  fi

  cd "${target}" && bash setup.sh
done
