import MEGADomain
import MEGAL10n

@MainActor
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
        containerViewController.view.wrap(content.view)
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
    
    func setViewModePreference(_ preference: ViewModePreferenceEntity) {
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
    
    func toggleState() {
        fatalError("toogleCurrentState() needs to be implemented by the subclass")
    }
    
    func toggleSelectAllNodes() {
        filesExplorerViewController?.toggleSelectAllNodes()
    }
    
    func removeSearchController(_ searchController: UISearchController) {
        filesExplorerViewController?.removeSearchController(searchController)
    }
    
    func updateSearchResults(for searchString: String?) {
        filesExplorerViewController?.updateSearchResults(for: searchString)
    }

    // MARK: - FilesExplorerViewControllerDelegate
    
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
    
    func showMoreButton(_ show: Bool) {
        containerViewController.showMoreButton(show)
    }
    
    func showSelectButton(_ show: Bool) {
        containerViewController.showSelectButton(show)
    }
    
    func updateContentView(_ height: CGFloat) {
        filesExplorerViewController?.updateContentView(height)
    }
    
    func audioPlayer(hidden: Bool) {
        containerViewController.audioPlayer(hidden: hidden)
    }
    
    func updateContextMenu(menu: UIMenu) {
        containerViewController.updateContextMenu(menu: menu)
    }
    
    func updateUploadAddMenu(menu: UIMenu) {
        containerViewController.updateUploadAddMenu(menu: menu)
    }
    
    func changeCurrentViewType() {
        containerViewController.updateCurrentState()
    }
    
    func didSelect(action: UploadAddActionEntity) {
        containerViewController.didSelect(action: action)
    }

    // MARK: - Private methods.
    
    func updateTitle(withNodesCount count: Int) {
        let title: String
        switch count {
        case 0:
            title = Strings.Localizable.selectTitle
        default:
            title = Strings.Localizable.General.Format.itemsSelected(count)
        }
        
        containerViewController.updateTitle(title)
    }
}
