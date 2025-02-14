#!/bin/bash

if [[ " $* " == *" --verbose "* ]]; then
    swift run PrepareRelease --verbose
else
    swift run
fi
