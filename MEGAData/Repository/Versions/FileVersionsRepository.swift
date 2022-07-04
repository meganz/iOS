
struct FileVersionsRepository: FileVersionsRepositoryProtocol {
    
    static var newRepo: FileVersionsRepository {
        FileVersionsRepository(sdk: MEGASdkManager.sharedMEGASdk())
    }
    
    private let sdk: MEGASdk
    
    init(sdk: MEGASdk) {
        self.sdk = sdk
    }
    
    func isFileVersionsEnabled(completion: @escaping (Result<Bool, FileVersionErrorEntity>) -> Void) {
        sdk.getFileVersionsOption(with: RequestDelegate { (result) in
            switch result {
            case .success(let request):
                completion(.success(!request.flag))
            case .failure(let error):
                if error.type == .apiENoent {
                    completion(.failure(.optionNeverSet))
                } else {
                    completion(.failure(.generic))
                }
            }
        })
    }
    
    func enableFileVersions(_ enable: Bool, completion: @escaping (Result<Bool, FileVersionErrorEntity>) -> Void) {
        sdk.setFileVersionsOption(!enable, delegate: RequestDelegate { (result) in
            switch result {
            case .success(let request):
                completion(.success(!(request.text == "1")))
            case .failure:
                completion(.failure(.generic))
            }
        })
    }
    
#if MAIN_APP_TARGET
    func rootNodeFileVersionCount() -> Int64 {
        guard let rootNode = sdk.rootNode,
              let count = sdk.mnz_accountDetails?.numberOfVersionFiles(forHandle: rootNode.handle) else {
            return 0
        }
        return count
    }
    
    func rootNodeFileVersionTotalSizeInBytes() -> Int64 {
        guard let rootNode = sdk.rootNode,
              let size = sdk.mnz_accountDetails?.versionStorageUsed(forHandle: rootNode.handle) else {
            return 0
        }
        return size
    }
#endif

    func deletePreviousFileVersions(completion: @escaping (Result<Bool, FileVersionErrorEntity>) -> Void) {
        sdk.removeVersions(with: RequestDelegate { (result) in
            switch result {
            case .success:
                completion(.success(true))
            case .failure:
                completion(.failure(.generic))
            }
        })
    }
}
