
struct MockFileVersionsRepository: FileVersionsRepositoryProtocol {
    static let newRepo = MockFileVersionsRepository()
    
    var versions: Int64 = 0
    var versionsSize: Int64 = 0
    var isFileVersionsEnabled: (Result<Bool, FileVersionErrorEntity>) = .failure(.generic)
    var enableFileVersions: (Result<Bool, FileVersionErrorEntity>) = .failure(.generic)
    var deletePreviousFileVersions: (Result<Bool, FileVersionErrorEntity>) = .failure(.generic)
    
    func isFileVersionsEnabled(completion: @escaping (Result<Bool, FileVersionErrorEntity>) -> Void) {
        completion(isFileVersionsEnabled)
    }
    
    func enableFileVersions(_ enable: Bool, completion: @escaping (Result<Bool, FileVersionErrorEntity>) -> Void) {
        completion(enableFileVersions)
    }
    
    func rootNodeFileVersionCount() -> Int64 {
        versions
    }
    
    func rootNodeFileVersionTotalSizeInBytes() -> Int64 {
        versionsSize
    }
    
    func deletePreviousFileVersions(completion: @escaping (Result<Bool, FileVersionErrorEntity>) -> Void) {
        completion(deletePreviousFileVersions)
    }
}

