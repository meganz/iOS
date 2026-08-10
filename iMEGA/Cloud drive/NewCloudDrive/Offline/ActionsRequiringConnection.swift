import CloudDrive
import MEGADomain

// The offline policy for every Cloud Drive action, in one place (IOS-12228).
//
// `requiresConnection` is true for anything that changes remote state and for anything that has
// to start a transfer — per the agreed Phase 1 scope, starting an upload or a download is
// intercepted too, while the local transfer engine operations (pause/resume/cancel) are not
// reached from here and stay available.
//
// The switches are exhaustive on purpose: adding a case to one of these enums should not compile
// until its offline behaviour has been decided.

extension BottomToolbarAction {
    var requiresConnection: Bool {
        switch self {
        case .download, .shareLink, .move, .copy, .delete, .restore:
            true
        case .actions:
            // Opens a sheet whose own actions are guarded individually
            false
        }
    }
}

extension QuickActionEntity {
    var requiresConnection: Bool {
        switch self {
        case .download, .shareLink, .manageLink, .removeLink, .shareFolder, .manageFolder,
             .rename, .copy, .removeSharing, .leaveSharing, .sendToChat, .saveToPhotos,
             .hide, .unhide:
            true
        case .info, .settings:
            false
        case .dispute:
            // Opens the takedown dispute page in a browser
            true
        }
    }
}

extension DisplayActionEntity {
    var requiresConnection: Bool {
        switch self {
        case .clearRubbishBin:
            true
        case .newPlaylist:
            // Creating a video playlist is a remote Set mutation. Cloud Drive's menu never offers
            // it today, but the policy has to stay honest about what the action does.
            true
        case .select, .mediaDiscovery, .thumbnailView, .listView, .sort, .filter, .filterActive,
             .locationFilter, .durationFilter, .mediaTypeFilter, .mediaLocationFilter:
            false
        }
    }
}

extension RubbishBinActionEntity {
    var requiresConnection: Bool {
        switch self {
        case .restore, .remove:
            true
        case .info, .versions:
            false
        }
    }
}

extension FloatingActionEntity {
    var requiresConnection: Bool {
        switch self {
        case .chooseFromPhotos, .capture, .importFrom, .scanDocument, .newFolder, .newTextFile,
             .openLink:
            true
        }
    }
}

extension UploadAddActionEntity {
    var requiresConnection: Bool {
        switch self {
        case .chooseFromPhotos, .capture, .importFrom, .scanDocument, .newFolder, .newTextFile,
             .importFolderLink:
            true
        }
    }
}

extension MegaNodeActionType {
    /// `MegaNodeActionType` is an Objective-C enum shared with screens outside Cloud Drive, so
    /// this lists what stays available and treats everything else as needing a connection —
    /// a new action is blocked offline until someone decides otherwise, never silently allowed.
    var requiresConnection: Bool {
        switch self {
        case .info, .viewVersions, .select, .search, .list, .thumbnail, .sort, .mediaDiscovery,
             .pdfPageView, .pdfThumbnailView, .viewInFolder, .showInLocation, .clear, .verifyContact:
            false
        default:
            true
        }
    }
}
