import Foundation
import MEGADomain
import Testing
@testable import Transfer

@Suite("TransferRetryPolicy")
struct TransferRetryPolicyTests {

    @Test(
        "Only terminal transfers (failed or cancelled) are retryable",
        arguments: [
            (TransferStateEntity.failed, true),
            (.cancelled, true),
            (.queued, false),
            (.active, false),
            (.paused, false),
            (.complete, false)
        ]
    )
    func onlyTerminalStatesAreRetryable(state: TransferStateEntity, expected: Bool) {
        let entity = TransferEntity(type: .download, state: state)

        #expect(TransferRetryPolicy.isRetryable(entity, sourceExists: { _ in true }) == expected)
    }

    @Test("A failed download stays retryable even without a local source")
    func failedDownloadIgnoresSourceAvailability() {
        let entity = TransferEntity(type: .download, path: nil, state: .failed)

        #expect(TransferRetryPolicy.isRetryable(entity, sourceExists: { _ in false }))
    }

    @Test("A failed upload is retryable only while its staged source file exists")
    func failedUploadRetryabilityFollowsSourceOnDisk() {
        let entity = TransferEntity(type: .upload, path: "/tmp/staged.jpg", state: .failed)

        #expect(TransferRetryPolicy.isRetryable(entity, sourceExists: { _ in true }))
        #expect(!TransferRetryPolicy.isRetryable(entity, sourceExists: { _ in false }))
    }

    @Test("A cancelled upload follows the same source-on-disk rule as a failed one")
    func cancelledUploadFollowsSameRule() {
        let entity = TransferEntity(type: .upload, path: "/tmp/staged.jpg", state: .cancelled)

        #expect(TransferRetryPolicy.isRetryable(entity, sourceExists: { _ in true }))
        #expect(!TransferRetryPolicy.isRetryable(entity, sourceExists: { _ in false }))
    }

    @Test("An upload without a usable source path is never retryable")
    func uploadWithoutPathIsNotRetryable() {
        #expect(!TransferRetryPolicy.isRetryable(
            TransferEntity(type: .upload, path: nil, state: .failed),
            sourceExists: { _ in true }
        ))
        #expect(!TransferRetryPolicy.isRetryable(
            TransferEntity(type: .upload, path: "", state: .failed),
            sourceExists: { _ in true }
        ))
    }

    @Test("The disk check is not consulted for non-terminal or download transfers")
    func sourceExistsIsOnlyConsultedForTerminalUploads() {
        var consulted = false
        let probe: (String) -> Bool = { _ in consulted = true; return true }

        _ = TransferRetryPolicy.isRetryable(TransferEntity(type: .download, path: "/x", state: .failed), sourceExists: probe)
        _ = TransferRetryPolicy.isRetryable(TransferEntity(type: .upload, path: "/x", state: .active), sourceExists: probe)
        #expect(!consulted)

        _ = TransferRetryPolicy.isRetryable(TransferEntity(type: .upload, path: "/x", state: .failed), sourceExists: probe)
        #expect(consulted)
    }
}
