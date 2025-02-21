import Foundation
import SharedReleaseScript

struct VersionFetcher {
    enum GetVersionError: Error {
        case noXcodeprojFileFound
        case failedToChangeDirectory
        case failedToReadVersionNumberFromFile
        case failedToRemoveVersionNumberFile
        case versionFileDoesNotExists
    }

    private let fileManager: FileManager = .default

    // MARK: - Interface methods.

    func fetchVersion() throws -> String {
        let originalDirectory = fileManager.currentDirectoryPath
        let projectFileDirectory = try projectFileDirectory()

        try change(to: projectFileDirectory)
        let version = try fetchVersionFile()
        try change(to: originalDirectory)

        return version
    }

    // MARK: - Private methods

    private func projectFileDirectory() throws -> String {
        var currentDirectory = URL(fileURLWithPath: fileManager.currentDirectoryPath)
        var xcodeprojFound = false

        while !xcodeprojFound {
            let contents = try fileManager.contentsOfDirectory(atPath: currentDirectory.path)
            if contents.contains(where: { $0.hasSuffix(".xcodeproj") }) {
                xcodeprojFound = true
            } else if currentDirectory.path == "/" {
                throw GetVersionError.noXcodeprojFileFound
            } else {
                currentDirectory = currentDirectory.deletingLastPathComponent()
            }
        }

        return currentDirectory.path
    }

    private func change(to directory: String) throws {
        print("Changing to directory: \(directory)")
        guard fileManager.changeCurrentDirectoryPath(directory) else {
            throw GetVersionError.failedToChangeDirectory
        }
    }

    private func fetchVersionFile() throws -> String {
        let outputFile = "read_version_number.txt"
        try runInShell("bundle exec fastlane fetch_version_number output_file:\"\(outputFile)\"")

        let versionFileURL = URL(fileURLWithPath: "fastlane/" + outputFile, relativeTo: URL(fileURLWithPath: fileManager.currentDirectoryPath))

        if fileManager.fileExists(atPath: versionFileURL.path) {
            let version: String
            do {
                version = try String(contentsOf: versionFileURL).trimmingCharacters(in: .whitespacesAndNewlines)
            } catch {
                throw GetVersionError.failedToReadVersionNumberFromFile
            }

            do {
                try fileManager.removeItem(at: versionFileURL)
            } catch {
                throw GetVersionError.failedToRemoveVersionNumberFile
            }

            return version
        } else {
            throw GetVersionError.versionFileDoesNotExists
        }
    }
}
