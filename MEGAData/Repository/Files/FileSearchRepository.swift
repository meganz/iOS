import MEGADomain

final class FileSearchRepository: NSObject, FileSearchRepositoryProtocol {
    static var newRepo: FileSearchRepository {
        FileSearchRepository(sdk: MEGASdkManager.sharedMEGASdk())
    }
    
    private let sdk: MEGASdk
    
    private var cancelToken: MEGACancelToken?
    private var callback: (([NodeEntity]) -> Void)?
    
    init(sdk: MEGASdk) {
        self.sdk = sdk
    }
    
    // MARK: - Protocols
    public func allPhotos() async throws -> [NodeEntity] {
        try await rootNodeSearch(for: .photo)
    }
    
    func allVideos() async throws -> [NodeEntity] {
        try await rootNodeSearch(for: .video)
    }
    
    func startMonitoringNodesUpdate(callback: @escaping ([NodeEntity]) -> Void) {
        self.callback = callback
        sdk.add(self)
    }
    
    func stopMonitoringNodesUpdate() {
        sdk.remove(self)
    }
    
    //MARK: - Private
    private func rootNodeSearch(for nodeFormatType: MEGANodeFormatType) async throws -> [NodeEntity] {
        return try await withCheckedThrowingContinuation { continuation in
            guard Task.isCancelled == false else { continuation.resume(throwing: FileSearchResultErrorEntity.generic); return }
            
            cancelToken = MEGACancelToken()
            
            guard let cancelToken, let rootNode = sdk.rootNode
            else {
                return continuation.resume(throwing: FileSearchResultErrorEntity.noDataAvailable)
            }
            
            let nodeList = sdk.nodeListSearch(
                for: rootNode,
                search: "",
                cancelToken: cancelToken,
                recursive: true,
                orderType: .modificationDesc,
                nodeFormatType: nodeFormatType,
                folderTargetType: .rootNode
            )
            
            continuation.resume(returning: nodeList.toNodeEntities())
        }
    }
    
    func fetchNode(by id: HandleEntity) async -> NodeEntity? {
        sdk.node(forHandle: id)?.toNodeEntity()
    }
}

extension FileSearchRepository: MEGAGlobalDelegate {
    func onNodesUpdate(_ api: MEGASdk, nodeList: MEGANodeList?) {
        callback?(nodeList?.toNodeEntities() ?? [])
    }
}
