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
    case cameraUploadsRevamp = "Camera Uploads Revamp"
    case dotAppDomain = ".app Domain"
    case videoPlayerRevamp = "Video Player Revamp"
    case cloudDriveRevamp = "Cloud Drive Revamp"
    case mediaRevamp = "Media Revamp"
    case appPerfomanceMonitoring = "App Perfomance Monitoring"

    /// The keys that are ready for production release, but not yet removed from code.
    /// Discussion:
    /// - For some features, we want to release them without having to remove their flags from code as a risk management measure.
    /// Instead we'll enable them first and then proceed to remove the flags after the features are stable.
    public static let rolledOutKeys: Set<FeatureFlagKey> = [
        .cameraUploadsRevamp,
        .dotAppDomain,
        .cloudDriveRevamp
    ]
}
