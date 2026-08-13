// The offline policy for the two action types that cannot leave the app target (IOS-12228):
// `MegaNodeActionType` is an Objective-C enum declared in the app's headers, and
// `BottomToolbarAction` is owned by the Cloud Drive select-mode toolbar here.
//
// The shared context-menu enums carry the same property in
// MEGAAppPresentation/Offline/ActionsRequiringConnection.swift, and the floating add button's
// in CloudDrive/UploadActions/FloatingActionEntity+RequiresConnection.swift; the rules below
// follow them.
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
