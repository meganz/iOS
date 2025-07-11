import ChatRepo
import MEGAAppSDKRepo
import MEGAAssets
import MEGADomain
import MEGAPermissions

@objc final class SaveMediaToPhotosUseCaseOCWrapper: NSObject {
    @objc func saveToPhotos(nodes: [MEGANode], isFolderLink: Bool = false) {
        Task { @MainActor in
            SaveToPhotosCoordinator.customProgressSVGErrorMessageDisplay(
                isFolderLink: isFolderLink,
                configureProgress: {
                    TransfersWidgetViewController.sharedTransfer().bringProgressToFrontKeyWindowIfNeeded()
                })
            .saveToPhotos(nodes: nodes.toNodeEntities())
        }
    }
}
