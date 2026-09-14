import Foundation
import MEGASwift

package struct ViewedLinksUseCase: ViewedLinksUseCaseProtocol {
    private let repository: any ViewedLinksRepositoryProtocol

    package init(repository: some ViewedLinksRepositoryProtocol) {
        self.repository = repository
    }

    package func viewedLinks(sortedBy sortKey: ViewedLinksSortKey, ascending: Bool) async throws(ViewedLinkErrorEntity) -> [ViewedLinkEntity] {
        try await repository.viewedLinks(sortedBy: sortKey, ascending: ascending)
    }

    package func topViewedLinks(limit: Int) async throws(ViewedLinkErrorEntity) -> [ViewedLinkEntity] {
        try await repository.topViewedLinks(limit: limit)
    }

    package func record(_ link: ViewedLinkEntity) async throws(ViewedLinkErrorEntity) {
        try await repository.record(link)
    }

    package func remove(_ links: [ViewedLinkEntity]) async throws(ViewedLinkErrorEntity) {
        try await repository.remove(links)
    }

    package func removeUnavailable(linkURL: URL) async throws(ViewedLinkErrorEntity) {
        try await repository.removeUnavailable(linkURL: linkURL)
    }

    package func clearHistory() async throws(ViewedLinkErrorEntity) {
        try await repository.clearHistory()
    }

    package func changesSignalSequence() -> AnyAsyncSequence<Void> {
        repository.changesSignalSequence()
    }
}
