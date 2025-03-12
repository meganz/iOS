#!/bin/bash

if [[ " $* " == *" --verbose "* ]]; then
    swift run TagRelease --verbose
else
    swift run
fi
