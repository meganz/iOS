import SharedReleaseScript

func pushToPublicMaster(_ tag: String) throws {
    let sshRepository = "git@github.com:meganz/iOS.git"
    let httpsRepository = "https://github.com/meganz/iOS.git"
    let isPublicRepositoryInRemoteList = try isRepositoryInRemoteList(
        sshRepository: sshRepository,
        httpsRepository: httpsRepository
    )

    if !isPublicRepositoryInRemoteList {
        // Favor ssh as it doesn't require stdin interaction
        try runInShell("git remote add public \(sshRepository)")
    }

    try checkoutToMasterAndPull()
    // If it's your first time pushing to master, the shell will ask for you to recognize Github's authenticity
    try runInShell("git push public master", input: "yes")
    try runInShell("git push public \(tag)")
}

private func isRepositoryInRemoteList(sshRepository: String, httpsRepository: String) throws -> Bool {
    let remoteList = try runInShell("git remote -v")
    return remoteList.contains(sshRepository) || remoteList.contains(httpsRepository)
}
