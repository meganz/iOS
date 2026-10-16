import Foundation
import MEGADomain

public protocol FileProviderUploadRepositoryProtocol: RepositoryProtocol, Sendable {
    /// Uploads the file at `url` into `parent` as `name`, leaving the file in place. A file of that name already in
    /// `parent` gets the upload as its new version, unless it has the same contents, in which case it is returned as
    /// is. Cancelling the calling task cancels the transfer.
    /// - Parameters:
    ///   - modificationDate: The modification date the node gets; `nil` keeps the file's own.
    ///   - progress: Called with how many bytes have been sent so far.
    /// - Returns: The uploaded node.
    func upload(
        fileAt url: URL,
        named name: String,
        to parent: NodeEntity,
        modificationDate: Date?,
        progress: @escaping @Sendable (Int) -> Void
    ) async throws -> NodeEntity

    /// The fingerprint a node uploaded from the file at `url` with `modificationDate` has, which `upload` compares
    /// to tell a file of the same contents.
    func fingerprint(ofFileAt url: URL, modificationDate: Date?) -> String?
}
