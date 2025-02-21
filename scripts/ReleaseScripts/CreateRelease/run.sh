#!/bin/bash

if [[ " $* " == *" --verbose "* ]]; then
    swift run CreateRelease --verbose
else
    swift run
fi
