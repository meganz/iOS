import Foundation

@MainActor
final class NodeLinkRouter: NSObject {

    private weak var navigationController: UINavigationController?

    init(navigationController: UINavigationController? = nil) {
        self.navigationController = navigationController
    }

    // MARK: - Public

    func showLinkManagement(for node: MEGANode) {
        guard let navigationController else { return }
        GetLinkRouter(presenter: navigationController,
                      nodes: [node]).start()
    }
}
