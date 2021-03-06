import Foundation

protocol NodeLabelActionUseCaseProtocol {

    var labelColors: [NodeLabelColor] { get }

    func setNodeLabelColor(
        _ labelColor: NodeLabelColor,
        forNode nodeHandle: MEGAHandle,
        completion: ((Result<Void, NodeLabelActionDomainError>) -> Void)?
    )

    func resetNodeLabelColor(
        forNode nodeHandle: MEGAHandle,
        completion: ((Result<Void, NodeLabelActionDomainError>) -> Void)?
    )

    func nodeLabelColor(
        forNode nodeHandle: MEGAHandle,
        completion: ((Result<NodeLabelColor, NodeLabelActionDomainError>) -> Void)?
    )
}

final class NodeLabelActionUseCase: NodeLabelActionUseCaseProtocol {


    private let nodeLabelActionRepository: NodeLabelActionRepositoryProtocol

    init(nodeLabelActionRepository: NodeLabelActionRepositoryProtocol) {
        self.nodeLabelActionRepository = nodeLabelActionRepository
    }

    var labelColors: [NodeLabelColor] {
        nodeLabelActionRepository.labelColors
    }

    func nodeLabelColor(forNode nodeHandle: MEGAHandle,
                        completion: ((Result<NodeLabelColor, NodeLabelActionDomainError>) -> Void)?) {
        nodeLabelActionRepository.nodeLabelColor(forNode: nodeHandle, completion: completion)
    }

    func setNodeLabelColor(
        _ labelColor: NodeLabelColor,
        forNode nodeHandle: MEGAHandle,
        completion: ((Result<Void, NodeLabelActionDomainError>) -> Void)?
    ) {
        nodeLabelActionRepository.setNodeLabelColor(labelColor, forNode: nodeHandle, completion: completion)
    }

    func resetNodeLabelColor(
        forNode nodeHandle: MEGAHandle,
        completion: ((Result<Void, NodeLabelActionDomainError>) -> Void)?
    ) {
        nodeLabelActionRepository.resetNodeLabelColor(forNode: nodeHandle, completion: completion ?? { _ in })
    }
}

enum NodeLabelActionDomainError: Error {

    case nodeNotFound

    case sdkError(MEGASDKErrorType)

    case unsupportedNodeLabelColorFound
}
