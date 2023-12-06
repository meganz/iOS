import SharedReleaseScript

enum GitError: Error {
    case missingTag
}

func createHotfixBranchFromTag(_ tag: String, hotfixVersion: String) throws {
    let isTagInTagList = try isTagInTagList(tag)

    guard isTagInTagList else {
        print("No git tag was found matching the provided version \(tag)")
        throw GitError.missingTag
    }

    try runInShell("git checkout \(tag)")

    try createHotfixBranchAndPushToOrigin(hotfixVersion)
}

private func isTagInTagList(_ tag: String) throws -> Bool {
    try runInShell("git fetch --tags --force")
    let tagList = try runInShell("git tag")
    return tagList.contains(tag)
}

private func createHotfixBranchAndPushToOrigin(_ hotfixVersion: String) throws {
    let branchName = "release/\(hotfixVersion)"
    try runInShell("git checkout -b \(branchName)")
    try updateAndCommitNewVersionNumber(hotfixVersion)
    try runInShell("git push --set-upstream origin \(branchName)")
}

private func updateAndCommitNewVersionNumber(_ hotfixVersion: String) throws {
    try updateProjectVersion(hotfixVersion)
    try runInShell("git add \(pathToPBXProj)")
    try runInShell("git commit -m \"Bump to \(hotfixVersion)\"")
}
