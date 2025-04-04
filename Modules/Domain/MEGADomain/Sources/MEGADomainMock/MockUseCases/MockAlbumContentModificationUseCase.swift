import Foundation
import MEGADomain
import MEGASwift

public final class MockAlbumModificationUseCase: AlbumModificationUseCaseProtocol, @unchecked Sendable {
    public enum Invocation: Sendable, Equatable {
        case addPhotosToAlbum(id: HandleEntity, nodes: [NodeEntity])
    }
    private var resultEntity = AlbumElementsResultEntity(success: 0, failure: 0)
    private let addPhotosResult: Result<AlbumElementsResultEntity, any Error>
    public private(set) var addedPhotosToAlbum: [NodeEntity]?
    public private(set) var deletedPhotos: [AlbumPhotoEntity]?
    public private(set) var deletedAlbumsIds: [HandleEntity]?
    public var invocationSequence: AnyAsyncSequence<Invocation> {
        invocationStream.eraseToAnyAsyncSequence()
    }

    private let albums: [AlbumEntity]
    private let invocationStream: AsyncStream<Invocation>
    private let invocationContinuation: AsyncStream<Invocation>.Continuation
    
    public init(resultEntity: AlbumElementsResultEntity? = nil,
                albums: [AlbumEntity] = [],
                addPhotosResult: Result<AlbumElementsResultEntity, any Error> = .failure(GenericErrorEntity())) {
        if let resultEntity = resultEntity {
            self.resultEntity = resultEntity
        }
        self.albums = albums
        self.addPhotosResult = addPhotosResult
        (invocationStream, invocationContinuation) = AsyncStream.makeStream(of: Invocation.self)
    }

    public func addPhotosToAlbum(by id: HandleEntity, nodes: [NodeEntity]) async throws -> AlbumElementsResultEntity {
        invocationContinuation.yield(.addPhotosToAlbum(id: id, nodes: nodes))
        switch addPhotosResult {
        case .success(let albumElementsResult):
            addedPhotosToAlbum = nodes
            return albumElementsResult
        case .failure(let error):
            throw error
        }
    }
    
    public func rename(album id: HandleEntity, with newName: String) async throws -> String {
        return newName
    }
    
    public func updateAlbumCover(album id: HandleEntity, withAlbumPhoto albumPhoto: AlbumPhotoEntity) async throws -> HandleEntity {
        return albumPhoto.id
    }

    public func deletePhotos(in albumId: HandleEntity, photos: [AlbumPhotoEntity]) async throws -> AlbumElementsResultEntity {
        deletedPhotos = photos
        return resultEntity
    }
    
    public func delete(albums ids: [HandleEntity]) async -> [HandleEntity] {
        deletedAlbumsIds = ids
        return albums.map { $0.id }
    }
}
