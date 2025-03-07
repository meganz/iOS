import Foundation

public struct VersionFetcher {
    enum GetVersionError: Error {
        case noXcodeprojFileFound
        case failedToChangeDirectory
        case failedToReadVersionNumberFromFile
        case failedToRemoveVersionNumberFile
        case versionFileDoesNotExists
        case currentVersionReadIsNotInCorrectFormat
        case buildNumberFileDoesNotExists
        case failedToReadBuildNumberFromFile
        case failedToRemoveBuildNumberFile
    }

    private let fileManager: FileManager = .default

    public init() {}

    // MARK: - Interface methods.

    public func fetchVersion() throws -> String {
        try fetch {
            try fetchVersionUsingFastlane()
        }
    }

    public func nextVersion(from currentVersion: String? = nil) throws -> String {
        let currentVersion = if let currentVersion { currentVersion } else { try fetchVersion() }
        let components = currentVersion.split(separator: ".").map { Int($0) }

        guard components.count == 2, let major = components[0], let minor = components[1] else {
            throw GetVersionError.currentVersionReadIsNotInCorrectFormat
        }

        return "\(major).\(minor + 1)"
    }

    public func fetchLatestBuildNumber(for version: String) throws -> String {
        try fetch {
            try fetchLatestBuildNumberUsingFastlane(for: version)
        }
    }

    // MARK: - Private methods

    private func fetch(fastlaneBlock block: () throws -> String) throws -> String {
        let directoryManager = DirectoryManager(fileManager: fileManager)
        let originalDirectory = fileManager.currentDirectoryPath
        let projectFileDirectory = try directoryManager.projectFileDirectory()

        try directoryManager.change(to: projectFileDirectory)
        let result = try block()
        try directoryManager.change(to: originalDirectory)

        return result
    }

    private func fetchVersionUsingFastlane() throws -> String {
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

    private func fetchLatestBuildNumberUsingFastlane(for version: String) throws -> String {
        let outputFile = "read_build_number.txt"
        try runInShell("bundle exec fastlane fetch_latest_build_number output_file:\"\(outputFile)\" version:\"\(version)\"")
        let buildNumberFileURL = URL(fileURLWithPath: "fastlane/" + outputFile, relativeTo: URL(fileURLWithPath: fileManager.currentDirectoryPath))

        if fileManager.fileExists(atPath: buildNumberFileURL.path) {
            let buildNumber: String
            do {
                buildNumber = try String(contentsOf: buildNumberFileURL).trimmingCharacters(in: .whitespacesAndNewlines)
            } catch {
                throw GetVersionError.failedToReadBuildNumberFromFile
            }

            do {
                try fileManager.removeItem(at: buildNumberFileURL)
            } catch {
                throw GetVersionError.failedToRemoveBuildNumberFile
            }

            return buildNumber
        } else {
            throw GetVersionError.buildNumberFileDoesNotExists
        }
    }
}
