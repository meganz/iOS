
class FilesExplorerContainerGridViewState: FilesExplorerContainerViewState {
    override func showContent() {
        super.showContent()
        let gridViewController = FilesExplorerGridViewController(
            viewModel: viewModel,
            delegate: self
        )
        add(content: gridViewController)
        updateTitle()
        setViewModePreference(.thumbnail)
    }
    
    override func showPreferences(sender: UIBarButtonItem) {
        let viewPreferenceAction = ActionSheetAction(
            title: NSLocalizedString("List View", comment: "Text shown for switching from thumbnail view to list view."),
            detail: nil,
            image: UIImage(named: "gridThin"),
            style: .default) { [weak self] in
            guard let self = self else { return }
            let nextState = self.transitionToState(matching: FilesExplorerContainerListViewState.identifier)
            nextState.showContent()
        }
        containerViewController.showPreferences(
            withViewPreferenceAction: viewPreferenceAction,
            sender: sender
        )
    }
    
    override func didScroll(scrollView: UIScrollView) {
        containerViewController.hideKeyboardIfRequired()
    }
}
