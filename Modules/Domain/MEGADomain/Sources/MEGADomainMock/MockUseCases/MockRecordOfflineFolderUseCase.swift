import Foundation
import MEGADomain
import MEGASwift

@MainActor
public final class MockRecordOfflineFolderUseCase: RecordOfflineFolderUseCaseProtocol {
    /// Every list of transfers `recordFolders(in:)` was called with, in call order.
    public private(set) var recordedBatches = [[CancellableTransferEntity]]()

    public init() { }

    public func recordFolders(in transfers: [CancellableTransferEntity]) {
        recordedBatches.append(transfers)
    }
}
