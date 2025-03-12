public func checkoutToMasterAndPull() throws {
    try runInShell("git fetch origin")
    try runInShell("git checkout master")
    try runInShell("git submodule update --init --recursive")
    try runInShell("git pull")
}

public func checkoutToReleaseAndPull(_ releaseBranch: String) throws {
    try runInShell("git checkout \(releaseBranch)")
    try pullLatestChanges()
}

public func pullLatestChanges() throws {
    try runInShell("git submodule update --init --recursive")
    try runInShell("git pull")
}
