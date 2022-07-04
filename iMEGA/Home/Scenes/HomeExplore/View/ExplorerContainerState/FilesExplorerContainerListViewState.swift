
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
}
