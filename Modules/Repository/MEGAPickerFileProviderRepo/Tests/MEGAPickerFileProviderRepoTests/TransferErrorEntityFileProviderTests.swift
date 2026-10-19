import FileProvider
import MEGADomain
@testable import MEGAPickerFileProviderRepo
import Testing

struct TransferErrorEntityFileProviderTests {
    @Test
    func toFileProviderError_whenCancelledForBeingOverQuota_isOverQuota() {
        let error = TransferErrorEntity.cancelled.toFileProviderError(isOverQuota: true, isBusinessExpired: true)

        #expect(error as? TransferErrorEntity == .overquota)
    }

    @Test
    func toFileProviderError_whenCancelledOtherwise_staysCancelled() {
        let error = TransferErrorEntity.cancelled.toFileProviderError(isOverQuota: false, isBusinessExpired: true)

        #expect(error as? TransferErrorEntity == .cancelled)
    }

    @Test(arguments: [TransferErrorEntity.upload, .download, .generic])
    func toFileProviderError_forAnExpiredBusinessAccount_cannotSynchronize(transferError: TransferErrorEntity) {
        let error = transferError.toFileProviderError(isOverQuota: false, isBusinessExpired: true)

        #expect((error as? NSFileProviderError)?.code == .cannotSynchronize)
    }

    @Test(arguments: [TransferErrorEntity.upload, .download, .overquota])
    func toFileProviderError_otherwise_staysTheTransferError(transferError: TransferErrorEntity) {
        let error = transferError.toFileProviderError(isOverQuota: false, isBusinessExpired: false)

        #expect(error as? TransferErrorEntity == transferError)
    }
}
