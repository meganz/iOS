#!/bin/bash

if [[ " $* " == *" --verbose "* ]]; then
    swift run PrepareHotfix --verbose
else
    swift run
fi
