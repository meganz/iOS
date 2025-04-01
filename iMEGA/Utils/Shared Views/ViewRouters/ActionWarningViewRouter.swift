import MEGAAppPresentation
import MEGADomain
import MEGAL10n
import MEGASDKRepo

final class ActionWarningViewRouter: NSObject, Routing {
    private weak var presenter: UIViewController?
    private var actionType: MegaNodeActionType
    private var nodes: [NodeEntity]
    private var onActionStart: () -> Void
    private var onActionFinish: (Result<String, RemoveLinkErrorEntity>) -> Void
    private var title: String = ""
    private var message: String = ""
    private var mainActionTitle: String = ""
    private var mainActionClosure: () -> Void = {}
    
    init(presenter: UIViewController, nodes: [NodeEntity], actionType: MegaNodeActionType, onActionStart: @escaping () -> Void, onActionFinish: @escaping (Result<String, RemoveLinkErrorEntity>) -> Void) {
        self.presenter = presenter
        self.actionType = actionType
        self.nodes = nodes
        self.onActionStart = onActionStart
        self.onActionFinish = onActionFinish
        
        super.init()
        
        configureWarning()
    }
    
    func build() -> UIViewController {
        let alertController = UIAlertController(title: title,
                                      message: message,
                                      preferredStyle: .alert)
        let continueAction = UIAlertAction(title: mainActionTitle, style: .default) { [weak self] _ in
            self?.mainActionClosure()
        }
        alertController.addAction(continueAction)
        alertController.addAction(UIAlertAction(title: Strings.Localizable.cancel, style: .cancel))
        alertController.preferredAction = continueAction
        
        return alertController
    }
    
    func start() {
        presenter?.present(build(), animated: true, completion: nil)
    }
    
    func configureWarning() {
        switch actionType {
        case .removeLink:
            let nodesCount = nodes.filter {$0.isExported}.count

            title = Strings.Localizable.General.MenuAction.RemoveLink.DoubleCheck.Warning.title(nodesCount)
            message = Strings.Localizable.General.MenuAction.RemoveLink.DoubleCheck.Warning.message(nodesCount)
            mainActionTitle = Strings.Localizable.remove
            mainActionClosure = {
                Task { @MainActor in
                    self.onActionStart()
                    let nodeActionUseCase = NodeActionUseCase(repo: NodeActionRepository.newRepo)
                    do {
                        try await nodeActionUseCase.removeLink(nodes: self.nodes)
                        self.onActionFinish(.success(Strings.Localizable.General.MenuAction.RemoveLink.Message.success(nodesCount)))
                    } catch {
                        if let removeLinkError = error as? RemoveLinkErrorEntity {
                            self.onActionFinish(.failure(removeLinkError))
                        } else {
                            self.onActionFinish(.failure(RemoveLinkErrorEntity.generic))
                        }
                    }
                }
            }
        default: break
        }
    }
}
