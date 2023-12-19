import SharedReleaseScript

func createTagAndPushToOrigin(version: String, message: String) throws {
    try runInShell("git tag -a \(version) -m \"\(message)\"")
    try runInShell("git push origin \(version)")
}

func mergeMasterWithOursStrategyAndPushToOrigin() throws {
    try runInShell("git merge -s ours master")
    try runInShell("git push origin")
}
