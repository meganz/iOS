import Foundation

public enum FileSystemError: Error {
    case cannotChangeToRootDirectory
}

public func changeCurrentWorkDirectoryToRootDirectory() throws {
    let rootDirectoryPath = "../../../"
    let fileManager = FileManager.default

    guard fileManager.changeCurrentDirectoryPath(rootDirectoryPath) else {
        throw FileSystemError.cannotChangeToRootDirectory
    }
}
