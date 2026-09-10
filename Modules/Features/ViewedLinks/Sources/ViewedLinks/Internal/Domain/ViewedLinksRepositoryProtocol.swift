import Foundation
import MEGASwift

package protocol ViewedLinksRepositoryProtocol: Sendable {
    func viewedLinks(sortedBy sortKey: ViewedLinksSortKey, ascending: Bool) async throws(ViewedLinkErrorEntity) -> [ViewedLinkEntity]
    func topViewedLinks(limit: Int) async throws(ViewedLinkErrorEntity) -> [ViewedLinkEntity]
    func record(_ link: ViewedLinkEntity) async throws(ViewedLinkErrorEntity)
    func remove(_ links: [ViewedLinkEntity]) async throws(ViewedLinkErrorEntity)
    func removeUnavailable(linkURL: URL) async throws(ViewedLinkErrorEntity)
    func clearHistory() async throws(ViewedLinkErrorEntity)
    func changesSignalSequence() -> AnyAsyncSequence<Void>
}
