#!/bin/bash

# SPM Executables do not have a straightforward way to import an .env file, hence the need of this run script
set -a
source ../Resources/values.env
set +a

if [[ " $* " == *" --verbose "* ]]; then
    swift run AnnounceRelease --verbose
else
    swift run
fi
