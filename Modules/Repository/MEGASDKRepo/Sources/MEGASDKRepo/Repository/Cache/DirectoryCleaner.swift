import Foundation

public protocol DirectoryCleaningProtocol: Sendable {
    func removeFolderContents(
        at url: URL,
        containing substring: String?,
        recursive: Bool,
        withExtension fileExtension: String?
    ) throws
    
    func removeFolderContentsRecursively(
        at url: URL,
        containing substring: String?,
        withExtension fileExtension: String?
    ) throws
    
    func removeItemAtURL(_ url: URL?) throws
}

extension DirectoryCleaningProtocol {
    func removeFolderContents(
        at url: URL
    ) throws {
        try removeFolderContents(
            at: url,
            containing: nil,
            recursive: false,
            withExtension: nil
        )
    }
    
    func removeFolderContentsRecursively(
        at url: URL,
        withExtension fileExtension: String?
    ) throws {
        try removeFolderContentsRecursively(
            at: url,
            containing: nil,
            withExtension: fileExtension
        )
    }
}

public struct DirectoryCleaner: DirectoryCleaningProtocol {
    private let fileManager: FileManager
    
    public init(fileManager: FileManager = .default) {
        self.fileManager = fileManager
    }
    
    public func removeFolderContents(
        at url: URL,
        containing substring: String? = nil,
        recursive: Bool = true,
        withExtension fileExtension: String? = nil
    ) throws {
        guard let directoryContents = try? fileManager.contentsOfDirectory(
            at: url,
            includingPropertiesForKeys: [.isDirectoryKey],
            options: []
        ) else {
            return
        }
        
        for fileURL in directoryContents {
            let isDirectory = (try? fileURL.resourceValues(forKeys: [.isDirectoryKey]).isDirectory) == true
            if isDirectory, recursive {
                try removeFolderContents(
                    at: fileURL,
                    containing: substring,
                    recursive: true,
                    withExtension: fileExtension
                )
            } else {
                if matchesCriteria(
                    fileURL,
                    substring: substring,
                    fileExtension: fileExtension
                ) {
                    try removeItemAtURL(fileURL)
                }
            }
        }
    }
    
    public func removeFolderContentsRecursively(
        at url: URL,
        containing substring: String? = nil,
        withExtension fileExtension: String? = nil
    ) throws {
        guard let directoryContents = try? fileManager.contentsOfDirectory(
            at: url,
            includingPropertiesForKeys: [.isDirectoryKey],
            options: []
        ) else {
            return
        }
        
        for fileURL in directoryContents {
            let isDirectory = (try? fileURL.resourceValues(forKeys: [.isDirectoryKey]).isDirectory) == true
            if isDirectory {
                try removeFolderContentsRecursively(
                    at: fileURL,
                    containing: substring,
                    withExtension: fileExtension
                )
            } else if matchesCriteria(
                fileURL,
                substring: substring,
                fileExtension: fileExtension
            ) {
                try removeItemAtURL(fileURL)
            }
        }
    }
    
    public func removeItemAtURL(_ url: URL?) throws {
        guard let url else { return }
        try fileManager.removeItem(at: url)
    }
    
    // MARK: - Helpers
    
    private func matchesCriteria(
        _ url: URL,
        substring: String?,
        fileExtension: String?
    ) -> Bool {
        let matchesSubstring = substring == nil ||
            url.lastPathComponent.lowercased().contains(substring?.lowercased() ?? "")
        let matchesExtension = fileExtension == nil ||
            url.pathExtension.lowercased() == fileExtension?.lowercased()
        return matchesSubstring && matchesExtension
    }
}
