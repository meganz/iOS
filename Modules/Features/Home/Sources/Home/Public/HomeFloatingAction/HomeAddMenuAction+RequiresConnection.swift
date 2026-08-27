public extension HomeAddMenuAction {
    /// The offline policy for the Home add menu — the floating + button and the Upload button in
    /// the Recents empty state, which open the same sheet
    ///
    /// The switch is exhaustive on purpose: adding a case should not compile until its offline
    /// behaviour has been decided.
    var requiresConnection: Bool {
        switch self {
        case .chooseFromPhotos, .capture, .importFromFiles, .scanDocument, .newTextFile, .openLink,
             .newChat:
            true
        }
    }
}
