import MEGADomain
import MEGAL10n

public enum FeatureType {
    case storage, transfer, passwordProtectedLinks, linksWithExpiryDate, transferSharing, rewind, vpn, callsAndMeetingsDuration, callsAndMeetingsParticipants
}

public protocol FeatureListHelperProtocol {
    func createCurrentFeatures(baseStorage: Int) -> [FeatureDetails]
}

struct FeatureListHelper: FeatureListHelperProtocol {
    let currentPlan: PlanEntity
    let assets: CancelAccountPlanAssets
    
    // The Cancel Subscription flow is only available for pro standard accounts (Pro I, II, III, lite, and Pro Flexi).
    // For this reason, we only set the limit of the rewind feature for the above-mentioned accounts.
    var rewindLimit: Int {
        switch currentPlan.type {
        case .lite: 90
        case .proI, .proII, .proIII, .business, .proFlexi: 180
        default: 0
        }
    }
    
    func createCurrentFeatures(baseStorage: Int) -> [FeatureDetails] {
        [
            FeatureDetails(
                type: .storage,
                title: Strings.Localizable.storage,
                freeText: Strings.Localizable.Storage.Limit.capacity(baseStorage),
                proText: currentPlan.storage
            ),
            FeatureDetails(
                type: .transfer,
                title: Strings.Localizable.transfer,
                freeText: Strings.Localizable.Account.TransferQuota.FreePlan.limited,
                proText: currentPlan.transfer
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
                proText: Strings.Localizable.Rewind.For.Pro.users(rewindLimit)
            ),
            FeatureDetails(
                type: .vpn,
                title: Strings.Localizable.Mega.Vpn.title,
                freeIconName: assets.unavailableImageName,
                proIconName: assets.availableImageName
            ),
            FeatureDetails(
                type: .callsAndMeetingsDuration,
                title: Strings.Localizable.CallAndMeeting.Duration.title,
                freeText: Strings.Localizable.CallAndMeeting.Duration.For.Free.users,
                proText: Strings.Localizable.CallAndMeeting.Duration.Unlimited.For.Pro.users
            ),
            FeatureDetails(
                type: .callsAndMeetingsParticipants,
                title: Strings.Localizable.CallAndMeeting.Participants.title,
                freeText: Strings.Localizable.CallAndMeeting.Participants.For.Free.users,
                proText: Strings.Localizable.CallAndMeeting.Participants.Unlimited.For.Pro.users
            )
        ]
    }
}
