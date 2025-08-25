#!/bin/sh

PACKAGE_ROOT="./Modules/Presentation/MEGAL10n"
RESOURCES_PATH="./Framework/MEGAL10n/MEGAL10n/Resources"

echo "Go to MEGAL10n package root at $PACKAGE_ROOT"
cd $PACKAGE_ROOT || exit 1

echo "Running from script dir: $(pwd)"

if [[ -n $(git status --porcelain $RESOURCES_PATH) ]]; then
  source ./build_xcframework.sh
else
  echo "No changes, skip building xcframework"
fi

exit 0
