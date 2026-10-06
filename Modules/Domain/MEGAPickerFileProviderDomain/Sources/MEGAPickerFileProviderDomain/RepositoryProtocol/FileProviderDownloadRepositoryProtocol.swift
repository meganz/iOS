import Foundation
import MEGADomain

public protocol FileProviderDownloadRepositoryProtocol: RepositoryProtocol, Sendable {
    /// Downloads the file `node` to `url`. Cancelling the calling task cancels the transfer.
    /// - Parameter progress: Called with how many bytes have arrived so far.
    func download(node: NodeEntity, to url: URL, progress: @escaping @Sendable (Int) -> Void) async throws
}
