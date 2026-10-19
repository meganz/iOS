import Foundation
import MEGADomain

public protocol FileProviderDownloadRepositoryProtocol: RepositoryProtocol, Sendable {
    /// Downloads the file `node` to `url`. Cancelling the calling task cancels the transfer.
    /// - Parameter progress: Called with how many bytes have arrived so far.
    /// - Throws: `NSFileProviderError(.cannotSynchronize)` while the account is an expired business account.
    func download(node: NodeEntity, to url: URL, progress: @escaping @Sendable (Int) -> Void) async throws
}
