@preconcurrency import Combine
import Foundation
import MEGADomain
import MEGASwift

public struct MockAlbumListUseCase: AlbumListUseCaseProtocol {
    public enum Invocation: Sendable, Equatable {
        case createUserAlbum(name: String?)
    }
    private let cameraUploadNode: NodeEntity?
    private let albums: [AlbumEntity]
    private let createdUserAlbums: [String: AlbumEntity]
    public let albumsUpdatedPublisher: AnyPublisher<Void, Never>
    
    public static func sampleUserAlbum(name: String) -> AlbumEntity {
        AlbumEntity(id: 4, name: name, coverNode: NodeEntity(handle: 4), count: 0, type: .user)
    }
    
    public var invocationSequence: AnyAsyncSequence<Invocation> {
        invocationStream.eraseToAnyAsyncSequence()
    }

    private let invocationStream: AsyncStream<Invocation>
    private let invocationContinuation: AsyncStream<Invocation>.Continuation
    
    public init(cameraUploadNode: NodeEntity? = nil,
                albums: [AlbumEntity] = [],
                createdUserAlbums: [String: AlbumEntity] = [:],
                albumsUpdatedPublisher: AnyPublisher<Void, Never> = Empty().eraseToAnyPublisher()) {
        self.cameraUploadNode = cameraUploadNode
        self.albums = albums
        self.createdUserAlbums = createdUserAlbums
        self.albumsUpdatedPublisher = albumsUpdatedPublisher
        (invocationStream, invocationContinuation) = AsyncStream.makeStream(of: Invocation.self)
    }
    
    public func loadCameraUploadNode() async throws -> NodeEntity? {
        cameraUploadNode
    }
    
    public func systemAlbums() async throws -> [AlbumEntity] {
        albums.filter { $0.type != .user }
    }
    
    public func userAlbums() async -> [AlbumEntity] {
        albums.filter { $0.type == .user }
    }
    
    public func createUserAlbum(with name: String?) async throws -> AlbumEntity {
        invocationContinuation.yield(.createUserAlbum(name: name))
        return createdUserAlbums[name ?? ""] ?? MockAlbumListUseCase.sampleUserAlbum(name: name ?? "Custom Name")
    }
    
    public func hasNoVisualMedia() async -> Bool {
        false
    }
}
