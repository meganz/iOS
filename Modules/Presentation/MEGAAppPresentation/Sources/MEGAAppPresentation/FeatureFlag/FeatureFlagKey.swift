import MEGADomain

public enum FeatureFlagKey: FeatureFlagName, CaseIterable, Sendable {
    case videoPlaylistSharing = "Video Playlist Sharing"
    case recentlyWatchedVideos = "Recently Watched Videos"
    case photosBrowser = "New Photos Browser"
    case addVideosToVideoPlaylist = "Add videos to video playlist"
    case reorderVideosInVideoPlaylistContent = "Reorder videos in video playlist content"
    case webclientSubscribersCancelSubscription = "Webclient subscribers cancel subscription flow"
    case multipleOptionsForCancellationSurvey = "Multiple Options for Cancellation Survey"
    case newSetting = "New Setting"
    case loginRegisterAndOnboardingRevamp = "Use revamp contained in the MEGAAuthentication package"
    case navigationRevamp = "Navigation Revamp"
    case cameraUploadsRevamp = "Camera Uploads Revamp"
    case dotAppDomain = ".app Domain"
    case videoPlayerRevamp = "Video Player Revamp"

    /// The keys that are ready for production release, but not yet removed from code.
    /// Discussion:
    /// - For some features, we want to release them without having to remove their flags from code as a risk management measure.
    /// Instead we'll enable them first and then proceed to remove the flags after the features are stable.
    public static let rolledOutKeys: Set<FeatureFlagKey> = [
        .loginRegisterAndOnboardingRevamp,
        .navigationRevamp, .cameraUploadsRevamp]
}
