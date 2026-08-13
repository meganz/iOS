public extension FloatingActionEntity {
    /// The offline policy for the floating add button's actions (IOS-12228): every one of them
    /// either changes remote state or has to start a transfer, so none survives being offline.
    ///
    /// It lives next to the enum rather than in MEGAAppPresentation — where the shared
    /// context-menu policy lives — because this package depends on MEGAAppPresentation, so the
    /// dependency cannot run the other way.
    ///
    /// The switch is exhaustive on purpose: adding a case should not compile until its offline
    /// behaviour has been decided.
    var requiresConnection: Bool {
        switch self {
        case .chooseFromPhotos, .capture, .importFrom, .scanDocument, .newFolder, .newTextFile,
             .openLink:
            true
        }
    }
}
