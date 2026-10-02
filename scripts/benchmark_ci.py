#!/usr/bin/env python3
"""Helpers for scripts/benchmark.sh and the Benchmarks CI stage.

benchmark_ci.py packages --repo-root DIR (--all | --base REF) [--output FILE]
    Prints the packages whose benchmarks should run, one folder per line, relative to the repo root.
    A package opts in when it has Tests/<package folder name>Benchmarks/Limits.json.
    --all prints every opted-in package. --base REF prints those that the change from REF to HEAD affects:
    a file in the package, in a local package it depends on (recursively), or in the benchmark tooling.
benchmark_ci.py simulator --name NAME --os VERSION
    Prints the udid of an available iOS simulator with this name and OS, and creates one when the runtime exists.
    Fails when no iOS runtime of that version is installed. It never picks another OS.
benchmark_ci.py skipped FILE
    Checks a skip list ({"Class/test": "reason"}) and prints its test names, one per line.
"""
import argparse
import importlib.util
import json
import os
import re
import subprocess
import sys

# A change to these files can change every benchmark result or check, so it runs every opted-in package.
TOOLING = (
    "scripts/benchmark.sh",
    "scripts/benchmark_report.py",
    "scripts/benchmark_ci.py",
    "jenkinsfile/benchmarks.groovy",
    "fastlane/Fastfile_post_benchmarks",
)
SKIPPED_FOLDERS = {".build", ".swiftpm", ".git", "derivedData", "SourcePackages", "node_modules"}
PACKAGE_PATH = re.compile(r'\.package\(\s*path:\s*"([^"]+)"')


def find_opted_in(repo_root):
    """Folders, relative to the repo root, that hold a Package.swift and Tests/<name>Benchmarks/Limits.json."""
    found = []
    for folder, children, files in os.walk(os.path.join(repo_root, "Modules")):
        children[:] = sorted(child for child in children if child not in SKIPPED_FOLDERS)
        if "Package.swift" not in files:
            continue
        name = os.path.basename(folder)
        if os.path.isfile(os.path.join(folder, "Tests", name + "Benchmarks", "Limits.json")):
            found.append(os.path.relpath(folder, repo_root))
    return sorted(found)


def local_dependencies(repo_root, package):
    """The package folder and every local package it depends on, recursively, relative to the repo root."""
    seen = []
    pending = [os.path.normpath(package)]
    while pending:
        folder = pending.pop()
        if folder.lower() in (item.lower() for item in seen):
            continue
        seen.append(folder)
        manifest = os.path.join(repo_root, folder, "Package.swift")
        if not os.path.isfile(manifest):
            continue
        with open(manifest) as handle:
            text = handle.read()
        pending += [os.path.normpath(os.path.join(folder, path)) for path in PACKAGE_PATH.findall(text)]
    return seen


def touches(changed, folder):
    """A file inside the folder, or a submodule (gitlink) that contains the folder."""
    changed, folder = changed.lower().rstrip("/"), folder.lower().rstrip("/")
    return changed == folder or changed.startswith(folder + "/") or folder.startswith(changed + "/")


def affected(repo_root, packages, changed_files):
    """(packages to run, reason)."""
    tooling = [path for path in changed_files if path in TOOLING or path.startswith("scripts/fixtures/benchmark_report/")]
    if tooling:
        return packages, f"benchmark tooling changed: {tooling[0]}"
    selected = []
    for package in packages:
        folders = local_dependencies(repo_root, package)
        if any(touches(path, folder) for path in changed_files for folder in folders):
            selected.append(package)
    return selected, "affected packages" if selected else "no benchmark package is affected"


def changed_files(repo_root, base):
    output = subprocess.run(["git", "-C", repo_root, "diff", "--name-only", f"{base}...HEAD"],
                            capture_output=True, text=True, check=True).stdout
    return [line for line in output.splitlines() if line.strip()]


def simctl_json(*arguments):
    output = subprocess.run(["xcrun", "simctl", "list", *arguments, "--json"], capture_output=True, text=True, check=True).stdout
    return json.loads(output)


def pick_runtime(runtimes, version):
    """The available iOS runtime whose version is `version` or starts with `version.`.
    `version` needs at least major.minor: "26" alone would accept any iOS 26 release."""
    if "." not in version:
        return None
    for runtime in runtimes.get("runtimes", []):
        if runtime.get("platform", "iOS") != "iOS" or not runtime.get("isAvailable", False):
            continue
        if runtime.get("version") == version or runtime.get("version", "").startswith(version + "."):
            return runtime
    return None


def pick_device(devices, runtime_identifier, name):
    for device in devices.get("devices", {}).get(runtime_identifier, []):
        if device.get("name") == name and device.get("isAvailable", False):
            return device["udid"]
    return None


def simulator(name, version):
    runtimes = simctl_json("runtimes")
    runtime = pick_runtime(runtimes, version)
    if runtime is None:
        installed = ", ".join(sorted(r.get("version", "?") for r in runtimes.get("runtimes", []) if r.get("platform", "iOS") == "iOS"))
        sys.exit(f"No available iOS {version} simulator runtime. Installed iOS runtimes: {installed or 'none'}.")
    udid = pick_device(simctl_json("devices", "available"), runtime["identifier"], name)
    if udid is None:
        # The runtime is there but no device of that name: make one, so a fresh CI machine works.
        udid = subprocess.run(["xcrun", "simctl", "create", name, name, runtime["identifier"]],
                              capture_output=True, text=True, check=True).stdout.strip()
    return udid


def load_report_module():
    path = os.path.join(os.path.dirname(os.path.abspath(__file__)), "benchmark_report.py")
    spec = importlib.util.spec_from_file_location("benchmark_report", path)
    module = importlib.util.module_from_spec(spec)
    spec.loader.exec_module(module)
    return module


def main():
    parser = argparse.ArgumentParser()
    commands = parser.add_subparsers(dest="command", required=True)
    packages_command = commands.add_parser("packages")
    packages_command.add_argument("--repo-root", default=".")
    mode = packages_command.add_mutually_exclusive_group(required=True)
    mode.add_argument("--all", action="store_true")
    mode.add_argument("--base")
    packages_command.add_argument("--output")
    simulator_command = commands.add_parser("simulator")
    simulator_command.add_argument("--name", required=True)
    simulator_command.add_argument("--os", required=True)
    skipped_command = commands.add_parser("skipped")
    skipped_command.add_argument("file")
    args = parser.parse_args()

    if args.command == "packages":
        packages = find_opted_in(args.repo_root)
        if args.all:
            selected, reason = packages, "all opted-in packages"
        else:
            selected, reason = affected(args.repo_root, packages, changed_files(args.repo_root, args.base))
        print(f"{reason}: {', '.join(selected) or 'none'}", file=sys.stderr)
        text = "".join(package + "\n" for package in selected)
        if args.output:
            with open(args.output, "w") as handle:
                handle.write(text)
        else:
            sys.stdout.write(text)
    elif args.command == "simulator":
        print(simulator(args.name, args.os))
    else:
        try:
            skipped = load_report_module().read_skipped(args.file)
        except (OSError, ValueError) as error:
            sys.exit(f"Invalid skip list: {error}")
        sys.stdout.write("".join(test.strip("/") + "\n" for test in sorted(skipped)))


if __name__ == "__main__":
    main()
