import SharedReleaseScript

func createTagAndPushToOrigin(version: String, message: String) throws {
    try runInShell("git tag -a \(version) -m \"\(message)\"")
    try runInShell("git push origin \(version)")
}

func checkoutToMasterAndPull() throws {
    try runInShell("git fetch origin")
    try runInShell("git checkout master")
    try runInShell("git pull")
}

func checkoutToReleaseAndPull(_ releaseBranch: String) throws {
    try runInShell("git checkout \(releaseBranch)")
    try runInShell("git pull")
}

func mergeMasterWithOursStrategyAndPushToOrigin() throws {
    try runInShell("git merge -s ours master")
    try runInShell("git push origin")
}

func pushToPublicMaster(_ tag: String) throws {
    let publicRepository = "git@github.com:meganz/iOS.git"
    let isPublicRepositoryInRemoteList = try isRepositoryInRemoteList(publicRepository)

    if !isPublicRepositoryInRemoteList {
        try runInShell("git remote add public \(publicRepository)")
    }

    try checkoutToMasterAndPull()
    // If it's your first time pushing to master, the shell will ask for you to recognize Github's authenticity
    try runInShell("git push public master", input: "yes")
    try runInShell("git push public \(tag)")
}

private func isRepositoryInRemoteList(_ repository: String) throws -> Bool {
    let remoteList = try runInShell("git remote -v")
    return remoteList.contains(repository)
}
