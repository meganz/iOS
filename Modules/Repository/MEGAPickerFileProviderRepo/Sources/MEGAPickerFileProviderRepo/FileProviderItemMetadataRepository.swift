import FileProvider
import Foundation
import MEGAAppSDKRepo
import MEGAPickerFileProviderDomain

public struct FileProviderItemMetadataRepository: FileProviderItemMetadataRepositoryProtocol {
    public static var newRepo: FileProviderItemMetadataRepository {
        FileProviderItemMetadataRepository()
    }

    private static let encoder = JSONEncoder()
    private static let decoder = JSONDecoder()

    private let appContainer = AppGroupContainer(fileManager: .default)
    private let storageDirectoryURL: URL

    public init(storageDirectoryURL: URL? = nil) {
        if let storageDirectoryURL {
            self.storageDirectoryURL = storageDirectoryURL
        } else {
            self.storageDirectoryURL = appContainer.url(for: .fileExtension)
        }
    }

    public func favoriteRank(for identifier: NSFileProviderItemIdentifier) -> NSNumber? {
        guard let metadata = retrieveMetadata(for: identifier), let favoriteRank = metadata.favoriteRank else {
            return nil
        }

        return NSNumber(value: favoriteRank)
    }

    public func setFavoriteRank(for identifier: NSFileProviderItemIdentifier, with rank: NSNumber?) {
        var metadata = retrieveMetadata(for: identifier) ?? FileProviderItemMetadata()
        metadata.favoriteRank = rank?.int64Value
        saveMetadata(metadata, for: identifier)
    }

    public func tagData(for identifier: NSFileProviderItemIdentifier) -> Data? {
        retrieveMetadata(for: identifier)?.tagData
    }

    public func setTagData(for identifier: NSFileProviderItemIdentifier, with data: Data?) {
        var metadata = retrieveMetadata(for: identifier) ?? FileProviderItemMetadata()
        metadata.tagData = data
        saveMetadata(metadata, for: identifier)
    }

    private func fileURL(for identifier: NSFileProviderItemIdentifier) -> URL {
        storageDirectoryURL.appendingPathComponent("\(identifier.rawValue).json")
    }

    private func retrieveMetadata(for identifier: NSFileProviderItemIdentifier) -> FileProviderItemMetadata? {
        let url = fileURL(for: identifier)

        guard let data = try? Data(contentsOf: url) else {
            return nil
        }

        return try? Self.decoder.decode(FileProviderItemMetadata.self, from: data)
    }

    private func saveMetadata(_ metadata: FileProviderItemMetadata, for identifier: NSFileProviderItemIdentifier) {
        let url = fileURL(for: identifier)

        guard let data = try? Self.encoder.encode(metadata) else {
            return
        }

        try? data.write(to: url)
    }
}
