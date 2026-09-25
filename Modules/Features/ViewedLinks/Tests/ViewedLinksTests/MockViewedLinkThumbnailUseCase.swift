import Foundation
import MEGADomain
import ViewedLinks

/// Mock `ViewedLinkThumbnailUseCaseProtocol` for tests.
///
/// `results` is consumed one entry per call so a test can express a failure followed by a success.
/// Once it runs dry the last entry is reused.
final class MockViewedLinkThumbnailUseCase: ViewedLinkThumbnailUseCaseProtocol, @unchecked Sendable {
    private let results: [ThumbnailEntity?]
    private let lock = NSLock()
    private var callCount = 0
    private var links: [ViewedLinkEntity] = []

    var loadThumbnailCallCount: Int {
        lock.withLock { callCount }
    }

    var requestedLinks: [ViewedLinkEntity] {
        lock.withLock { links }
    }

    init(thumbnail: ThumbnailEntity? = nil) {
        results = [thumbnail]
    }

    init(results: [ThumbnailEntity?]) {
        self.results = results.isEmpty ? [nil] : results
    }

    func loadThumbnail(viewedLink: ViewedLinkEntity) async throws -> ThumbnailEntity {
        let result = lock.withLock {
            links.append(viewedLink)
            defer { callCount += 1 }
            return results[min(callCount, results.count - 1)]
        }

        guard let result else { throw GenericErrorEntity() }
        return result
    }
}
