import Foundation

public func branchNameForSubmodule(with path: String) throws -> String {
    let directoryManager = DirectoryManager()
    let originalDirectory = directoryManager.currentDirectoryPath
    let projectRootDirectoryURL = try directoryManager.projectFileDirectory()

    try directoryManager.change(to: projectRootDirectoryURL + "/" + path)
    try runInShell("git fetch --all")
    let branchName = try runInShell("git branch -a --contains | grep '/release/' | sed -E 's/^[ \t]*//; s#remotes/origin/##'")
    try directoryManager.change(to: originalDirectory)

    return branchName.components(separatedBy: .newlines).joined()
}
