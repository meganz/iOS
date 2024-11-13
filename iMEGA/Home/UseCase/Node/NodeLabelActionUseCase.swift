import Foundation
import MEGADomain

protocol NodeLabelActionUseCaseProtocol {

    var labelColors: [NodeLabelColor] { get }

    func setNodeLabelColor(
        _ labelColor: NodeLabelColor,
        forNode nodeHandle: HandleEntity,
        completion: ((Result<Void, NodeLabelActionDomainError>) -> Void)?
    )

    func resetNodeLabelColor(
        forNode nodeHandle: HandleEntity,
        completion: ((Result<Void, NodeLabelActionDomainError>) -> Void)?
    )

    func nodeLabelColor(
        forNode nodeHandle: HandleEntity,
        completion: ((Result<NodeLabelColor, NodeLabelActionDomainError>) -> Void)?
    )
}

final class NodeLabelActionUseCase: NodeLabelActionUseCaseProtocol {

    private let nodeLabelActionRepository: any NodeLabelActionRepositoryProtocol

    init(nodeLabelActionRepository: some NodeLabelActionRepositoryProtocol) {
        self.nodeLabelActionRepository = nodeLabelActionRepository
    }

    var labelColors: [NodeLabelColor] {
        nodeLabelActionRepository.labelColors
    }

    func nodeLabelColor(forNode nodeHandle: HandleEntity,
                        completion: ((Result<NodeLabelColor, NodeLabelActionDomainError>) -> Void)?) {
        nodeLabelActionRepository.nodeLabelColor(forNode: nodeHandle, completion: completion)
    }

    func setNodeLabelColor(
        _ labelColor: NodeLabelColor,
        forNode nodeHandle: HandleEntity,
        completion: ((Result<Void, NodeLabelActionDomainError>) -> Void)?
    ) {
        nodeLabelActionRepository.setNodeLabelColor(labelColor, forNode: nodeHandle, completion: completion)
    }

    func resetNodeLabelColor(
        forNode nodeHandle: HandleEntity,
        completion: ((Result<Void, NodeLabelActionDomainError>) -> Void)?
    ) {
        nodeLabelActionRepository.resetNodeLabelColor(forNode: nodeHandle, completion: completion)
    }
}

enum NodeLabelActionDomainError: Error {

    case nodeNotFound

    case sdkError(MEGASDKErrorType)

    case unsupportedNodeLabelColorFound
}
