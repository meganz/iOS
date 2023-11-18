import Foundation
import SharedReleaseScript

func createPrepareBranch(_ versionNumber: String) throws {
    try checkIfGitIsInstalled()
    try checkoutToDevelopAndPull()
    try runInShell("git checkout -b task/prepare-\(versionNumber)")
}

func checkoutSubmoduleToCommit(submodule: Submodule, commitHash: String) throws {
    try runInShell("git submodule update --init -- \(submodule.path)")
    try runInShell("git checkout \(commitHash)", cwd: URL(fileURLWithPath: submodule.path))
}

func createReleaseCommitAndPushToOrigin(_ versionNumber: String) throws {
    try runInShell("git add .")
    try runInShell("git commit -m \"Prepare v\(versionNumber)\"")
    try runInShell("git push --set-upstream origin task/prepare-\(versionNumber)")
}

 func checkIfGitIsInstalled() throws {
    try runInShell("git --version")
}

private func checkoutToDevelopAndPull() throws {
    try runInShell("git checkout develop")
    try runInShell("git pull")
}
