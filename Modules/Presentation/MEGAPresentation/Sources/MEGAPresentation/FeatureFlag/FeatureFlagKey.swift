import MEGADomain

public enum FeatureFlagKey: FeatureFlagName, CaseIterable {
    case newHomeSearch = "New Home Search"
    case albumPhotoCache = "Album and Photo Cache"
    case onboardingProPlan = "Onboarding Pro Plan Upselling Dialog"
    case chipsGroups = "Chips groups and dropdown chips picker"
    case designToken = "MEGADesignToken"
    case newCloudDrive = "New Cloud Drive"
    case videoRevamp = "Video Revamp"
    case notificationCenter = "NotificationCenter"
    case chatMonetization =  "Chats and Meetings Monetization"
    case hiddenNodes =  "Hidden Nodes"
    case callKitRefactor =  "Call Kit refactor"
}
