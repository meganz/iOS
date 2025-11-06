import MEGADomain

class FilesExplorerContainerListViewState: FilesExplorerContainerViewState {
    override func showContent() {
        super.showContent()
        let listViewController = FilesExplorerListViewController(
            viewModel: viewModel,
            delegate: self
        )
        add(content: listViewController)
        updateTitle()
        setViewModePreference(.list)
    }
    
    override func toggleState() {
        let nextState = self.transitionToState(matching: FilesExplorerContainerGridViewState.identifier)
        nextState.showContent()
    }

    override func handle(viewMode: ViewModePreferenceEntity) {
        guard viewMode != .list else { return }
        toggleState()
    }
}
