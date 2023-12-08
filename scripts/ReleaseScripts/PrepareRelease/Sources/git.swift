import Foundation
import SharedReleaseScript

func createPrepareBranch(_ versionNumber: String) throws -> String {
    try checkIfGitIsInstalled()
    try checkoutToDevelopAndPull()
    let prepareBranch = "task/prepare-\(versionNumber)"
    try runInShell("git checkout -b \(prepareBranch)")
    return prepareBranch
}

func checkoutSubmoduleToCommit(submodule: Submodule, commitHash: String) throws {
    try runInShell("git submodule update --init -- \(submodule.path)")
    try runInShell("git checkout \(commitHash)", cwd: URL(fileURLWithPath: submodule.path))
}

func createReleaseCommitAndPushToOrigin(version: String, prepareBranch: String) throws {
    try runInShell("git add .")
    try runInShell("git commit -m \"Prepare v\(version)\"")
    try runInShell("git push --set-upstream origin \(prepareBranch)")
}

 func checkIfGitIsInstalled() throws {
    try runInShell("git --version")
}

private func checkoutToDevelopAndPull() throws {
    try runInShell("git checkout develop")
    try runInShell("git pull")
}
