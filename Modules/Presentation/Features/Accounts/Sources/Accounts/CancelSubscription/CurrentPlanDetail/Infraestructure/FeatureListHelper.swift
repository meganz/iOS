import MEGADomain
import MEGAL10n

public enum FeatureType {
    case storage, transfer, passwordProtectedLinks, linksWithExpiryDate, transferSharing, rewind, vpn, callsAndMeetingsDuration, callsAndMeetingsParticipants
}

public protocol FeatureListHelperProtocol {
    func createCurrentFeatures() -> [FeatureDetails]
}

struct FeatureListHelper: FeatureListHelperProtocol {
    let account: AccountDetailsEntity
    let assets: CurrentPlanDetailAssets
    
    func createCurrentFeatures() -> [FeatureDetails] {
        [
            FeatureDetails(
                type: .storage,
                title: Strings.Localizable.storage,
                freeText: Strings.Localizable.Storage.Limit.capacity(20),
                proText: String.memoryStyleString(fromByteCount: account.storageMax)
            ),
            FeatureDetails(
                type: .transfer,
                title: Strings.Localizable.transfer,
                freeText: Strings.Localizable.Limited.Feature.message,
                proText: String.memoryStyleString(fromByteCount: account.transferMax)
            ),
            FeatureDetails(
                type: .passwordProtectedLinks,
                title: Strings.Localizable.Password.Protected.Links.title,
                freeIconName: assets.unavailableImageName,
                proIconName: assets.availableImageName
            ),
            FeatureDetails(
                type: .linksWithExpiryDate,
                title: Strings.Localizable.Links.With.Expiry.Dates.title,
                freeIconName: assets.unavailableImageName,
                proIconName: assets.availableImageName
            ),
            FeatureDetails(
                type: .transferSharing,
                title: Strings.Localizable.Transfer.Sharing.title,
                freeIconName: assets.unavailableImageName,
                proIconName: assets.availableImageName
            ),
            FeatureDetails(
                type: .rewind,
                title: Strings.Localizable.Rewind.Feature.title,
                freeText: Strings.Localizable.Rewind.For.Free.users,
                proText: Strings.Localizable.Rewind.For.Pro.users
            ),
            FeatureDetails(
                type: .vpn,
                title: Strings.Localizable.Mega.Vpn.title,
                freeIconName: assets.unavailableImageName,
                proIconName: assets.availableImageName
            ),
            FeatureDetails(
                type: .callsAndMeetingsDuration,
                title: Strings.Localizable.Call.And.Meeting.Duration.title,
                freeText: Strings.Localizable.Call.And.Meeting.Duration.For.Free.users,
                proText: Strings.Localizable.Call.And.Meeting.Duration.For.Pro.users
            ),
            FeatureDetails(
                type: .callsAndMeetingsParticipants,
                title: Strings.Localizable.Call.And.Meeting.Participants.title,
                freeText: Strings.Localizable.Call.And.Meeting.Participants.For.Free.users,
                proText: Strings.Localizable.Unlimited.Feature.message
            )
        ]
    }
}
