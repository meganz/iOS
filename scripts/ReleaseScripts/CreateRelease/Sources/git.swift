import SharedReleaseScript

func createReleaseBranchAndPushToOrigin(version: String) throws -> String {
    try checkoutToDevelopAndPull()

    let branchName = "release/\(version)"

    try runInShell("git checkout -b \(branchName)")
    try runInShell("git push --set-upstream origin \(branchName)")

    return branchName
}

private func checkoutToDevelopAndPull() throws {
    try runInShell("git checkout develop")
    try runInShell("git pull")
}
