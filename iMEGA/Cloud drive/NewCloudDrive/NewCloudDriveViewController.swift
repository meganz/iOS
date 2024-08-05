import MEGADomain

/// Mordern replacement of CloudDriveViewController
final class NewCloudDriveViewController: SearchBarUIHostingController<NodeBrowserView> {
    private(set) var viewModeProvider: CloudDriveViewModeProvider
    private(set) var displayModeProvider: CloudDriveDisplayModeProvider
    private let parentNodeProvider: ParentNodeProvider

    init(
        rootView: NodeBrowserView,
        wrapper: SearchControllerWrapper,
        selectionHandler: SearchControllerSelectionHandler,
        toolbarBuilder: CloudDriveBottomToolbarItemsFactory,
        backButtonTitle: String?,
        searchBarVisible: Bool,
        viewModeProvider: CloudDriveViewModeProvider,
        displayModeProvider: CloudDriveDisplayModeProvider,
        matchingNodeProvider: CloudDriveMatchingNodeProvider,
        audioPlayerManager: some AudioPlayerHandlerProtocol,
        parentNodeProvider: @escaping ParentNodeProvider
    ) {
        self.viewModeProvider = viewModeProvider
        self.displayModeProvider = displayModeProvider
        self.parentNodeProvider = parentNodeProvider
        super.init(
            rootView: rootView,
            wrapper: wrapper,
            selectionHandler: selectionHandler,
            toolbarBuilder: toolbarBuilder,
            backButtonTitle: backButtonTitle,
            searchBarVisible: searchBarVisible,
            matchingNodeProvider: matchingNodeProvider,
            audioPlayerManager: audioPlayerManager
        )
    }
    
    @MainActor required dynamic init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}

extension NewCloudDriveViewController: TextFileEditable {}

extension NewCloudDriveViewController {
    var parentNode: NodeEntity? {
        parentNodeProvider()
    }
}

/// For Quick Quick Upload feature, we need to know the current viewMode of the CloudDriveVC in order to generate the correct upload actions
/// CloudDriveViewModeProvider is used for that purpose
struct CloudDriveViewModeProvider {
    let viewMode: () -> ViewModePreferenceEntity?
}

/// For Ads Slot feature, we need to know the current displayMode of the CloudDriveVC in order to decide whether to show ads slot or not.
/// CloudDriveDisplayModeProvider is used for that purpose
struct CloudDriveDisplayModeProvider {
    let displayMode: () -> DisplayMode?
}
