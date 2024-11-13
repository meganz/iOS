@testable import MEGA
import MEGADomain

final class MockNodeLabelActionRepository: NodeLabelActionRepositoryProtocol {
    private let _labelColors: [NodeLabelColor]
    private let setNodeLabelColorResult: Result<Void, NodeLabelActionDomainError>
    private let resetNodeLabelColorResult: Result<Void, NodeLabelActionDomainError>
    private let nodeLabelColorResult: Result<NodeLabelColor, NodeLabelActionDomainError>
    
    init(
        labelColors: [NodeLabelColor] = [],
        setNodeLabelColorResult: Result<Void, NodeLabelActionDomainError> = .success,
        resetNodeLabelColorResult: Result<Void, NodeLabelActionDomainError> = .success,
        nodeLabelColorResult: Result<NodeLabelColor, NodeLabelActionDomainError> = .success(.unknown)
    ) {
        _labelColors = labelColors
        self.setNodeLabelColorResult = setNodeLabelColorResult
        self.resetNodeLabelColorResult = resetNodeLabelColorResult
        self.nodeLabelColorResult = nodeLabelColorResult
    }
    
    var labelColors: [NodeLabelColor] { _labelColors }
    
    func setNodeLabelColor(
        _ labelColor: NodeLabelColor,
        forNode nodeHandle: HandleEntity,
        completion: ((Result<Void, NodeLabelActionDomainError>) -> Void)?
    ) {
        completion?(setNodeLabelColorResult)
    }
    
    func resetNodeLabelColor(
        forNode nodeHandle: HandleEntity,
        completion: ((Result<Void, NodeLabelActionDomainError>) -> Void)?
    ) {
        completion?(resetNodeLabelColorResult)
    }
    
    func nodeLabelColor(
        forNode nodeHandle: HandleEntity,
        completion: ((Result<NodeLabelColor, NodeLabelActionDomainError>) -> Void)?
    ) {
        completion?(nodeLabelColorResult)
    }
}
