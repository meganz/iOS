import Foundation
import MEGADomain
import MEGAPickerFileProviderDomain

/// Records each upload, reports `sentBytes` as its progress and returns `uploadedFile`. Every file has
/// `fileFingerprint`.
actor MockFileProviderUploadRepository: FileProviderUploadRepositoryProtocol {
    struct Upload: Equatable {
        let url: URL
        let name: String
        let parent: String
        let modificationDate: Date?
    }

    static var newRepo: MockFileProviderUploadRepository { MockFileProviderUploadRepository() }

    private let uploadedFile: NodeEntity
    private let sentBytes: [Int]
    private let error: (any Error)?
    private let fileFingerprint: String?
    private(set) var uploads: [Upload] = []

    /// - Parameter error: What every upload throws, when set.
    init(uploadedFile: NodeEntity = NodeEntity(), sentBytes: [Int] = [], error: (any Error)? = nil, fileFingerprint: String? = nil) {
        self.uploadedFile = uploadedFile
        self.sentBytes = sentBytes
        self.error = error
        self.fileFingerprint = fileFingerprint
    }

    nonisolated func fingerprint(ofFileAt url: URL, modificationDate: Date?) -> String? {
        fileFingerprint
    }

    func upload(
        fileAt url: URL,
        named name: String,
        to parent: NodeEntity,
        modificationDate: Date?,
        progress: @escaping @Sendable (Int) -> Void
    ) async throws -> NodeEntity {
        uploads.append(Upload(url: url, name: name, parent: parent.base64Handle, modificationDate: modificationDate))
        if let error {
            throw error
        }
        sentBytes.forEach(progress)
        return uploadedFile
    }
}
