import MEGADomain
import MEGAL10n
import Testing
@testable import Transfer

@Suite("TransferFailureReason")
struct TransferFailureReasonTests {

    private func reason(
        errorType: ErrorTypeEntity? = nil,
        errorString: String? = nil,
        direction: TransferRowState.Direction = .download,
        isForeignOverquota: Bool = false
    ) -> String? {
        TransferFailureReason.localizedReason(
            errorType: errorType,
            errorString: errorString,
            direction: direction,
            isForeignOverquota: isForeignOverquota
        )
    }

    @Test func noError_hasNoReason() {
        #expect(reason() == nil)
    }

    @Test func foreignOverquota_winsOverTheError() {
        #expect(
            reason(errorType: .quotaExceeded, errorString: "Over quota", direction: .upload, isForeignOverquota: true)
            == Strings.Localizable.Transfer.Cell.ShareOwnerStorageQuota.infoLabel
        )
    }

    @Test func blockedDownload_isTermsOfServiceViolation() {
        #expect(
            reason(errorType: .resourceAdministrativelyBlocked, errorString: "File removed as it violated our Terms of Service", direction: .download)
            == Strings.Localizable.Transfer.Error.termsOfServiceViolation
        )
    }

    @Test func blockedUpload_usesTheSDKErrorString() {
        #expect(
            reason(errorType: .resourceAdministrativelyBlocked, errorString: "Blocked", direction: .upload)
            == Strings.Localizable.blocked
        )
    }

    @Test func otherErrors_localizeTheSDKErrorString() {
        #expect(reason(errorType: .resourceNotExists, errorString: "Not found") == Strings.Localizable.notFound)
        #expect(reason(errorType: .accessDenied, errorString: "Access denied", direction: .upload) == Strings.Localizable.accessDenied)
    }

    @Test func errorStringWithoutATranslation_isShownAsIs() {
        #expect(reason(errorString: "Insufficient disk space") == "Insufficient disk space")
    }
}
