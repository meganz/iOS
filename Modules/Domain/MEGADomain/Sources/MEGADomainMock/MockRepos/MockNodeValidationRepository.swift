import MEGADomain

public struct MockNodeValidationRepository: NodeValidationRepositoryProtocol {
    public static var newRepo: MockNodeValidationRepository = MockNodeValidationRepository()
    
    private let hasVersions: Bool
    private let isDownloaded: Bool
    private let isInRubbishBin: Bool
    private let isFile: Bool
    private let isNodeDescendant: Bool
    private let isMultimediaFile: Bool
    
    public init(hasVersions: Bool = false, isDownloaded: Bool = false, isInRubbishBin: Bool = false, isFile: Bool = false, isNodeDescendant: Bool = false, isMultimediaFile: Bool = false) {
        self.hasVersions = hasVersions
        self.isDownloaded = isDownloaded
        self.isInRubbishBin = isInRubbishBin
        self.isFile = isFile
        self.isNodeDescendant = isNodeDescendant
        self.isMultimediaFile = isMultimediaFile
    }
    
    public func hasVersions(nodeHandle: HandleEntity) -> Bool {
        hasVersions
    }
    
    public func isDownloaded(nodeHandle: HandleEntity) -> Bool {
        isDownloaded
    }
    
    public func isInRubbishBin(nodeHandle: HandleEntity) -> Bool {
        isInRubbishBin
    }
    
    public func isFileNode(handle: HandleEntity) -> Bool {
        isFile
    }
    
    public func isNode(_ node: NodeEntity, descendantOf ancestor: NodeEntity) async -> Bool {
        isNodeDescendant
    }
}
