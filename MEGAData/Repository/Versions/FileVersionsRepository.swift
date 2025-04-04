import MEGAAppSDKRepo
import MEGADomain
import MEGASdk
import MEGASwift

struct FileVersionsRepository: FileVersionsRepositoryProtocol {
    
    static var newRepo: FileVersionsRepository {
        FileVersionsRepository(sdk: .shared)
    }
    
    private let sdk: MEGASdk
    
    init(sdk: MEGASdk) {
        self.sdk = sdk
    }
    
    func isFileVersionsEnabled() async throws -> Bool {
        try await withAsyncThrowingValue { completion in
            isFileVersionsEnabled { result in
                switch result {
                case .success(let value):
                    completion(.success(value))
                case .failure(let error):
                    completion(.failure(error))
                }
            }
        }
    }
    
    private func isFileVersionsEnabled(completion: @escaping (Result<Bool, FileVersionErrorEntity>) -> Void) {
        sdk.getFileVersionsOption(with: RequestDelegate { result in
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
    
    func enableFileVersions(_ enable: Bool) async throws -> Bool {
        try await withAsyncThrowingValue { completion in
            enableFileVersions(enable) { result in
                switch result {
                case .success(let value):
                    completion(.success(value))
                case .failure(let error):
                    completion(.failure(error))
                }
            }
        }
    }
    
    private func enableFileVersions(_ enable: Bool, completion: @escaping (Result<Bool, FileVersionErrorEntity>) -> Void) {
        sdk.setFileVersionsOption(!enable, delegate: RequestDelegate { result in
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
    
    func deletePreviousFileVersions() async throws -> Bool {
        try await withAsyncThrowingValue { completion in
            deletePreviousFileVersions { result in
                switch result {
                case .success(let value):
                    completion(.success(value))
                case .failure(let error):
                    completion(.failure(error))
                }
            }
        }
    }

    private func deletePreviousFileVersions(completion: @escaping (Result<Bool, FileVersionErrorEntity>) -> Void) {
        sdk.removeVersions(with: RequestDelegate { result in
            switch result {
            case .success:
                completion(.success(true))
            case .failure:
                completion(.failure(.generic))
            }
        })
    }
}
