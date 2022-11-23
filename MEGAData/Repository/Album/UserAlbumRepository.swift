import MEGADomain

struct UserAlbumRepository: UserAlbumRepositoryProtocol {
    static var newRepo: UserAlbumRepository {
        UserAlbumRepository(sdk: MEGASdkManager.sharedMEGASdk())
    }
    
    private let sdk: MEGASdk
    
    init(sdk: MEGASdk) {
        self.sdk = sdk
    }
    
    // MARK: - Albums
    func albums() async -> [SetEntity] {
        let megaSets = sdk.megaSets()
        return megaSets.toSetEntities()
    }
    
    func albumContent(by id: HandleEntity) async -> [SetElementEntity] {
        let megaSetElements = sdk.megaSetElements(bySid: id)
        let elements = megaSetElements.toSetElementsEntities()
        
        return elements
    }
    
    func createAlbum(_ name: String?) async throws -> SetEntity {
        return try await withCheckedThrowingContinuation { continuation in
            sdk.createSet(name, delegate: RequestDelegate { result in
                guard Task.isCancelled == false else { continuation.resume(throwing: AlbumErrorEntity.generic); return }
                
                switch result {
                case .success(let request):
                    guard let set = request.set else {
                        continuation.resume(throwing: AlbumErrorEntity.generic)
                        return
                    }
                    
                    continuation.resume(returning: set.toSetEntity())
                case .failure(_):
                    continuation.resume(throwing: AlbumErrorEntity.generic)
                }
            })
        }
    }
    
    func updateAlbumName(_ name: String, _ id: HandleEntity) async throws -> String {
        return try await withCheckedThrowingContinuation { continuation in
            sdk.updateSetName(id, name: name, delegate: RequestDelegate { result in
                guard Task.isCancelled == false else { continuation.resume(throwing: AlbumErrorEntity.generic); return }
                
                switch result {
                case .success(let request):
                    continuation.resume(returning: request.text ?? "")
                case .failure(_):
                    continuation.resume(throwing: AlbumErrorEntity.generic)
                }
            })
        }
    }
    
    func deleteAlbum(by id: HandleEntity) async throws -> HandleEntity {
        return try await withCheckedThrowingContinuation { continuation in
            sdk.removeSet(id, delegate: RequestDelegate { result in
                guard Task.isCancelled == false else { continuation.resume(throwing: AlbumErrorEntity.generic); return }
                
                switch result {
                case .success(let request):
                    continuation.resume(returning: request.parentHandle)
                case .failure(_):
                    continuation.resume(throwing: AlbumErrorEntity.generic)
                }
            })
        }
    }
}
