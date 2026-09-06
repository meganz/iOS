import Foundation

/// One root of a batch upload: what to upload, where it goes and how it is queued.
///
/// Handed to `UploadFileRepositoryProtocol.upload(batch:)`, which reports the whole selection as a
/// single transfer. Every item carries its own parent, so a batch may span several destinations.
public struct UploadBatchItemEntity: Sendable {
    public let localFileURL: URL
    public let parentHandle: HandleEntity
    public let isFile: Bool
    public let options: UploadOptionsEntity

    public init(
        localFileURL: URL,
        parentHandle: HandleEntity,
        isFile: Bool,
        options: UploadOptionsEntity
    ) {
        self.localFileURL = localFileURL
        self.parentHandle = parentHandle
        self.isFile = isFile
        self.options = options
    }
}
