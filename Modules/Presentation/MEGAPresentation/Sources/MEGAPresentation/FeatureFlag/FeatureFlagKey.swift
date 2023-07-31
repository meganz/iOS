import MEGADomain

public enum FeatureFlagKey: FeatureFlagName, CaseIterable {
    case scheduleMeeting = "Schedule Meeting"
    case newUpgradeAccountPlanUI = "New Upgrade Account Plan UI"
    case albumShareLink = "Album Share Link"
    case deviceCenter = "Device Center"
    case contactVerification = "Contact verification UI/UX updates"
    case waitingRoom = "Waiting Room"
}
