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
    case crossfadeSlideShow = "Apply crossfade animation to slideshow"
    case navigationRevamp = "Navigation Revamp"
    case cameraUploadsRevamp = "Camera Uploads Revamp"
    case kmTransfer = "KM Transfer"
    case dotAppDomain = ".app Domain"

    /// The keys that are ready for production release, but not yet removed from code.
    /// Discussion:
    /// - For some features, we want to release them without having to remove their flags from code as a risk management measure.
    /// Instead we'll enable them first and then proceed to remove the flags after the features are stable.
    public static let rolledOutKeys: Set<FeatureFlagKey> = [.crossfadeSlideShow, .loginRegisterAndOnboardingRevamp]
}
