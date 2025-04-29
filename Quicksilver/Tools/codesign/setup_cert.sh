#!/usr/bin/env bash

set -exu

certificateFile="codesign"
certificatePassword=$(openssl rand -base64 12)

# cd to Quicksilver directory if 'Tools' is not a subdirectory of the current directory
if [[ ! -d "Tools" ]]; then
  cd "Quicksilver"
fi

./Tools/codesign/generate_selfsigned_certificate.sh "${certificateFile}" "${certificatePassword}"

# check if running in CI and use import_certificate_into_new_keychain.sh
if [[ "${CI:-}" == "true" ]]; then
  ./Tools/codesign/import_certificate_into_new_keychain.sh "${certificateFile}" "${certificatePassword}"
else
  # Otherwise, use import_certificate_into_main_keychain.sh
  ./Tools/codesign/import_certificate_into_main_keychain.sh "${certificateFile}" "${certificatePassword}"
fi
