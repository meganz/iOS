import MEGADomain

public enum FeatureFlagKey: FeatureFlagName, CaseIterable, Sendable {
    case videoPlaylistSharing = "Video Playlist Sharing"
    case recentlyWatchedVideos = "Recently Watched Videos"
    case photosBrowser = "New Photos Browser"
    case visualMediaSearch = "Search Albums and Photos"
    case addVideosToVideoPlaylist = "Add videos to video playlist"
    case reorderVideosInVideoPlaylistContent = "Reorder videos in video playlist content"
    case nodeTags = "Node Tags"
    case webclientSubscribersCancelSubscription = "Webclient subscribers cancel subscription flow"
    case multipleOptionsForCancellationSurvey = "Multiple Options for Cancellation Survey"
    case newCallsSetting = "New Calls Setting"
    case newFileManagementSettings = "New File Management Settings"
    case newChatSetting = "New Chat Setting"
    case searchByNodeTags = "Search By Node Tags"
    case newCloudDriveHomeRecents = "New Cloud Drive - Recent files"
    case newLoadingView = "New Loading view"
    case noteToSelfChat = "Note to Self Chat"
}
