import MEGADomain

public final class MockNodeDataUseCase: NodeUseCaseProtocol {
    private let nodeAccessLevelVariable: NodeAccessTypeEntity
    private let labelString: String
    private let filesAndFolders: (Int, Int)
    private let versions: Bool
    private let downloaded: Bool
    private let inRubbishBin: Bool
    private var multimediaNodes: [NodeEntity]
    
    public var isMultimediaFileNode_CalledTimes = 0
    
    public init(nodeAccessLevelVariable: NodeAccessTypeEntity = .unknown,
                labelString: String = "",
                filesAndFolders: (Int, Int) = (0, 0),
                versions: Bool = false,
                downloaded: Bool = false,
                inRubbishBin: Bool = false,
                multimediaNodes: [NodeEntity] = []) {
        self.nodeAccessLevelVariable = nodeAccessLevelVariable
        self.labelString = labelString
        self.filesAndFolders = filesAndFolders
        self.versions = versions
        self.downloaded = downloaded
        self.inRubbishBin = inRubbishBin
        self.multimediaNodes = multimediaNodes
    }
    
    public func nodeAccessLevel(nodeHandle: HandleEntity) -> NodeAccessTypeEntity {
        return nodeAccessLevelVariable
    }
    
    public func nodeAccessLevelAsync(nodeHandle: HandleEntity) async -> NodeAccessTypeEntity {
        nodeAccessLevelVariable
    }
    
    public func downloadToOffline(nodeHandle: HandleEntity) { }
    
    public func labelString(label: NodeLabelTypeEntity) -> String {
        labelString
    }
    
    public func getFilesAndFolders(nodeHandle: HandleEntity) -> (childFileCount: Int, childFolderCount: Int) {
        filesAndFolders
    }
    
    public func hasVersions(nodeHandle: HandleEntity) -> Bool {
        versions
    }
    
    public func isDownloaded(nodeHandle: HandleEntity) -> Bool {
        downloaded
    }
    
    public func isInRubbishBin(nodeHandle: HandleEntity) -> Bool {
        inRubbishBin
    }
}
