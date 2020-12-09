
class FilesExplorerContainerViewState: FilesExplorerViewControllerDelegate {
    class var identifier: AnyHashable {
      return ObjectIdentifier(self)
    }
    
    unowned let containerViewController: FilesExplorerContainerViewController
    let viewModel: FilesExplorerViewModel
    
    var title: String? {
        return filesExplorerViewController?.title()
    }
    
    private var filesExplorerViewController: FilesExplorerViewController? {
        return childViewController as? FilesExplorerViewController
    }
    
    var childViewController: UIViewController? {
        assert(containerViewController.children.count < 2,
               "multiple view controllers added to container")
        return containerViewController.children.first
    }

    init(containerViewController: FilesExplorerContainerViewController,
         viewModel: FilesExplorerViewModel) {
        self.containerViewController = containerViewController
        self.viewModel = viewModel
    }

    func add(content: UIViewController) {
        containerViewController.addChild(content)
        containerViewController.view.addSubview(content.view)
        content.view.autoPinEdgesToSuperviewEdges()
        content.didMove(toParent: containerViewController)
    }

    func remove(content: UIViewController) {
        guard content.view.superview != nil else { return }
        content.willMove(toParent: nil)
        content.view.removeFromSuperview()
        content.removeFromParent()
    }
    
    func transitionToState(matching identifier: AnyHashable) -> FilesExplorerContainerViewState {
        let state = containerViewController.states[identifier]!
        containerViewController.currentState = state
        return state
    }

    func showContent() {
        removeChildrenFromContainerIfNeeded()
    }
    
    func removeChildrenFromContainerIfNeeded() {
        containerViewController.children.forEach { remove(content: $0)}
    }
    
    func setViewModePreference(_ preference: ViewModePreference) {
        containerViewController.setViewModePreference(preference)
    }
    
    func updateTitle() {
        if let title = title {
            containerViewController.updateTitle(title)
        }
    }
    
    func setEditingMode() {
        updateTitle(withNodesCount: 0)
        filesExplorerViewController?.setEditingMode()
    }
    
    func endEditingMode() {
        filesExplorerViewController?.endEditingMode()
    }
    
    func showPreferences(sender: UIBarButtonItem) {
        fatalError("showPreferences(sender:) needs to be implemented by the subclass")
    }
    
    func toggleSelectAllNodes() {
        filesExplorerViewController?.toggleSelectAllNodes()
    }
    
    func configureSearchController(_ searchController: UISearchController) {
        filesExplorerViewController?.configureSearchController(searchController)
    }
    
    func removeSearchController(_ searchController: UISearchController) {
        filesExplorerViewController?.removeSearchController(searchController)
    }
    
    func updateSearchResults(for searchString: String?) {
        filesExplorerViewController?.updateSearchResults(for: searchString)
    }

    //MARK:- FilesExplorerViewControllerDelegate
    
    func updateSearchResults() {
        containerViewController.updateSearchResults()
    }
    
    func didScroll(scrollView: UIScrollView) {}
    
    func didSelectNodes(withCount count: Int) {
        updateTitle(withNodesCount: count)
    }
    
    func configureNavigationBarToDefault() {
        containerViewController.configureNavigationBarToDefault()
    }
    
    func showSearchBar(_ show: Bool) {
        containerViewController.showSearchBar(show)
    }
    
    func showMoreButton(_ show: Bool) {
        containerViewController.showMoreButton(show)
    }
    
    // MARK: - Private methods.
    
    func updateTitle(withNodesCount count: Int) {
        let title: String
        switch count {
        case 0:
            title = NSLocalizedString("selectTitle", comment: "Title shown on the Camera Uploads section when the edit mode is enabled. On this mode you can select photos")
        case 1:
            title = String(format: NSLocalizedString("oneItemSelected", comment: "Title shown on the Camera Uploads section when the edit mode is enabled and you have selected one photo"), count)
        default:
            title = String(format: NSLocalizedString("itemsSelected", comment: "Title shown on the Camera Uploads section when the edit mode is enabled and you have selected more than one photo"), count)
        }
        
        containerViewController.updateTitle(title)
    }
}
