import Search

extension DisplayMode {
    var toViewDisplayMode: ViewDisplayMode {
        switch self {
        case .unknown:
                .unknown
        case .cloudDrive:
                .cloudDrive
        case .rubbishBin:
                .rubbishBin
        case .sharedItem:
                .sharedItem
        case .nodeInfo:
                .nodeInfo
        case .nodeVersions:
                .nodeVersions
        case .folderLink:
                .folderLink
        case .fileLink:
                .fileLink
        case .nodeInsideFolderLink:
                .nodeInsideFolderLink
        case .recents:
                .recents
        case .publicLinkTransfers:
                .publicLinkTransfers
        case .transfers:
                .transfers
        case .transfersFailed:
                .transfersFailed
        case .chatAttachment:
                .chatAttachment
        case .chatSharedFiles:
                .chatSharedFiles
        case .previewDocument:
                .previewDocument
        case .textEditor:
                .textEditor
        case .backup:
                .backup
        case .mediaDiscovery:
                .mediaDiscovery
        case .photosFavouriteAlbum:
                .photosFavouriteAlbum
        case .photosAlbum:
                .photosAlbum
        case .photosTimeline:
                .photosTimeline
        case .previewPdfPage:
                .previewPdfPage
        case .albumLink:
                .albumLink
        case .videoPlaylistContent:
                .videoPlaylistContent
        @unknown default:
                .unknown
        }
    }
}
