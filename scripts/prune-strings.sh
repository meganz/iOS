#!/bin/sh

echo "This script should be executed from the root of the project"
echo "executing prune script"

# Run the commands
python3 ./iosTransifex/iosTransifex.py -m clean
python3 ./iosTransifex/iosTransifex.py -m clean -r lib
python3 ./iosTransifex/iosTransifex.py -m lang -r Localizable

echo "prune script finished"
