@preconcurrency import Combine
import MEGADomain
import MEGASdk
import MEGASwift

final public class UserAlbumRepository: NSObject, UserAlbumRepositoryProtocol {
    
    public static var newRepo: UserAlbumRepository {
        UserAlbumRepository(sdk: MEGASdk.sharedSdk)
    }
    
    private let setsUpdatedSourcePublisher = PassthroughSubject<[SetEntity], Never>()
    private let setElementsUpdatedSourcePublisher = PassthroughSubject<[SetElementEntity], Never>()
    
    private let sdk: MEGASdk
    
    public var setsUpdatedPublisher: AnyPublisher<[SetEntity], Never> {
        setsUpdatedSourcePublisher.eraseToAnyPublisher()
    }
    
    public var setElementsUpdatedPublisher: AnyPublisher<[SetElementEntity], Never> {
        setElementsUpdatedSourcePublisher.eraseToAnyPublisher()
    }
    
    public init(sdk: MEGASdk) {
        self.sdk = sdk
        super.init()
        sdk.add(self)
    }
    
    deinit {
        sdk.remove(self)
    }
    
    public func albumsUpdated() async -> AnyAsyncSequence<[SetEntity]> {
        setsUpdatedSourcePublisher.values
            .compactMap { [weak self] _ in await self?.albums() }
            .eraseToAnyAsyncSequence()
    }
    
    public func albumContentUpdated(by id: HandleEntity) async -> AnyAsyncSequence<[SetElementEntity]> {
        setElementsUpdatedSourcePublisher.values
            .map {
                $0.filter { $0.ownerId == id }
            }
            .filter { $0.isNotEmpty }
            .eraseToAnyAsyncSequence()
    }
    
    // MARK: - Albums
    public func albums() async -> [SetEntity] {
        sdk.megaSets().toSetEntities().filter { $0.setType == .album }
    }
    
    public func albumContent(by id: HandleEntity, includeElementsInRubbishBin: Bool) async -> [SetElementEntity] {
        let megaSetElements = sdk.megaSetElements(bySid: id,
                                                  includeElementsInRubbishBin: includeElementsInRubbishBin)
        return megaSetElements.toSetElementsEntities()
    }
    
    public func albumElement(by id: HandleEntity, elementId: HandleEntity) async -> SetElementEntity? {
        sdk.megaSetElement(bySid: id, eid: elementId)?.toSetElementEntity()
    }
    
    public func albumElementIds(by id: HandleEntity, includeElementsInRubbishBin: Bool) async -> [AlbumPhotoIdEntity] {
        let megaSetElements = sdk.megaSetElements(bySid: id,
                                                  includeElementsInRubbishBin: includeElementsInRubbishBin)
        return megaSetElements.toAlbumPhotoIdEntities()
    }
    
    public func albumElementId(by id: HandleEntity, elementId: HandleEntity) async -> AlbumPhotoIdEntity? {
        sdk.megaSetElement(bySid: id, eid: elementId)?.toAlbumPhotoIdEntity()
    }
    
    public func createAlbum(_ name: String?) async throws -> SetEntity {
        return try await withCheckedThrowingContinuation { continuation in
            sdk.createSet(name, type: .album, delegate: RequestDelegate { result in
                guard Task.isCancelled == false else { continuation.resume(throwing: AlbumErrorEntity.generic); return }
                
                switch result {
                case .success(let request):
                    guard let set = request.set else {
                        continuation.resume(throwing: AlbumErrorEntity.generic)
                        return
                    }
                    
                    continuation.resume(returning: set.toSetEntity())
                case .failure:
                    continuation.resume(throwing: AlbumErrorEntity.generic)
                }
            })
        }
    }
    
    public func updateAlbumName(_ name: String, _ id: HandleEntity) async throws -> String {
        return try await withCheckedThrowingContinuation { continuation in
            sdk.updateSetName(id, name: name, delegate: RequestDelegate { result in
                guard Task.isCancelled == false else { continuation.resume(throwing: AlbumErrorEntity.generic); return }
                
                switch result {
                case .success(let request):
                    continuation.resume(returning: request.text ?? "")
                case .failure:
                    continuation.resume(throwing: AlbumErrorEntity.generic)
                }
            })
        }
    }
    
    public func deleteAlbum(by id: HandleEntity) async throws -> HandleEntity {
        return try await withCheckedThrowingContinuation { continuation in
            sdk.removeSet(id, delegate: RequestDelegate { result in
                guard Task.isCancelled == false else { continuation.resume(throwing: AlbumErrorEntity.generic); return }
                
                switch result {
                case .success(let request):
                    continuation.resume(returning: request.parentHandle)
                case .failure:
                    continuation.resume(throwing: AlbumErrorEntity.generic)
                }
            })
        }
    }
    
