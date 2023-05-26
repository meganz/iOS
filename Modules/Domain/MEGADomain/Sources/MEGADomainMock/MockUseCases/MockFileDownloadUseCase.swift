import Foundation
import MEGADomain

public final class MockFileDownloadUseCase: FileDownloadUseCaseProtocol {
    private let url: URL
    
    public init(url: URL) {
        self.url = url
    }
    
    public func cachedOriginalPath(_ node: NodeEntity) -> URL? {
        nil
    }
    
    public func downloadNode(_ node: NodeEntity) async throws -> URL {
        url
    }
}
