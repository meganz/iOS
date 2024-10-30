import MEGADomain
import MEGASDKRepo

extension MegaNodeActionType {
    
    func toNodeActionTypeEntity() -> NodeActionTypeEntity? {
        switch self {
        case .download: .download
        case .exportFile: .exportFile
        case .copy: .copy
        case .move: .move
        case .info: .info
        case .favourite: .favourite
        case .label: .label
        case .leaveSharing: .leaveSharing
        case .rename: .rename
        case .removeLink: .removeLink
        case .moveToRubbishBin: .moveToRubbishBin
        case .remove: .remove
        case .removeSharing: .removeSharing
        case .import: .import
        case .viewVersions: .viewVersions
        case .revertVersion: .revertVersion
        case .select: .select
        case .restore: .restore
        case .saveToPhotos: .saveToPhotos
        case .manageShare: .manageShare
        case .shareFolder: .shareFolder
        case .manageLink: .manageLink
        case .shareLink: .shareLink
        case .sendToChat: .sendToChat
        case .pdfPageView: .pdfPageView
        case .pdfThumbnailView: .pdfThumbnailView
        case .forward: .forward
        case .viewInFolder: .viewInFolder
        case .clear: .clear
        case .retry: .retry
        case .search: .search
        case .list: .list
        case .thumbnail: .thumbnail
        case .sort: .sort
        case .editTextFile: .editTextFile
        case .disputeTakedown: .disputeTakedown
        case .verifyContact: .verifyContact
        case .restoreBackup: .restoreBackup
        case .mediaDiscovery: .mediaDiscovery
        case .hide: .hide
        case .unhide: .unhide
        case .removeVideoFromVideoPlaylist: .removeVideoFromVideoPlaylist
        case .moveVideoInVideoPlaylistContentToRubbishBin: .moveVideoInVideoPlaylistContentToRubbishBin
        case .addTo: .addTo
        case .addToAlbum: .addToAlbum
        @unknown default: nil
        }
    }
}
