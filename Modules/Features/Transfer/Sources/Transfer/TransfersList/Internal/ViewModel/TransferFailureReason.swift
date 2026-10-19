import MEGADomain
import MEGAL10n

/// Localized reason shown after "Failed:" on a Failed-tab row.
enum TransferFailureReason {
    static func localizedReason(
        errorType: ErrorTypeEntity?,
        errorString: String?,
        direction: TransferRowState.Direction,
        isForeignOverquota: Bool
    ) -> String? {
        if isForeignOverquota {
            return Strings.Localizable.Transfer.Cell.ShareOwnerStorageQuota.infoLabel
        }
        if errorType == .resourceAdministrativelyBlocked && direction != .upload {
            return Strings.Localizable.Transfer.Error.termsOfServiceViolation
        }
        return errorString.map { Strings.localized($0, comment: "") }
    }
}
