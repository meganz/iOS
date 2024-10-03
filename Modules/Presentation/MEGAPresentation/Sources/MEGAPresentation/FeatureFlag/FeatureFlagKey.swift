import MEGADomain

public enum FeatureFlagKey: FeatureFlagName, CaseIterable, Sendable {
    case albumPhotoCache = "Album and Photo Cache"
    case hiddenNodes =  "Hidden Nodes"
    case videoPlaylistSharing = "Video Playlist Sharing"
    case recentlyWatchedVideos = "Recently Watched Videos"
    case photosBrowser = "New Photos Browser"
    case visualMediaSearch = "Search Albums and Photos"
    case addVideosToVideoPlaylist = "Add videos to video playlist"
    case fullStorageOverQuotaBanner = "Full Storage Over Quota banner"
    case almostFullStorageOverQuotaBanner = "Almost Full Storage Over Quota banner"
    case reorderVideosInVideoPlaylistContent = "Reorder videos in video playlist content"
    case addToAlbumAndPlaylists = "Add to Album and Playlists"
    case nodeTags = "Node Tags"
}
