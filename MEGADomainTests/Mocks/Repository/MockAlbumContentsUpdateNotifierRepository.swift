@testable import MEGA

final class MockAlbumContentsUpdateNotifierRepository: AlbumContentsUpdateNotifierRepositoryProtocol {
    var onAlbumReload: (() -> Void)?
    
    private let sdk: MockSdk
    
    init(sdk: MockSdk) {
        self.sdk = sdk
    }
}
