import MEGADomain

public struct MockNodeValidationRepository: NodeValidationRepositoryProtocol {
    public static let newRepo: MockNodeValidationRepository = MockNodeValidationRepository()
    
    private let hasVersions: Bool
    private let isDownloaded: Bool
    private let isFile: Bool
    private let isNodeDescendant: Bool
    private let isMultimediaFile: Bool
    private let nodeInRubbishBin: NodeEntity?
    
    public init(
        hasVersions: Bool = false,
        isDownloaded: Bool = false,
        isFile: Bool = false,
        isNodeDescendant: Bool = false,
        isMultimediaFile: Bool = false,
        nodeInRubbishBin: NodeEntity? = nil
    ) {
        self.hasVersions = hasVersions
        self.isDownloaded = isDownloaded
        self.isFile = isFile
        self.isNodeDescendant = isNodeDescendant
        self.isMultimediaFile = isMultimediaFile
        self.nodeInRubbishBin = nodeInRubbishBin
    }
    
    public func hasVersions(nodeHandle: HandleEntity) -> Bool {
        hasVersions
    }
    
    public func isDownloaded(nodeHandle: HandleEntity) -> Bool {
        isDownloaded
    }
    
    public func isInRubbishBin(nodeHandle: HandleEntity) -> Bool {
        nodeInRubbishBin?.handle == nodeHandle
    }
    
    public func isFileNode(handle: HandleEntity) -> Bool {
        isFile
    }
    
    public func isNode(_ node: NodeEntity, descendantOf ancestor: NodeEntity) async -> Bool {
        isNodeDescendant
    }
}
