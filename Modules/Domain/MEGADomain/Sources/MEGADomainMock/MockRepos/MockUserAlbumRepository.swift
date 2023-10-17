import Combine
import Foundation
import MEGADomain

public struct MockUserAlbumRepository: UserAlbumRepositoryProtocol {
    public static var newRepo = MockUserAlbumRepository()
    private let node: NodeEntity?
    private let albums: [SetEntity]
    private let albumContent: [HandleEntity: [SetElementEntity]]
    public let setsUpdatedPublisher: AnyPublisher<[SetEntity], Never>
    public let setElementsUpdatedPublisher: AnyPublisher<[SetElementEntity], Never>
    public let albumElement: SetElementEntity?
    public let createAlbumResult: Result<SetEntity, Error>
    public let updateAlbumNameResult: Result<String, Error>
    public let deleteAlbumResult: Result<HandleEntity, Error>?
    public let addPhotosResult: Result<AlbumElementsResultEntity, Error>
    public let updateAlbumElementNameResult: Result<String, Error>
    public let updateAlbumElementOrderResult: Result<Int64, Error>
    public let deleteAlbumElementsResult: Result<AlbumElementsResultEntity, Error>
    public let updateAlbumCoverResult: Result<HandleEntity, Error>
    
    public init(node: NodeEntity? = nil,
                albums: [SetEntity] = [],
                albumContent: [HandleEntity: [SetElementEntity]] = [:],
                setsUpdatedPublisher: AnyPublisher<[SetEntity], Never> = Empty().eraseToAnyPublisher(),
                setElementsUpdatedPublisher: AnyPublisher<[SetElementEntity], Never> = Empty().eraseToAnyPublisher(),
                albumElement: SetElementEntity? = nil,
                createAlbumResult: Result<SetEntity, Error> = .failure(GenericErrorEntity()),
                updateAlbumNameResult: Result<String, Error> = .failure(GenericErrorEntity()),
                deleteAlbumResult: Result<HandleEntity, Error>? = nil,
                addPhotosResult: Result<AlbumElementsResultEntity, Error> = .failure(GenericErrorEntity()),
                updateAlbumElementNameResult: Result<String, Error> = .failure(GenericErrorEntity()),
                updateAlbumElementOrderResult: Result<Int64, Error> = .failure(GenericErrorEntity()),
                deleteAlbumElementsResult: Result<AlbumElementsResultEntity, Error> = .failure(GenericErrorEntity()),
                updateAlbumCoverResult: Result<HandleEntity, Error> = .failure(GenericErrorEntity())
    ) {
        self.node = node
        self.albums = albums
        self.albumContent = albumContent
        self.setsUpdatedPublisher = setsUpdatedPublisher
        self.setElementsUpdatedPublisher = setElementsUpdatedPublisher
        self.albumElement = albumElement
        self.createAlbumResult = createAlbumResult
        self.updateAlbumNameResult = updateAlbumNameResult
        self.deleteAlbumResult = deleteAlbumResult
        self.addPhotosResult = addPhotosResult
        self.updateAlbumElementNameResult = updateAlbumElementNameResult
        self.updateAlbumElementOrderResult = updateAlbumElementOrderResult
        self.deleteAlbumElementsResult = deleteAlbumElementsResult
        self.updateAlbumCoverResult = updateAlbumCoverResult
    }
    
    public func albums() async -> [SetEntity] {
        albums
    }
    
    public func albumContent(by id: HandleEntity, includeElementsInRubbishBin: Bool) async -> [SetElementEntity] {
        albumContent[id] ?? []
    }
    
    public func albumElement(by id: HandleEntity, elementId: HandleEntity) async -> SetElementEntity? {
        albumElement
    }
    
    public func createAlbum(_ name: String?) async throws -> SetEntity {
        try await withCheckedThrowingContinuation {
            $0.resume(with: createAlbumResult)
        }
    }
    
    public func updateAlbumName(_ name: String, _ id: HandleEntity) async throws -> String {
        try await withCheckedThrowingContinuation {
            $0.resume(with: updateAlbumNameResult)
        }
    }
    
    public func deleteAlbum(by id: HandleEntity) async throws -> HandleEntity {
        guard let deleteAlbumResult else {
            return id
        }
        return try await withCheckedThrowingContinuation {
            $0.resume(with: deleteAlbumResult)
        }
    }
    
    public func addPhotosToAlbum(by id: HandleEntity,
                                 nodes: [NodeEntity]) async throws -> AlbumElementsResultEntity {
        try await withCheckedThrowingContinuation {
            $0.resume(with: addPhotosResult)
        }
    }
    
    public func updateAlbumElementName(albumId: HandleEntity, elementId: HandleEntity, name: String) async throws -> String {
        try await withCheckedThrowingContinuation {
            $0.resume(with: updateAlbumElementNameResult)
        }
    }
    
    public func updateAlbumElementOrder(albumId: HandleEntity, elementId: HandleEntity, order: Int64) async throws -> Int64 {
        try await withCheckedThrowingContinuation {
            $0.resume(with: updateAlbumElementOrderResult)
        }
    }
    
    public func deleteAlbumElements(albumId: HandleEntity, elementIds: [HandleEntity]) async throws -> AlbumElementsResultEntity {
        try await withCheckedThrowingContinuation {
            $0.resume(with: deleteAlbumElementsResult)
        }
    }
    
    public func updateAlbumCover(for albumId: HandleEntity, elementId: HandleEntity) async throws -> HandleEntity {
        try await withCheckedThrowingContinuation {
            $0.resume(with: updateAlbumCoverResult)
        }
    }
}
