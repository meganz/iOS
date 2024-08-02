import MEGADomain

public enum FeatureFlagKey: FeatureFlagName, CaseIterable {
    case newHomeSearch = "New Home Search"
    case albumPhotoCache = "Album and Photo Cache"
    case designToken = "MEGADesignToken"
    case newCloudDrive = "New Cloud Drive"
    case videoRevamp = "Video Revamp"
    case notificationCenter = "NotificationCenter"
    case hiddenNodes =  "Hidden Nodes"
    case cancelSubscription = "Cancel Subscription"
    case videoPlaylistSharing = "Video Playlist Sharing"
    case nodeDescription = "Node Description"
    case photosBrowser = "New Photos Browser"
}
