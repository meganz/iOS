import SharedReleaseScript

func createReleaseBranch(with version: String) throws -> String {
    try checkoutToDevelopAndPull()

    let branchName = "release/\(version)"

    try runInShell("git checkout -b \(branchName)")

    return branchName
}

private func checkoutToDevelopAndPull() throws {
    try runInShell("git checkout develop")
    try runInShell("git pull")
}
