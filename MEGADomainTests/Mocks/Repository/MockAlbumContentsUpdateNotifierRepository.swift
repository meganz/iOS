@testable import MEGA

final class MockAlbumContentsUpdateNotifierRepository: AlbumContentsUpdateNotifierRepositoryProtocol {
    var onAlbumReload: (() -> Void)?
}
