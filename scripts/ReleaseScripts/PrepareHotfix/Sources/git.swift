import SharedReleaseScript

enum GitError: Error {
    case missingTag
    case couldNotCreateUpcomingHotfixPatchVersion
}

func createHotfixBranchFromTag(_ tag: String, hotfixVersion: String) throws -> String {
    let isTagInTagList = try isTagInTagList(tag)

    guard isTagInTagList else {
        print("No git tag was found matching the provided version \(tag)")
        throw GitError.missingTag
    }

    try runInShell("git checkout \(tag)")

    return try createHotfixBranchAndPushToOrigin(hotfixVersion)
}

func latestTag() throws -> String {
    try runInShell("git describe --tags $(git rev-list --tags --max-count=1)").trimmingCharacters(in: .whitespacesAndNewlines)
}

func upcomingHotfixPatchVersion() throws -> String {
    let latestTag = try latestTag()
    let components = latestTag.split(separator: ".")
    if components.count == 2 {
        return "\(latestTag).1"
    } else if components.count == 3, let patchVersion = Int(components[2]) {
        return "\(components[0]).\(components[1]).\(patchVersion + 1)"
    }

    throw GitError.couldNotCreateUpcomingHotfixPatchVersion
}

private func isTagInTagList(_ tag: String) throws -> Bool {
    try runInShell("git fetch --tags --force")
    let tagList = try runInShell("git tag")
    return tagList.contains(tag)
}

private func createHotfixBranchAndPushToOrigin(_ hotfixVersion: String) throws -> String {
    let branchName = "release/\(hotfixVersion)"
    try runInShell("git checkout -b \(branchName)")
    try updateAndCommitNewVersionNumber(hotfixVersion)
    return branchName
}

private func updateAndCommitNewVersionNumber(_ hotfixVersion: String) throws {
    try updateProjectVersion(hotfixVersion)
    try runInShell("git add \(pathToPBXProj)")
    try runInShell("git commit -m \"Bump to \(hotfixVersion)\"")
}
