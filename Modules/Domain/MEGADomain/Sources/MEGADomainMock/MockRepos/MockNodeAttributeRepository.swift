import MEGADomain

public struct MockNodeAttributeRepository: NodeAttributeRepositoryProtocol {
    public static let newRepo: MockNodeAttributeRepository = MockNodeAttributeRepository()
    
    private let path: String?
    private let children: Int
    private let isInRubbishBin: Bool
    
    public init(path: String? = nil, children: Int = 0, isInRubbishBin: Bool = false) {
        self.path = path
        self.children = children
        self.isInRubbishBin = isInRubbishBin
    }
    
    public func pathFor(node: MEGADomain.NodeEntity) -> String? {
        path
    }
    
    public func numberChildrenFor(node: MEGADomain.NodeEntity) -> Int {
        children
    }
    
    public func isInRubbishBin(node: MEGADomain.NodeEntity) -> Bool {
        isInRubbishBin
    }
}
