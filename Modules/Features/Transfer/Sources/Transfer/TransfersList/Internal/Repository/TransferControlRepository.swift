import MEGAAppSDKRepo
import MEGADomain
import MEGASdk
import MEGASwift

package protocol TransferControlRepositoryProtocol: RepositoryProtocol, Sendable {
    /// Pauses a single in-flight transfer in the transfer engine.
    func pauseTransfer(_ transfer: TransferEntity) async throws
    /// Resumes a single paused transfer in the transfer engine.
    func resumeTransfer(_ transfer: TransferEntity) async throws
}

package struct TransferControlRepository: TransferControlRepositoryProtocol {
    package static var newRepo: TransferControlRepository {
        TransferControlRepository(sdk: MEGASdk.sharedSdk)
    }

    private let sdk: MEGASdk

    package init(sdk: MEGASdk) {
        self.sdk = sdk
    }

    package func pauseTransfer(_ transfer: TransferEntity) async throws {
        try await setTransfer(transfer, paused: true)
    }

    package func resumeTransfer(_ transfer: TransferEntity) async throws {
        try await setTransfer(transfer, paused: false)
    }

    /// Pause and resume share a single SDK entry point (`pauseTransferByTag:pause:`),
    /// addressing the transfer by its tag since the engine is keyed by tag, not handle.
    private func setTransfer(_ transfer: TransferEntity, paused: Bool) async throws {
        try await withAsyncThrowingValue { completion in
            sdk.pauseTransfer(byTag: transfer.tag, pause: paused, delegate: RequestDelegate { result in
                switch result {
                case .success:
                    completion(.success)
                case .failure(let error):
                    completion(.failure(error))
                }
            })
        }
    }
}
