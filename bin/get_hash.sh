#!/usr/bin/env bash
file="$(mktemp)"
curl "$1" -o "$file"
hash="$(guix hash "$file")"
rm "$file"
echo "$hash"
