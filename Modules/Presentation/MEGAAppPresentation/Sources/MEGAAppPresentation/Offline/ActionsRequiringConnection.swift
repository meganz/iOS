import MEGADomain

// The offline policy for the shared context-menu actions (IOS-12228).
//
// `requiresConnection` is true for anything that changes remote state and for anything that has
// to start a transfer — per the agreed Phase 1 scope, starting an upload or a download is
// intercepted too, while the local transfer engine operations (pause/resume/cancel) are not
// reached from here and stay available.
//
// The switches are exhaustive on purpose: adding a case to one of these enums should not compile
// until its offline behaviour has been decided.
//
// Action types that cannot be seen from here — the Objective-C `MegaNodeActionType` and the
// screen-owned toolbar/floating-button enums — carry the same property in the app target; see
// `ActionsRequiringConnection+App.swift`.

public extension QuickActionEntity {
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

public extension DisplayActionEntity {
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

public extension RubbishBinActionEntity {
    var requiresConnection: Bool {
        switch self {
        case .restore, .remove:
            true
        case .info, .versions:
            false
        }
    }
}

public extension UploadAddActionEntity {
    var requiresConnection: Bool {
        switch self {
        case .chooseFromPhotos, .capture, .importFrom, .scanDocument, .newFolder, .newTextFile,
             .importFolderLink:
            true
        }
    }
}
