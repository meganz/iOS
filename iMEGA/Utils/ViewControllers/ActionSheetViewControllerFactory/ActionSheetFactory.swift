import Foundation

protocol ActionSheetFactoryProtocol {

    func nodeLabelColorView(forNode nodeHandle: MEGAHandle,
                            completion:((Result<ActionSheetViewController, NodeLabelActionError>) -> Void)?)
}

struct ActionSheetFactory: ActionSheetFactoryProtocol {

    private let nodeLabelActionUseCase: NodeLabelActionUseCaseProtocol

    init(
        nodeLabelActionUseCase: NodeLabelActionUseCaseProtocol
            = NodeLabelActionUseCase(nodeLabelActionRepository:NodeLabelActionRepository())
    ) {
        self.nodeLabelActionUseCase = nodeLabelActionUseCase
    }

    func nodeLabelColorView(forNode nodeHandle: MEGAHandle,
                            completion:((Result<ActionSheetViewController, NodeLabelActionError>) -> Void)?) {
        nodeLabelColorActions(forNode: nodeHandle) { (actionsResult) in
            let viewControllerResult = actionsResult.map {
                ActionSheetViewController(actions: $0, headerTitle: nil, dismissCompletion: nil, sender: nil)
            }
            completion?(viewControllerResult)
        }
    }

    private func nodeLabelColorActions(
        forNode nodeHandle: MEGAHandle,
        completion:((Result<[BaseAction], NodeLabelActionError>) -> Void)?
    ) {
        nodeLabelActionUseCase.nodeLabelColor(forNode: nodeHandle) { (colorResult) in
            switch colorResult {
            case .failure(let error):
                completion?(.failure(NodeLabelActionError(error)))
            case .success(let nodeCurrentColor):
                let allLabelColors = nodeLabelActionUseCase.labelColors
                let actionSheetActions = allLabelColors.map { (color) -> BaseAction in
                    nodeLabelActions(
                        forNode: nodeHandle,
                        ofColor: color,
                        currentLabelColor: nodeCurrentColor
                    )
                }
                completion?(.success(actionSheetActions))
            }
        }
    }

    private func nodeLabelActions(
        forNode nodeHandle: MEGAHandle,
        ofColor labelColor: NodeLabelColor,
        currentLabelColor: NodeLabelColor
    ) -> BaseAction {
        switch labelColor == currentLabelColor {
        case true:
            let checkMarkImageView = UIImage(named: "turquoise_checkmark")
            return ActionSheetAction(
                title: labelColor.localizedTitle,
                detail: nil,
                accessoryView: nil,
                image: checkMarkImageView,
                style: .default,
                actionHandler: { [nodeLabelActionUseCase] in
                    nodeLabelActionUseCase.resetNodeLabelColor(forNode: nodeHandle, completion: nil)
                }
            )
        case false:
            return ActionSheetAction(
                title: labelColor.localizedTitle,
                detail: nil,
                accessoryView: nil,
                image: labelColor.iconImage,
                style: .default,
                actionHandler: { [nodeLabelActionUseCase] in
                    nodeLabelActionUseCase.setNodeLabelColor(labelColor, forNode: nodeHandle, completion: nil)
                }
            )
        }
    }
}

enum NodeLabelActionError: Error {

    case nodeNotFound

    case unsupportedNodeLabelColorFound

    case internalGeneric

    init(_ domainError: NodeLabelActionDomainError) {
        switch domainError {
        case .nodeNotFound: self = .nodeNotFound
        case .unsupportedNodeLabelColorFound: self = .unsupportedNodeLabelColorFound
        case .sdkError: self = .internalGeneric
        }
    }
}

private extension NodeLabelColor {

    var iconImage: UIImage {
        switch self {
        case .red:
            return UIImage(named: "Red")!
        case .orange:
            return UIImage(named: "Orange")!
        case .yellow:
            return UIImage(named: "Yellow")!
        case .green:
            return UIImage(named: "Green")!
        case .blue:
            return UIImage(named: "Blue")!
        case .purple:
            return UIImage(named: "Purple")!
        case .grey:
            return UIImage(named: "Grey")!
        case .unknown:
            return UIImage(named: "delete")!
        }
    }

    var localizedTitle: String {
        switch self {
        case .red:
            return NSLocalizedString("Red", comment: "A user can mark a folder or file with its own colour, in this case “Red”.")
        case .orange:
            return NSLocalizedString("Orange", comment: "A user can mark a folder or file with its own colour, in this case “Orange”.")
        case .yellow:
            return NSLocalizedString("Yellow", comment: "A user can mark a folder or file with its own colour, in this case “Yellow”.")
        case .green:
            return NSLocalizedString("Green", comment: "A user can mark a folder or file with its own colour, in this case “Green”.")
        case .blue:
            return NSLocalizedString("Blue", comment: "A user can mark a folder or file with its own colour, in this case “Blue”.")
        case .purple:
            return NSLocalizedString("Purple", comment: "A user can mark a folder or file with its own colour, in this case “Purple”.")
        case .grey:
            return NSLocalizedString("Grey", comment: "A user can mark a folder or file with its own colour, in this case “Grey”.")
        case .unknown:
            return NSLocalizedString("Remove Label", comment: "Option shown on the action sheet where you can choose or change the color label of a file or folder. The 'Remove Label' only appears if you have previously selected a label")
        }
    }
}
