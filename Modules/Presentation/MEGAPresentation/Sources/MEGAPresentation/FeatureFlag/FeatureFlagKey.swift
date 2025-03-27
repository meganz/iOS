import MEGADomain

public enum FeatureFlagKey: FeatureFlagName, CaseIterable, Sendable {
    case videoPlaylistSharing = "Video Playlist Sharing"
    case recentlyWatchedVideos = "Recently Watched Videos"
    case photosBrowser = "New Photos Browser"
    case addVideosToVideoPlaylist = "Add videos to video playlist"
    case reorderVideosInVideoPlaylistContent = "Reorder videos in video playlist content"
    case nodeTags = "Node Tags"
    case webclientSubscribersCancelSubscription = "Webclient subscribers cancel subscription flow"
    case multipleOptionsForCancellationSurvey = "Multiple Options for Cancellation Survey"
    case newCallsSetting = "New Calls Setting"
    case newFileManagementSettings = "New File Management Settings"
    case newChatSetting = "New Chat Setting"
    case searchByNodeTags = "Search By Node Tags"
    case noteToSelfChat = "Note to Self Chat"

    /// The keys that are ready for production release, but not yet removed from code.
    /// Discussion:
    /// - For some features, we want to release them without having to remove their flags from code as a risk management measure.
    /// Instead we'll enable them first and then proceed to remove the flags after the features are stable.
    public static let rolledOutKeys: Set<FeatureFlagKey> = [Self.nodeTags, .searchByNodeTags]
}
