import Foundation

public enum FileSystemError: Error {
    case cannotChangeToDirectory(directory: AvailableDirectories, path: String)
}

private let fileManager = FileManager.default

public enum AvailableDirectories {
    case root
    case currentScriptDirectory

    var isInRootDirectory: Bool {
        if case .root = self {
            return true
        } else {
            return false
        }
    }
}

private var currentDirectory: AvailableDirectories = .currentScriptDirectory

public func changeCurrentWorkDirectoryToRootDirectory() throws {
    guard !currentDirectory.isInRootDirectory else { return }
    let rootDirectoryPath = "../../../"
    try changeDirectory(path: rootDirectoryPath, directory: .root)
}

private func changeDirectory(path: String, directory: AvailableDirectories) throws {
    guard fileManager.changeCurrentDirectoryPath(path) else {
        throw FileSystemError.cannotChangeToDirectory(directory: directory, path: path)
    }

    currentDirectory = directory
}
