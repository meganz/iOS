import Foundation

public enum SubmoduleReferenceType: Sendable {
    case tag(String)
    case branch(String)

    public func description(type: String, plainText: Bool = false) -> String {
        switch self {
        case .tag(let tag):
            plainText ? "\(type) Release: \(tag)" : "*\(type) Release:* `\(tag)`"
        case .branch(let branch):
            plainText ? "\(type) Branch: \(branch)" : "*\(type) Branch:* `\(branch)`"
        }
    }

    public func description(for submodule: Submodule, plainText: Bool = false) -> String {
        switch submodule {
        case .sdk:
            description(type: "SDK", plainText: plainText)
        case .chatSDK:
            description(type: "Chat SDK", plainText: plainText)
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
