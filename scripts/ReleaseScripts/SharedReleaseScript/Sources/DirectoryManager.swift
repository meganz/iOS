import Foundation

public struct DirectoryManager {
    public enum DirectoryManagerError: Error {
        case failedToChangeDirectory
        case noXcodeprojFileFound
    }

    private let fileManager: FileManager

    public var currentDirectoryPath: String { fileManager.currentDirectoryPath }

    public init(fileManager: FileManager = .default) {
        self.fileManager = fileManager
    }

    public func change(to directory: String) throws {
        guard fileManager.changeCurrentDirectoryPath(directory) else {
            throw DirectoryManagerError.failedToChangeDirectory
        }
    }

    public func projectFileDirectory() throws -> String {
        var currentDirectory = URL(fileURLWithPath: fileManager.currentDirectoryPath)
        var xcodeprojFound = false

        while !xcodeprojFound {
            if try fileManager
                .contentsOfDirectory(atPath: currentDirectory.path)
                .lazy
                .contains(where: { $0.hasSuffix(".xcodeproj") }) {
                xcodeprojFound = true
            } else if currentDirectory.path == "/" {
                throw DirectoryManagerError.noXcodeprojFileFound
            } else {
                currentDirectory = currentDirectory.deletingLastPathComponent()
            }
        }

        return currentDirectory.path
    }
}
