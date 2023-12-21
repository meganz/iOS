import Foundation

extension MEGANode {
    @objc func pushCloudDriveForNode(_ node: MEGANode, displayMode: DisplayMode, navigationController: UINavigationController) {
        let factory = CloudDriveViewControllerFactory.make()
        let vc = factory.buildBare(
            parentNode: node.toNodeEntity(),
            options: .init(
                displayMode: displayMode
            )
        )
        guard let vc else { return }
        navigationController.pushViewController(vc, animated: false)
    }
}
