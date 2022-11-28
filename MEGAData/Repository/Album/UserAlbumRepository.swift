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
    
    // MARK: - Album Content
    func addPhotosToAlbum(by id: HandleEntity, nodes: [NodeEntity]) async throws -> AlbumElementsResultEntity {
        guard nodes.isNotEmpty else { return AlbumElementsResultEntity(success: 0, failure: 0) }
        
        return try await withCheckedThrowingContinuation { continuation in
            let requestDelegate = AlbumElementRequestDelegate(numberOfCalls: nodes.count) { result in
                guard Task.isCancelled == false else { continuation.resume(throwing: AlbumErrorEntity.generic); return }
                
                switch result {
                case .success(let result):
                    let entity = AlbumElementsResultEntity(success:result.0, failure: result.1)
                    continuation.resume(returning:entity)
                case .failure(_):
                    continuation.resume(throwing: AlbumErrorEntity.generic)
                }
            }
            
            for node in nodes {
                sdk.createSetElement(id, nodeId: node.id, name: "", delegate: requestDelegate)
            }
        }
    }
    
    func updateAlbumElementName(albumId: HandleEntity, elementId: HandleEntity, name: String) async throws -> String {
        return try await withCheckedThrowingContinuation { continuation in
            sdk.updateSetElement(albumId, eid: elementId, name: name, delegate: RequestDelegate { result in
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
    
    func updateAlbumElementOrder(albumId: HandleEntity, elementId: HandleEntity, order: Int64) async throws -> Int64 {
        return try await withCheckedThrowingContinuation { continuation in
            sdk.updateSetElementOrder(albumId, eid: elementId, order: order, delegate: RequestDelegate { result in
                guard Task.isCancelled == false else { continuation.resume(throwing: AlbumErrorEntity.generic); return }
                
                switch result {
                case .success(let request):
                    continuation.resume(returning: request.number.int64Value)
                case .failure(_):
                    continuation.resume(throwing: AlbumErrorEntity.generic)
                }
            })
        }
    }
    
    func deleteAlbumElements(albumId: HandleEntity, elementIds: [HandleEntity]) async throws -> AlbumElementsResultEntity {
        guard elementIds.isNotEmpty else { return AlbumElementsResultEntity(success: 0, failure: 0) }
        
        return try await withCheckedThrowingContinuation { continuation in
            let requestDelegate = AlbumElementRequestDelegate(numberOfCalls: elementIds.count) { result in
                guard Task.isCancelled == false else { continuation.resume(throwing: AlbumErrorEntity.generic); return }
                
                switch result {
                case .success(let result):
                    let entity = AlbumElementsResultEntity(success:result.0, failure: result.1)
                    continuation.resume(returning:entity)
                case .failure(_):
                    continuation.resume(throwing: AlbumErrorEntity.generic)
                }
            }
            
            for eid in elementIds {
                sdk.removeSetElement(albumId, eid: eid, delegate: requestDelegate)
            }
        }
    }
}
