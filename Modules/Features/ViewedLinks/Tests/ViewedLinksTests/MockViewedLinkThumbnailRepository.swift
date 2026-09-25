import Foundation
import MEGADomain
@testable import ViewedLinks

/// Mock `ViewedLinkThumbnailRepositoryProtocol` for tests.
final class MockViewedLinkThumbnailRepository: ViewedLinkThumbnailRepositoryProtocol, @unchecked Sendable {
    private let cached: ThumbnailEntity?
    private let downloaded: ThumbnailEntity?
    private let lock = NSLock()
    private var cachedHandles: [HandleEntity] = []
    private var loadedLinks: [ViewedLinkEntity] = []

    var cachedThumbnailCallCount: Int {
        lock.withLock { cachedHandles.count }
    }

    var loadThumbnailCallCount: Int {
        lock.withLock { loadedLinks.count }
    }

    var requestedHandles: [HandleEntity] {
        lock.withLock { cachedHandles }
    }

    init(cached: ThumbnailEntity? = nil, downloaded: ThumbnailEntity? = nil) {
        self.cached = cached
        self.downloaded = downloaded
    }

    func cachedThumbnail(for handle: HandleEntity) -> ThumbnailEntity? {
        lock.withLock { cachedHandles.append(handle) }
        return cached
    }

    func loadThumbnail(for link: ViewedLinkEntity) async throws -> ThumbnailEntity {
        lock.withLock { loadedLinks.append(link) }

        guard let downloaded else { throw GenericErrorEntity() }
        return downloaded
    }
}
