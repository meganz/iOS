extension NodeActions {
    /// creates new instance of a NodeActionsDelegateHandler to be used inside CloudDrive toolbar actions
    /// This is possible as it only depends on the self (NodeActions) which stores all action handlers to executre any
    /// action on any nodes.
    /// NodeActionsDelegateHandler implements NodeActionViewControllerDelegate protocol used and required by
    /// NodeActionViewController
    func makeNodeActionsHandler(toggleEditMode: @escaping (Bool) -> Void) -> NodeActionsDelegateHandler {
        .init(
            download: nodeDownloader,
            browserAction: browserAction,
            moveToRubbishBin: moveToRubbishBin,
            exportFiles: exportFiles,
            shareFolders: shareFolders,
            shareOrManageLink: shareOrManageLink,
            sendToChat: sendToChat,
            removeLink: removeLink,
            removeFromRubbishBin: removeFromRubbishBin,
            saveToPhotos: saveToPhotos,
            showNodeInfo: showNodeInfo,
            toggleNodeFavourite: toggleNodeFavourite,
            assignLabel: assignLabel,
            leaveSharing: leaveSharing,
            rename: rename,
            removeSharing: removeSharing,
            viewVersions: showNodeVersions,
            restore: restoreFromRubbishBin,
            manageShare: { manageShare([$0]) },
            shareFolder: { shareFolders([$0]) },
            editTextFile: editTextFile,
            disputeTakedown: disputeTakedown,
            hide: hide,
            unhide: unhide,
            addToAlbum: addToAlbum,
            addTo: addTo,
            toggleEditMode: toggleEditMode
        )
    }
    
}
