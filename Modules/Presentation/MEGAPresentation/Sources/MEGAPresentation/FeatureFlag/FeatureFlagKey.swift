import MEGADomain

public enum FeatureFlagKey: FeatureFlagName, CaseIterable {
    case deviceCenter = "Device Center"
    case newHomeSearch = "New Home Search"
    case cloudDriveMediaDiscoveryIntegration = "Cloud Drive Media Discovery Integration"
    case inAppAds = "In-App Ads"
    case albumPhotoCache = "Album and Photo Cache"
    case timelineCameraUploadStatus = "Timeline Camera Upload Status"
    case onboardingProPlan = "Onboarding Pro Plan Upselling Dialog"
}
