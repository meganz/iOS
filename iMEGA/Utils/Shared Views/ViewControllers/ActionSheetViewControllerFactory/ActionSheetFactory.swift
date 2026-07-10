import Foundation
import MEGAAssets
import MEGADomain
import MEGAL10n

@MainActor
protocol ActionSheetFactoryProtocol {

    func nodeLabelColorView(forNode nodeHandle: HandleEntity,
                            completion: ((Result<ActionSheetViewController, NodeLabelActionDomainError>) -> Void)?)

    func nodeLabelColorView(forNodes nodeHandles: [HandleEntity]) -> ActionSheetViewController
}

struct ActionSheetFactory: ActionSheetFactoryProtocol {

    private let nodeLabelActionUseCase: any NodeLabelActionUseCaseProtocol

    init(
        nodeLabelActionUseCase: some NodeLabelActionUseCaseProtocol
            = NodeLabelActionUseCase(nodeLabelActionRepository: NodeLabelActionRepository())
    ) {
        self.nodeLabelActionUseCase = nodeLabelActionUseCase
    }

    func nodeLabelColorView(forNode nodeHandle: HandleEntity,
                            completion: ((Result<ActionSheetViewController, NodeLabelActionDomainError>) -> Void)?) {
        nodeLabelColorActions(forNode: nodeHandle) { (actionsResult) in
            let viewControllerResult = actionsResult.map {
                ActionSheetViewController(actions: $0, headerTitle: nil, dismissCompletion: nil, sender: nil)
            }
            completion?(viewControllerResult)
        }
    }

    /// Builds a label-colour picker that applies the chosen colour (or clears it) to every node.
    /// There is no current-colour checkmark since the selection may hold nodes with different labels, and
    /// "Remove label" (`.unknown`) is only offered when at least one selected node is currently labelled —
    /// matching the single-node picker's behaviour.
    func nodeLabelColorView(forNodes nodeHandles: [HandleEntity]) -> ActionSheetViewController {
        let selectionContainsLabelledNode = nodeHandles.contains { isNodeLabelled(forNode: $0) }
        let actions = nodeLabelActionUseCase.labelColors
            .filter { $0 != .unknown || selectionContainsLabelledNode }
            .map { color -> BaseAction in
                ActionSheetAction(
                    title: color.localizedTitle,
                    detail: nil,
                    accessoryView: nil,
                    image: color.iconImage,
                    style: (color != .unknown) ? .default : .destructive,
                    actionHandler: { [nodeLabelActionUseCase] in
                        nodeHandles.forEach { nodeHandle in
                            if color == .unknown {
                                nodeLabelActionUseCase.resetNodeLabelColor(forNode: nodeHandle, completion: nil)
                            } else {
                                nodeLabelActionUseCase.setNodeLabelColor(color, forNode: nodeHandle, completion: nil)
                            }
                        }
                    }
                )
            }
        return ActionSheetViewController(actions: actions, headerTitle: nil, dismissCompletion: nil, sender: nil)
    }

    private func isNodeLabelled(forNode nodeHandle: HandleEntity) -> Bool {
        var isLabelled = false
        // nodeLabelColor(forNode:) resolves its completion synchronously (it just reads the node's label).
        nodeLabelActionUseCase.nodeLabelColor(forNode: nodeHandle) { result in
            if case .success(let color) = result {
                isLabelled = color != .unknown
            }
        }
        return isLabelled
    }

    private func nodeLabelColorActions(
        forNode nodeHandle: HandleEntity,
        completion: ((Result<[BaseAction], NodeLabelActionDomainError>) -> Void)?
    ) {
        nodeLabelActionUseCase.nodeLabelColor(forNode: nodeHandle) { (colorResult) in
            switch colorResult {
            case .failure(let error):
                completion?(.failure(error))
            case .success(let nodeCurrentColor):
                let allLabelColors = nodeLabelActionUseCase.labelColors
                let actionSheetActions = allLabelColors.compactMap { (color) -> BaseAction? in
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
        forNode nodeHandle: HandleEntity,
        ofColor labelColor: NodeLabelColor,
        currentLabelColor: NodeLabelColor
    ) -> BaseAction? {
        switch labelColor == currentLabelColor {
        case true:
            if currentLabelColor == .unknown {
                return nil
            } else {
                let checkMarkImageView = UIImageView.init(image: MEGAAssets.UIImage.turquoiseCheckmark)
                return ActionSheetAction(
                    title: labelColor.localizedTitle,
                    detail: nil,
                    accessoryView: checkMarkImageView,
                    image: labelColor.iconImage,
                    style: .default,
                    actionHandler: { [nodeLabelActionUseCase] in
                        nodeLabelActionUseCase.resetNodeLabelColor(forNode: nodeHandle, completion: nil)
                    }
                )
            }
        case false:
            return ActionSheetAction(
                title: labelColor.localizedTitle,
                detail: nil,
                accessoryView: nil,
                image: labelColor.iconImage,
                style: (labelColor != .unknown) ? .default : .destructive,
                actionHandler: { [nodeLabelActionUseCase] in
                    nodeLabelActionUseCase.setNodeLabelColor(labelColor, forNode: nodeHandle, completion: nil)
                }
            )
        }
    }
}

private extension NodeLabelColor {

    var iconImage: UIImage {
        switch self {
        case .red:
            return MEGAAssets.UIImage.red
        case .orange:
            return MEGAAssets.UIImage.orange
        case .yellow:
            return MEGAAssets.UIImage.yellow
        case .green:
            return MEGAAssets.UIImage.green
        case .blue:
            return MEGAAssets.UIImage.blue
        case .purple:
            return MEGAAssets.UIImage.purple
        case .grey:
            return MEGAAssets.UIImage.grey
        case .unknown:
            return MEGAAssets.UIImage.delete
        }
    }

    var localizedTitle: String {
        switch self {
        case .red:
            return Strings.Localizable.red
        case .orange:
            return Strings.Localizable.orange
        case .yellow:
            return Strings.Localizable.yellow
        case .green:
            return Strings.Localizable.green
        case .blue:
            return Strings.Localizable.blue
        case .purple:
            return Strings.Localizable.purple
        case .grey:
            return Strings.Localizable.grey
        case .unknown:
            return Strings.Localizable.removeLabel
        }
    }
}
