import MEGAAppSDKRepo
import MEGAAppSDKRepoMock
import MEGADomain
import MEGASdk
import Testing

@Suite("Transfer error mapping")
struct TransferErrorMappingTests {

    @Test func failedTransfer_keepsTheFullErrorTypeAndTheSDKErrorString() {
        let transfer = MockTransfer(type: .download, lastErrorExtended: MockError(errorType: .apiENoent))

        let entity = transfer.toTransferEntity()

        #expect(entity.lastErrorType == .resourceNotExists)
        #expect(entity.lastErrorString == "Not found")
        #expect(entity.lastErrorExtended == .generic)
    }

    @Test func overquotaTransfer_keepsBothErrorRepresentations() {
        let transfer = MockTransfer(lastErrorExtended: MockError(errorType: .apiEOverQuota))

        let entity = transfer.toTransferEntity()

        #expect(entity.lastErrorType == .quotaExceeded)
        #expect(entity.lastErrorExtended == .overquota)
    }

    @Test func errorString_dependsOnTheTransferDirection() {
        let download = MockTransfer(type: .download, lastErrorExtended: MockError(errorType: .apiETooMany))
        let upload = MockTransfer(type: .upload, lastErrorExtended: MockError(errorType: .apiETooMany))

        #expect(download.toTransferEntity().lastErrorString == "Terms of Service breached")
        #expect(upload.toTransferEntity().lastErrorString == "Too many concurrent connections or transfers")
    }

    @Test func transferWithoutError_hasNoErrorTypeOrString() {
        let entity = MockTransfer(lastErrorExtended: MockError(errorType: .apiOk)).toTransferEntity()

        #expect(entity.lastErrorType == nil)
        #expect(entity.lastErrorString == nil)
    }
}
