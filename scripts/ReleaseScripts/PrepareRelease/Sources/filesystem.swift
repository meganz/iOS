import Foundation

enum FileSystemError: Error {
    case cannotChangeToRootDirectory
}

func changeCurrentWorkDirectoryToRootDirectory() throws {
    let rootDirectoryPath = "../../../"
    let fileManager = FileManager.default

    guard fileManager.changeCurrentDirectoryPath(rootDirectoryPath) else {
        throw FileSystemError.cannotChangeToRootDirectory
    }
}