    // MARK: - Album Content
    public func addPhotosToAlbum(by id: HandleEntity, nodes: [NodeEntity]) async throws -> AlbumElementsResultEntity {
        guard nodes.isNotEmpty else { return AlbumElementsResultEntity(success: 0, failure: 0) }
        
        return try await withCheckedThrowingContinuation { continuation in
            let requestDelegate = AlbumElementRequestDelegate(numberOfCalls: nodes.count) { result in
                guard Task.isCancelled == false else { continuation.resume(throwing: AlbumErrorEntity.generic); return }
                
                switch result {
                case .success(let result):
                    let entity = AlbumElementsResultEntity(success: result.0, failure: result.1)
                    continuation.resume(returning: entity)
                case .failure:
                    continuation.resume(throwing: AlbumErrorEntity.generic)
                }
            }
            
            for node in nodes {
                sdk.createSetElement(id, nodeId: node.id, name: "", delegate: requestDelegate)
            }
        }
    }
    
    public func updateAlbumElementName(albumId: HandleEntity, elementId: HandleEntity, name: String) async throws -> String {
        return try await withCheckedThrowingContinuation { continuation in
            sdk.updateSetElement(albumId, eid: elementId, name: name, delegate: RequestDelegate { result in
                guard Task.isCancelled == false else { continuation.resume(throwing: AlbumErrorEntity.generic); return }
                
                switch result {
                case .success(let request):
                    continuation.resume(returning: request.text ?? "")
                case .failure:
                    continuation.resume(throwing: AlbumErrorEntity.generic)
                }
            })
        }
    }
    
    public func updateAlbumElementOrder(albumId: HandleEntity, elementId: HandleEntity, order: Int64) async throws -> Int64 {
        return try await withCheckedThrowingContinuation { continuation in
            sdk.updateSetElementOrder(albumId, eid: elementId, order: order, delegate: RequestDelegate { result in
                guard Task.isCancelled == false else { continuation.resume(throwing: AlbumErrorEntity.generic); return }
                
                switch result {
                case .success(let request):
                    continuation.resume(returning: request.number)
                case .failure:
                    continuation.resume(throwing: AlbumErrorEntity.generic)
                }
            })
        }
    }
    
    public func deleteAlbumElements(albumId: HandleEntity, elementIds: [HandleEntity]) async throws -> AlbumElementsResultEntity {
        guard elementIds.isNotEmpty else { return AlbumElementsResultEntity(success: 0, failure: 0) }
        
        return try await withCheckedThrowingContinuation { continuation in
            let requestDelegate = AlbumElementRequestDelegate(numberOfCalls: elementIds.count) { result in
                guard Task.isCancelled == false else { continuation.resume(throwing: AlbumErrorEntity.generic); return }
                
                switch result {
                case .success(let result):
                    let entity = AlbumElementsResultEntity(success: result.0, failure: result.1)
                    continuation.resume(returning: entity)
                case .failure:
                    continuation.resume(throwing: AlbumErrorEntity.generic)
                }
            }
            
            for eid in elementIds {
                sdk.removeSetElement(albumId, eid: eid, delegate: requestDelegate)
            }
        }
    }
    
    // MARK: Album Cover
    public func updateAlbumCover(for albumId: HandleEntity, elementId: HandleEntity) async throws -> HandleEntity {
        return try await withCheckedThrowingContinuation { continuation in
            sdk.putSetCover(albumId, eid: elementId, delegate: RequestDelegate { result in
                guard Task.isCancelled == false else { continuation.resume(throwing: AlbumErrorEntity.generic); return }
                
                switch result {
                case .success(let request):
                    continuation.resume(returning: request.nodeHandle)
                case .failure:
                    continuation.resume(throwing: AlbumErrorEntity.generic)
                }
            })
        }
    }
}

extension UserAlbumRepository: MEGAGlobalDelegate {
    public func onSetsUpdate(_ api: MEGASdk, sets: [MEGASet]) {
        let albumSets = sets.toSetEntities().filter { $0.setType == .album }
        guard albumSets.isNotEmpty else { return }
        setsUpdatedSourcePublisher.send(albumSets)
    }
    
    public func onSetElementsUpdate(_ api: MEGASdk, setElements: [MEGASetElement]) {
        setElementsUpdatedSourcePublisher.send(setElements.toSetElementsEntities())
    }
}
