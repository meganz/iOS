import MEGADomain

public enum FeatureFlagKey: FeatureFlagName, CaseIterable, Sendable {
    case videoPlaylistSharing = "Video Playlist Sharing"
    case recentlyWatchedVideos = "Recently Watched Videos"
    case photosBrowser = "New Photos Browser"
    case visualMediaSearch = "Search Albums and Photos"
    case addVideosToVideoPlaylist = "Add videos to video playlist"
    case almostFullStorageOverQuotaBanner = "Almost Full Storage Over Quota banner"
    case reorderVideosInVideoPlaylistContent = "Reorder videos in video playlist content"
    case addToAlbumAndPlaylists = "Add to Album and Playlists"
    case nodeTags = "Node Tags"
    case markdownSupport = "Markdown support"
    case webclientSubscribersCancelSubscription = "Webclient subscribers cancel subscription flow"
    case multipleOptionsForCancellationSurvey = "Multiple Options for Cancellation Survey"
    case followUpOptionsForCancellationSurvey = "Follow up Options for Cancellation Survey"
    case newCallsSetting = "New Calls Setting"
}
