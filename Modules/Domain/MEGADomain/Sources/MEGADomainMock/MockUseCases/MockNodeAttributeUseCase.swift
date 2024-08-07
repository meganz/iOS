import MEGADomain

public struct MockNodeAttributeUseCase: NodeAttributeUseCaseProtocol {
    
    private let pathForNodes: [NodeEntity: String]
    private let numberChildrenForNodes: [NodeEntity: Int]
    private let isInRubbishBinForNodes: [NodeEntity: Bool]
    
    public init(pathForNodes: [NodeEntity: String] = [:],
                numberChildrenForNodes: [NodeEntity: Int] = [:],
                isInRubbishBinForNodes: [NodeEntity: Bool] = [:]) {
        self.pathForNodes = pathForNodes
        self.numberChildrenForNodes = numberChildrenForNodes
        self.isInRubbishBinForNodes = isInRubbishBinForNodes
    }
    
    public func pathFor(node: NodeEntity) -> String? {
        pathForNodes[node]
    }
    
    public func numberChildrenFor(node: NodeEntity) -> Int {
        numberChildrenForNodes[node] ?? -1
    }
    
    public func isInRubbishBin(node: NodeEntity) -> Bool {
        isInRubbishBinForNodes[node] ?? false
    }
}
