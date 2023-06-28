import MEGADomain

public enum FeatureFlagKey: FeatureFlagName, CaseIterable {
    case scheduleMeeting = "Schedule Meeting"
    case newUpgradeAccountPlanUI = "New Upgrade Account Plan UI"
    case albumShareLink = "Album Share Link"
    case deviceCenter = "Device Center"
    case audioPlaybackContinuation = "Audio Playback Continuation"
}
