import Foundation

/// Represents the view display mode
public enum ViewDisplayMode: Sendable, CaseIterable {
    case unknown
    case cloudDrive
    case rubbishBin
    case sharedItem
    case nodeInfo
    case nodeVersions
    case folderLink
    case fileLink
    case nodeInsideFolderLink
    case recents
    case publicLinkTransfers
    case transfers
    case transfersFailed
    case chatAttachment
    case chatSharedFiles
    case previewDocument
    case textEditor
    case backup
    case mediaDiscovery
    case photosFavouriteAlbum
    case photosAlbum
    case photosTimeline
    case previewPdfPage
    case albumLink
    case home
    case videoPlaylistContent
}
