#!/usr/bin/env bash
# BASH3 Boilerplate: ini_val
#
# This file:
#
#  - Can read and write .ini files using pure bash
#
# Limitations:
#
#  - All keys inside a section of the .ini file must be unique
#  - Optional comment parameter for the creation of new entries
#
# Usage as a function:
#
#  source ini_val.sh
#  ini_val data.ini connection.host 127.0.0.1 "Host name or IP address"
#
# Usage as a command:
#
#  ini_val.sh data.ini connection.host 127.0.0.1 "Host name or IP address"
#
# Based on a template by BASH3 Boilerplate v2.4.1
# http://bash3boilerplate.sh/#authors
#
# The MIT License (MIT)
# Copyright (c) 2013 Kevin van Zonneveld and contributors
# You are not obligated to bundle the LICENSE file with your b3bp projects as long
# as you leave these references intact in the header comments of your source files.

function ini_val() {
  local file="${1:-}"
  local sectionkey="${2:-}"
  local val="${3:-}"
  local comment="${4:-}"
  local delim="="
  local comment_delim=";"
  local section=""
  local key=""
  local current=""
  # add default section
  local section_default="default"

  if [[ ! -f "${file}" ]]; then
    # touch file if not exists
    touch "${file}"
  fi

  # Split on . for section. However, section is optional
  IFS='.' read -r section key <<< "${sectionkey}"
  if [[ ! "${key}" ]]; then
    key="${section}"
    # default section if not given
    section="${section_default}"
  fi

  current=$(sed -En "/^\[/{h;d;};G;s/^${key}([[:blank:]]*)${delim}(.*)\n\[${section}\]$/\2/p" "${file}"|awk '{$1=$1};1')

  if ! grep -q "\[${section}\]" "${file}"; then
    # create section if not exists (empty line to seperate new section)
    echo  >> "${file}"
    echo "[${section}]" >> "${file}"
  fi

  if [[ ! "${val}" ]]; then
    # get a value
    echo "${current}"
  else
    # set a value
    if [[ ! "${current}" ]]; then
      # doesn't exist yet, add
      if [[ ! "${section}" ]]; then
        # if no section is given, propagate the default section
        section=${section_default}
      fi
      # add to section
      if [[ ! "${comment}" ]]; then
        # add new key/value without comment
        RET="/\\[${section}\\]/a\\
${key}${delim}${val}"
      else
        # add new key/value with preceeding comment
        RET="/\\[${section}\\]/a\\
${comment_delim}[${key}] ${comment}\\
${key}${delim}${val}"
      fi
      sed -i.bak -e "${RET}" "${file}"
      # this .bak dance is done for BSD/GNU portability: http://stackoverflow.com/a/22084103/151666
      rm -f "${file}.bak"
    else
      # replace existing (modified to replace only keys in given section)
      sed -i.bak -e "/^\[${section}\]/,/^\[.*\]/ s|^\(${key}[ \t]*${delim}[ \t]*\).*$|\1${val}|" "${file}"
      # this .bak dance is done for BSD/GNU portability: http://stackoverflow.com/a/22084103/151666
      rm -f "${file}.bak"
    fi
  fi
}

if [[ "${BASH_SOURCE[0]}" != "${0}" ]]; then
  export -f ini_val
else
  ini_val "${@}"
  exit ${?}
fi
