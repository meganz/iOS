import Foundation

public enum SubmoduleReferenceType: Sendable {
    case tag(String)
    case branch(String)

    public func description(type: String) -> String {
        switch self {
        case .tag(let tag):
            "*\(type) release:* `\(tag)`"
        case .branch(let branch):
            "*\(type) Branch:* `\(branch)`"
        }
    }
}

public func tagOrBranchNameForSubmodule(with path: String) throws -> SubmoduleReferenceType {
    let directoryManager = DirectoryManager()
    let originalDirectory = directoryManager.currentDirectoryPath
    let projectRootDirectoryURL = try directoryManager.projectFileDirectory()

    try directoryManager.change(to: projectRootDirectoryURL + "/" + path)
    try runInShell("git fetch --all")
    do {
        let tag = try runInShell("git describe --exact-match --tags")
        try directoryManager.change(to: originalDirectory)
        return .tag(tag.components(separatedBy: .newlines).joined())
    } catch {
        let command = "git branch -a --contains | grep '/release/' | sed -E 's/^[ \t]*//; s#remotes/origin/##' | sort -V | head -n 1"
        let branchName = try runInShell(command)
        try directoryManager.change(to: originalDirectory)
        return .branch(branchName.components(separatedBy: .newlines).joined())
    }
}
