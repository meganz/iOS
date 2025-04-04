import Foundation

public protocol DirectoryProvidingProtocol: Sendable {
    func urlForSharedSandboxCacheDirectory(_ directory: String) throws -> URL
    func pathForOffline() -> URL?
    func downloadsDirectory() throws -> URL
    func uploadsDirectory() throws -> URL
    func groupSharedURL() -> URL?
}

public struct DirectoryProvider: DirectoryProvidingProtocol {
    private let fileManager: FileManager
    
    public enum Path {
        static let libraryCaches = "Library/Caches"
        static let downloads = "Downloads"
        static let uploads = "Uploads"
    }
    
    public init(fileManager: FileManager = .default) {
        self.fileManager = fileManager
    }
    
    public func urlForSharedSandboxCacheDirectory(_ directory: String) throws -> URL {
        guard let containerURL = fileManager.containerURL(forSecurityApplicationGroupIdentifier: GroupSharedDirectory.identifier) else {
            fatalError("Unable to access the container URL for \(GroupSharedDirectory.identifier).")
        }
        
        let destinationURL = containerURL
            .appendingPathComponent(Path.libraryCaches, isDirectory: true)
            .appendingPathComponent(directory, isDirectory: true)
        
        try createFolderIfNeeded(at: destinationURL)
        return destinationURL
    }
    
    public func pathForOffline() -> URL? {
        fileManager.urls(
            for: .documentDirectory,
            in: .userDomainMask
        ).first
    }
    
    private func applicationSupportDirectory() -> URL {
        guard let applicationSupportDirectory = fileManager
            .urls(for: .applicationSupportDirectory, in: .userDomainMask)
            .first
        else {
            fatalError("Failed to retrieve application support directory.")
        }

        return applicationSupportDirectory
    }

    public func downloadsDirectory() throws -> URL {
        let directory = applicationSupportDirectory()
            .appendingPathComponent(Path.downloads)
        try createFolderIfNeeded(at: directory)
        return directory
    }

    public func uploadsDirectory() throws -> URL {
        let directory = applicationSupportDirectory()
            .appendingPathComponent(Path.uploads)
        try createFolderIfNeeded(at: directory)
        return directory
    }
    
    public func groupSharedURL() -> URL? {
        fileManager.containerURL(
            forSecurityApplicationGroupIdentifier: GroupSharedDirectory.identifier
        )
    }
    
    // MARK: - Helpers
    private func createFolderIfNeeded(at url: URL) throws {
        if !fileManager.fileExists(atPath: url.path) {
            try fileManager.createDirectory(
                at: url,
                withIntermediateDirectories: true,
                attributes: nil
            )
        }
    }
}
