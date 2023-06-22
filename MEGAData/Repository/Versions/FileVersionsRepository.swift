import MEGAData
import MEGADomain

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
    
    func rootNodeFileVersionCount() -> Int64 {
#if MAIN_APP_TARGET
        guard let rootNode = sdk.rootNode,
              let count = sdk.mnz_accountDetails?.numberOfVersionFiles(forHandle: rootNode.handle) else {
            return 0
        }
        return count
#else
        return 0
#endif
    }
    
    func rootNodeFileVersionTotalSizeInBytes() -> Int64 {
#if MAIN_APP_TARGET
        guard let rootNode = sdk.rootNode,
              let size = sdk.mnz_accountDetails?.versionStorageUsed(forHandle: rootNode.handle) else {
            return 0
        }
        return size
#else
        return 0
#endif
    }

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
