extension ContextMenuManager {
    /// This will check and return an array of all non-nil delegates used by ContextMenuManager
    /// it's needed as ContextMenuManager is weakly linking to them, so that we have to retain them elsewhere
    /// Thanks to this, we can grab all delegates and store in the in the array of a view model in one line
    /// Example of use is in the NodeBrowserViewModel.actionHandlers
    /// Warning, as those delegate references are weak, this needs to be called before scope finishes
    /// as those delegate objects will deallocated if there are no other strong references to them
    /// See CloudDriveViewControllerFactory for an example usage
    func allNonNilActionHandlers() -> [AnyObject] {
        let delegates: [AnyObject?] = [
            displayMenuDelegate,
            quickActionsMenuDelegate,
            uploadAddMenuDelegate,
            rubbishBinMenuDelegate,
            chatMenuDelegate,
            qrMenuDelegate,
            meetingContextMenuDelegate,
            filterMenuDelegate,
            albumMenuDelegate
        ]
        
        return delegates.compactMap { $0 }
    }
}
