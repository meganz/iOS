struct NodeThumbnailRepository: NodeThumbnailRepositoryProtocol {
    private let sdk: MEGASdk
    private let nodeHandle: MEGAHandle
    
    init(sdk: MEGASdk, nodeHandle: MEGAHandle) {
        self.sdk = sdk
        self.nodeHandle = nodeHandle
    }
    
    func getThumbnailFilePath(base64Handle: String) -> String {
        return Helper.path(forHandle: base64Handle, inSharedSandboxCacheDirectory: "thumbnailsV3")
    }
    
    func isThumbnailDownloaded(thumbnailFilePath: String) -> Bool {
        return FileManager.default.fileExists(atPath: thumbnailFilePath)
    }
    
    func getThumbnail(destinationFilePath: String, completion: @escaping (Result<String, GetThumbnailErrorEntity>) -> Void) {
        guard let node = sdk.node(forHandle: nodeHandle) else {
            completion(.failure(GetThumbnailErrorEntity.nodeNotFound))
            return
        }
        
        let getThumbnailRequestDelegate = MEGAGenericRequestDelegate { request, error  in
            if error.type == .apiOk {
                completion(.success(request.file))
            } else {
                let getThumbnailErrorEntity: GetThumbnailErrorEntity
                if error.type == .apiENoent {
                    getThumbnailErrorEntity = .noThumbnail
                } else {
                    getThumbnailErrorEntity = .generic
                }
                completion(.failure(getThumbnailErrorEntity))
            }
        }
        sdk.getThumbnailNode(node, destinationFilePath: destinationFilePath, delegate: getThumbnailRequestDelegate)
    }
    
    func iconImagesDictionary() -> [String : String] {
        return Helper.fileTypesDictionary() as? [String: String] ?? [:]
    }
}
