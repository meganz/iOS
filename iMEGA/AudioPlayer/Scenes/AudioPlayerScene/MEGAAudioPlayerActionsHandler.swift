import MEGAAppSDKRepo
import MEGAAudioPlayer
import MEGADomain
import MEGASDKRepo
import UIKit

/// Builds the closure that `MEGAAudioPlayerViewRouter` invokes when the user
/// taps the three-dot button on the revamped audio player.
@MainActor
enum MEGAAudioPlayerActionsHandler {
    static func make() -> MEGAAudioPlayerViewRouter.ActionsHandler {
        { hostVC, track in
            switch track {
            case .account(let node), .folderLink(let node):
                presentNodeAction(for: node, on: hostVC)
            case .fileLink(let url, _):
                presentFileLinkAction(for: url, on: hostVC)
            case .offline:
                // The player hides the three-dot for offline playback, matching
                // legacy. This branch only runs if that invariant breaks.
                break
            }
        }
    }

    private static func presentNodeAction(for nodeEntity: NodeEntity, on hostVC: UIViewController) {
        guard let node = MEGASdk.sharedSdk.node(forHandle: nodeEntity.handle) else { return }
        let displayMode: DisplayMode = node.mnz_isInRubbishBin() ? .rubbishBin : .cloudDrive
        let isBackupNode = BackupsUseCase(
            backupsRepository: BackupsRepository.newRepo,
            nodeRepository: NodeRepository.newRepo
        ).isBackupNode(nodeEntity)
        let delegate = NodeActionViewControllerGenericDelegate(
            viewController: hostVC,
            moveToRubbishBinViewModel: MoveToRubbishBinViewModel(presenter: hostVC)
        )
        let vc = PortraitNodeActionViewController(
            node: node,
            delegate: delegate,
            displayMode: displayMode,
            isIncoming: false,
            isBackupNode: isBackupNode,
            sender: hostVC
        )
        hostVC.present(vc, animated: true)
    }

    private static func presentFileLinkAction(for url: URL, on hostVC: UIViewController) {
        let link = url.absoluteString
        Task { @MainActor [weak hostVC] in
            let node: MEGANode? = await withCheckedContinuation { continuation in
                MEGASdk.sharedSdk.publicNode(forMegaFileLink: link, delegate: RequestDelegate { result in
                    switch result {
                    case .success(let request):
                        continuation.resume(returning: request.publicNode)
                    case .failure:
                        continuation.resume(returning: nil)
                    }
                })
            }
            guard let node, let hostVC else { return }
            let displayMode: DisplayMode = node.mnz_isInRubbishBin() ? .rubbishBin : .cloudDrive
            let delegate = FileLinkActionViewControllerDelegate(link: link, viewController: hostVC)
            let vc = PortraitNodeActionViewController(
                node: node,
                delegate: delegate,
                displayMode: displayMode,
                isInVersionsView: false,
                isBackupNode: false,
                isFromSharedItem: false,
                isAudioFileLink: true,
                sender: hostVC
            )
            hostVC.present(vc, animated: true)
        }
    }
}
