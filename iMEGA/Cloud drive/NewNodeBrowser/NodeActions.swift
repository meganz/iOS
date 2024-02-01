import MEGADomain
import MEGASDKRepo
/// Place to store quick node actions instead of injecting tens of closures directly into the factory
/// Probably all single use router access can be moved here
/// And entire thing could be injected from the outside as it mostly needs
/// parentViewController and a node or array of nodes
struct NodeActions {
    var nodeDownloader: ([CancellableTransfer]) -> Void
    var getLinkOpener: ([NodeEntity]) -> Void
    var copyNode: (NodeEntity) -> Void
    var userProfileOpener: (UINavigationController) -> Void
    var removeLink: ([NodeEntity]) -> Void
    var removeSharing: (NodeEntity) -> Void
    // second argument should be called to trigger NavBar title refresh
    var rename: (_ node: NodeEntity, _ nameChanged: @escaping () -> Void) -> Void
    var leaveSharing: (NodeEntity) -> Void
    var restoreFromRubbishBin: (NodeEntity) -> Void
    var showNodeVersions: (NodeEntity) -> Void
    // this is handling rubbish bin action
    var remove: (NodeEntity) -> Void
}

extension NodeActions {
    static func makeActions(
        sdk: MEGASdk,
        nc: UINavigationController?
    ) -> NodeActions {
        .init(
            nodeDownloader: { transfers in
                guard let nc else { return }
                CancellableTransferRouter(
                    presenter: nc,
                    transfers: transfers,
                    transferType: .download
                ).start()
            },
            getLinkOpener: { nodes in
                guard let nc else { return }
                GetLinkRouter(
                    presenter: nc,
                    nodes: nodes.compactMap { sdk.node(forHandle: $0.handle) }
                ).start()
            },
            copyNode: {
                guard let nc else { return }
                sdk.node(forHandle: $0.handle)?.mnz_copy(in: nc)
            },
            userProfileOpener: { navigationController in
                MyAccountHallRouter(
                    myAccountHallUseCase: MyAccountHallUseCase(repository: AccountRepository.newRepo),
                    purchaseUseCase: AccountPlanPurchaseUseCase(repository: AccountPlanPurchaseRepository.newRepo),
                    shareUseCase: ShareUseCase(repo: ShareRepository.newRepo),
                    networkMonitorUseCase: NetworkMonitorUseCase(repo: NetworkMonitorRepository.newRepo),
                    navigationController: navigationController
                ).start()
            },
            removeLink: { nodes in
                guard let nc else { return }
                let router = ActionWarningViewRouter(
                    presenter: nc,
                    nodes: nodes,
                    actionType: .removeLink,
                    onActionStart: { SVProgressHUD.show() },
                    onActionFinish: {
                        switch $0 {
                        case .success(let message):
                            SVProgressHUD.showSuccess(withStatus: message)
                        case .failure:
                            SVProgressHUD.dismiss()
                        }
                    })
                router.start()
            },
            removeSharing: { node in
                guard
                    let nc,
                    let megaNode = sdk.node(forHandle: node.handle)
                else { return }
                
                megaNode.mnz_removeSharing { [weak nc] completed in
                    if completed {
                        nc?.popViewController(animated: true)
                    }
                }
            },
            rename: { node, triggerNameChanged in
                guard
                    let nc,
                    let megaNode = sdk.node(forHandle: node.handle)
                else { return }
                megaNode.mnz_renameNode(in: nc) { request in
                    if request.name != nil {
                        triggerNameChanged()
                    }
                }
            },
            leaveSharing: { node in
                guard
                    let nc,
                    let megaNode = sdk.node(forHandle: node.handle)
                else { return }
                megaNode.mnz_leaveSharing(in: nc) { [weak nc] actionCompleted in
                    if actionCompleted {
                        nc?.popViewController(animated: true)
                    }
                }
            },
            restoreFromRubbishBin: { node in
                guard
                    let nc,
                    let megaNode = sdk.node(forHandle: node.handle)
                else { return }
                megaNode.mnz_restore()
                nc.popViewController(animated: true)
            },
            showNodeVersions: { node in
                guard
                    let nc,
                    let megaNode = sdk.node(forHandle: node.handle)
                else { return }
                megaNode.mnz_showVersions(in: nc)
            },
            remove: { node in
                guard
                    let nc,
                    let megaNode = sdk.node(forHandle: node.handle)
                else { return }
                megaNode.mnz_remove(in: nc) { [weak nc] shouldRemove in
                    if shouldRemove {
                        nc?.popViewController(animated: true)
                    }
                }
            }
        )
    }
    
}
