import Foundation

public protocol AlbumRepositoryProtocol: RepositoryProtocol {
    func loadCameraUploadNode() async throws -> NodeEntity?
}
