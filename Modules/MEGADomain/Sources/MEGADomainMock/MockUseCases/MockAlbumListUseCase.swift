import Foundation
import MEGADomain

public final class MockAlbumListUseCase: AlbumListUseCaseProtocol {
    private let cameraUploadNode: NodeEntity?
    private let albums: [AlbumEntity]
    
    public var startMonitoringNodesUpdateCalled = 0
    public var stopMonitoringNodesUpdateCalled = 0
    
    private var sampleUserAlbum: AlbumEntity {
        AlbumEntity(id: 4, name: "Custom Name", coverNode: NodeEntity(handle: 4), count: 0, type: .user)
    }
    
    public init(cameraUploadNode: NodeEntity? = nil, albums: [AlbumEntity] = []) {
        self.cameraUploadNode = cameraUploadNode
        self.albums = albums
    }
    
    public func loadCameraUploadNode() async throws -> NodeEntity? {
        cameraUploadNode
    }
    
    public func loadAlbums() async -> [AlbumEntity] {
        albums
    }
    
    public func startMonitoringNodesUpdate(callback: @escaping () -> Void) {
        startMonitoringNodesUpdateCalled += 1
    }
    
    public func stopMonitoringNodesUpdate() {
        stopMonitoringNodesUpdateCalled += 1
    }
    
    public func createUserAlbum(with name: String?) async throws -> AlbumEntity {
        sampleUserAlbum.update(name: name ?? "")
    }
}
