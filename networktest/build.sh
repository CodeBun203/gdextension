#!/bin/sh
echo -ne '\033c\033]0;NetworkTest\a'
base_path="$(dirname "$(realpath "$0")")"
"$base_path/build.x86_64" "$@"
