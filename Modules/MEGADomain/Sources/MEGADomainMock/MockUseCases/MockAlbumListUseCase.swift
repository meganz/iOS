import Foundation
import MEGADomain

public final class MockAlbumListUseCase: AlbumListUseCaseProtocol {
    private let cameraUploadNode: NodeEntity?
    private let albums: [AlbumEntity]
    
    public var startMonitoringNodesUpdateCalled = 0
    public var stopMonitoringNodesUpdateCalled = 0
    
    public init(cameraUploadNode: NodeEntity? = nil, albums: [AlbumEntity] = []) {
        self.cameraUploadNode = cameraUploadNode
        self.albums = albums
    }
    
    public func loadCameraUploadNode() async throws -> NodeEntity? {
        cameraUploadNode
    }
    
    public func loadAlbums() async throws -> [AlbumEntity] {
        albums
    }
    
    public func startMonitoringNodesUpdate(callback: @escaping () -> Void) {
        startMonitoringNodesUpdateCalled += 1
    }
    
    public func stopMonitoringNodesUpdate() {
        stopMonitoringNodesUpdateCalled += 1
    }
}
