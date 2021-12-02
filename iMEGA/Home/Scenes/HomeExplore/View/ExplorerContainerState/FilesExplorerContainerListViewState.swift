
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
    
    override func showPreferences(sender: UIBarButtonItem) {
        var viewPreferenceAction: ActionSheetAction? = nil
        if (self.viewModel.getExplorerType()  == .document) {
            viewPreferenceAction = ActionSheetAction(
                title: Strings.Localizable.thumbnailView,
                detail: nil,
                image: UIImage(named: "thumbnailsThin"),
                style: .default) { [weak self] in
                guard let self = self else { return }
                let nextState = self.transitionToState(matching: FilesExplorerContainerGridViewState.identifier)
                nextState.showContent()
            }
        }
        containerViewController.showPreferences(
            withViewPreferenceAction: viewPreferenceAction,
            sender: sender
        )
    }
}
