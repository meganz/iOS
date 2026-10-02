#!/bin/bash
# Copies the cmark spec test files that match the swift-cmark revision pinned in Package.resolved.
# Run `bash scripts/refresh-cmark-spec.sh` after a swift-cmark pin bump.
# SpecCorpusRevisionTests fails until the copy is refreshed.
set -euo pipefail

package_dir="$(cd "$(dirname "$0")/.." && pwd)"
target="$package_dir/Tests/MEGAMarkdownTests/Fixtures/cmark-spec"
revision="$(python3 -c '
import json, sys
pins = json.load(open(sys.argv[1]))["pins"]
print(next(p["state"]["revision"] for p in pins if p["identity"] == "swift-cmark"))
' "$package_dir/Package.resolved")"

echo "swift-cmark revision: $revision"
for name in spec.txt extensions.txt regression.txt smart_punct.txt; do
    curl --fail --silent --show-error --location \
        "https://raw.githubusercontent.com/swiftlang/swift-cmark/$revision/test/$name" \
        --output "$target/$name"
    echo "updated $name"
done
printf '%s\n' "$revision" > "$target/REVISION"
echo "wrote REVISION"
