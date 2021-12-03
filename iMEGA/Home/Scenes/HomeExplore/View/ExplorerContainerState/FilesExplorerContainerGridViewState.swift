
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
            title: Strings.Localizable.listView,
            detail: nil,
            image: Asset.Images.ActionSheetIcons.gridThin.image,
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
