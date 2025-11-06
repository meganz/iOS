import MEGADomain

@MainActor
class FilesExplorerContainerGridViewState: FilesExplorerContainerViewState {
    override func showContent() {
        super.showContent()
        
        var gridViewController: FilesExplorerViewController
        
        switch viewModel.getExplorerType() {
        case .favourites:
            gridViewController = FavouritesExplorerGridViewController(
                viewModel: viewModel,
                delegate: self)
        default:
            gridViewController = FilesExplorerGridViewController(
                viewModel: viewModel,
                delegate: self
            )
        }
        
        add(content: gridViewController)
        updateTitle()
        setViewModePreference(.thumbnail)
    }
    
    override func toggleState() {
        let nextState = self.transitionToState(matching: FilesExplorerContainerListViewState.identifier)
        nextState.showContent()
    }
    
    override func didScroll(scrollView: UIScrollView) {
        containerViewController.hideKeyboardIfRequired()
    }

    override func handle(viewMode: ViewModePreferenceEntity) {
        guard viewMode != .thumbnail else { return }
        toggleState()
    }
}
