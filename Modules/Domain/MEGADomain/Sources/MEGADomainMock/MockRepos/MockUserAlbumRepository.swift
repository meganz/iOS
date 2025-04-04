@preconcurrency import Combine
import Foundation
import MEGADomain
import MEGASwift

public struct MockUserAlbumRepository: UserAlbumRepositoryProtocol {
    public static let newRepo = MockUserAlbumRepository()
    private let node: NodeEntity?
    private let albums: [SetEntity]
    private let albumContent: [HandleEntity: [SetElementEntity]]
    private let albumElementIds: [HandleEntity: [AlbumPhotoIdEntity]]
    public let setsUpdatedPublisher: AnyPublisher<[SetEntity], Never>
    public let setElementsUpdatedPublisher: AnyPublisher<[SetElementEntity], Never>
    private let albumElement: SetElementEntity?
    private let createAlbumResult: Result<SetEntity, any Error>
    private let updateAlbumNameResult: Result<String, any Error>
    private let deleteAlbumResult: Result<HandleEntity, any Error>?
    private let addPhotosResult: Result<AlbumElementsResultEntity, any Error>
    private let updateAlbumElementNameResult: Result<String, any Error>
    private let updateAlbumElementOrderResult: Result<Int64, any Error>
    private let deleteAlbumElementsResult: Result<AlbumElementsResultEntity, any Error>
    private let updateAlbumCoverResult: Result<HandleEntity, any Error>
    private let albumsUpdated: AnyAsyncSequence<[SetEntity]>
    private let albumContentUpdated: AnyAsyncSequence<[SetElementEntity]>
    
    public init(node: NodeEntity? = nil,
                albums: [SetEntity] = [],
                albumContent: [HandleEntity: [SetElementEntity]] = [:],
                albumElementIds: [HandleEntity: [AlbumPhotoIdEntity]] = [:],
                setsUpdatedPublisher: AnyPublisher<[SetEntity], Never> = Empty().eraseToAnyPublisher(),
                setElementsUpdatedPublisher: AnyPublisher<[SetElementEntity], Never> = Empty().eraseToAnyPublisher(),
                albumElement: SetElementEntity? = nil,
                createAlbumResult: Result<SetEntity, any Error> = .failure(GenericErrorEntity()),
                updateAlbumNameResult: Result<String, any Error> = .failure(GenericErrorEntity()),
                deleteAlbumResult: Result<HandleEntity, any Error>? = nil,
                addPhotosResult: Result<AlbumElementsResultEntity, any Error> = .failure(GenericErrorEntity()),
                updateAlbumElementNameResult: Result<String, any Error> = .failure(GenericErrorEntity()),
                updateAlbumElementOrderResult: Result<Int64, any Error> = .failure(GenericErrorEntity()),
                deleteAlbumElementsResult: Result<AlbumElementsResultEntity, any Error> = .failure(GenericErrorEntity()),
                updateAlbumCoverResult: Result<HandleEntity, any Error> = .failure(GenericErrorEntity()),
                albumsUpdated: AnyAsyncSequence<[SetEntity]> = EmptyAsyncSequence<[SetEntity]>().eraseToAnyAsyncSequence(),
                albumContentUpdated: AnyAsyncSequence<[SetElementEntity]> = EmptyAsyncSequence<[SetElementEntity]>().eraseToAnyAsyncSequence()
    ) {
        self.node = node
        self.albums = albums
        self.albumContent = albumContent
        self.albumElementIds = albumElementIds
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
        self.albumsUpdated = albumsUpdated
        self.albumContentUpdated = albumContentUpdated
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
    
    public func albumElementIds(by id: HandleEntity, includeElementsInRubbishBin: Bool) async -> [AlbumPhotoIdEntity] {
        albumElementIds[id] ?? []
    }
    
    public func albumElementId(by id: HandleEntity, elementId: HandleEntity) async -> AlbumPhotoIdEntity? {
        albumElementIds[id]?.first(where: { $0.albumPhotoId == elementId })
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
    
    public func albumsUpdated() async -> AnyAsyncSequence<[SetEntity]> {
        albumsUpdated
    }
    
    public func albumContentUpdated(by id: HandleEntity) async -> AnyAsyncSequence<[SetElementEntity]> {
        albumContentUpdated
    }
}
