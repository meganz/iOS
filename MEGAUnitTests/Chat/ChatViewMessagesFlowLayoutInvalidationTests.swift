@testable import MEGA
import MessageKit
import XCTest

/// Pins the UIKit invalidation signals that ChatViewMessagesFlowLayout's size cache relies on.
///
/// The cache is dropped wholesale when a context arrives with `invalidateEverything`, per row when
/// `prepare(forCollectionViewUpdates:)` sees a `.reload`, and explicitly on `editing`. It ignores
/// `invalidateFlowLayoutDelegateMetrics` on purpose. Which of those signals `reloadItems`,
/// `reloadSections`, a bare `invalidateLayout()` and `reloadData()` actually send is UIKit
/// behaviour, not ours, so it is measured here rather than assumed. If a UIKit release changes it,
/// this is where it shows up.
///
/// The stub stands in for MessagesViewController on both sides: it is the UIKit data source the
/// collection view counts sections through, and the MessageKit data source the layout sizes through.
final class ChatViewMessagesFlowLayoutInvalidationTests: XCTestCase {
    private struct Message: MessageType {
        let sender: any SenderType
        let messageId: String
        let sentDate: Date
        let kind: MessageKind
    }

    @MainActor
    private final class DataSource: NSObject, UICollectionViewDataSource, MessagesDataSource, MessagesLayoutDelegate, MessagesDisplayDelegate {
        static let cellIdentifier = "cell"
        let messages: [Message]

        init(count: Int) {
            let user = User(senderId: "1", displayName: "one")
            messages = (0..<count).map {
                Message(sender: user, messageId: "m\($0)", sentDate: Date(), kind: .text("message \($0)"))
            }
        }

        // UIKit side: one section per message, one item per section, as ChatViewController does.
        func numberOfSections(in collectionView: UICollectionView) -> Int { messages.count }
        func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int { 1 }
        func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
            collectionView.dequeueReusableCell(withReuseIdentifier: Self.cellIdentifier, for: indexPath)
        }

        // MessageKit side.
        var currentSender: any SenderType { messages[0].sender }
        func numberOfSections(in messagesCollectionView: MessagesCollectionView) -> Int { messages.count }
        func messageForItem(at indexPath: IndexPath, in messagesCollectionView: MessagesCollectionView) -> any MessageType {
            messages[indexPath.section]
        }
    }

    @MainActor
    private final class SpyLayout: ChatViewMessagesFlowLayout {
        struct Invalidation {
            let everything: Bool
            let dataSourceCounts: Bool
            let flowDelegateMetrics: Bool?
        }
        var invalidations: [Invalidation] = []
        var updates: [(action: UICollectionViewUpdateItem.Action, before: IndexPath?, after: IndexPath?)] = []

        override func invalidateLayout(with context: UICollectionViewLayoutInvalidationContext) {
            invalidations.append(Invalidation(
                everything: context.invalidateEverything,
                dataSourceCounts: context.invalidateDataSourceCounts,
                flowDelegateMetrics: (context as? UICollectionViewFlowLayoutInvalidationContext)?.invalidateFlowLayoutDelegateMetrics
            ))
            super.invalidateLayout(with: context)
        }

        override func prepare(forCollectionViewUpdates updateItems: [UICollectionViewUpdateItem]) {
            updates.append(contentsOf: updateItems.map { ($0.updateAction, $0.indexPathBeforeUpdate, $0.indexPathAfterUpdate) })
            super.prepare(forCollectionViewUpdates: updateItems)
        }

        func reset() {
            invalidations.removeAll()
            updates.removeAll()
        }

        var sawFlowDelegateMetrics: Bool { invalidations.contains { $0.flowDelegateMetrics == true } }
        var sawEverything: Bool { invalidations.contains(where: \.everything) }

        /// Goes into every assertion message so the raw observations survive into the xcresult.
        var report: String {
            let inv = invalidations.map {
                "[everything=\($0.everything) counts=\($0.dataSourceCounts) flowMetrics=\(String(describing: $0.flowDelegateMetrics))]"
            }
            let upd = updates.map { "[\($0.action.rawValue) before=\(String(describing: $0.before)) after=\(String(describing: $0.after))]" }
            return "invalidations=\(inv) updates=\(upd)"
        }
    }

    /// Everything the collection view needs, kept alive together for the length of one test. Both
    /// data-source references on the collection view are weak, so the stub has to live here.
    @MainActor
    private struct SUT {
        let window: UIWindow
        let dataSource: DataSource
        let layout: SpyLayout
        let collectionView: MessagesCollectionView

        func settle() {
            collectionView.layoutIfNeeded()
        }
    }

    @MainActor
    private func makeSUT(messageCount: Int = 5) -> SUT {
        let dataSource = DataSource(count: messageCount)
        let layout = SpyLayout()
        let collectionView = MessagesCollectionView(frame: CGRect(x: 0, y: 0, width: 390, height: 844), collectionViewLayout: layout)
        collectionView.register(UICollectionViewCell.self, forCellWithReuseIdentifier: DataSource.cellIdentifier)
        collectionView.dataSource = dataSource
        collectionView.messagesDataSource = dataSource
        collectionView.messagesLayoutDelegate = dataSource
        collectionView.messagesDisplayDelegate = dataSource
        let window = UIWindow(frame: collectionView.frame)
        window.addSubview(collectionView)
        window.makeKeyAndVisible()
        collectionView.reloadData()
        collectionView.layoutIfNeeded()
        layout.reset()
        return SUT(window: window, dataSource: dataSource, layout: layout, collectionView: collectionView)
    }

    // MARK: - The four paths the cache cares about

    @MainActor
    func testHarness_reportsOneSectionPerMessage() {
        let sut = makeSUT()

        XCTAssertEqual(sut.collectionView.numberOfSections, 5)
        XCTAssertEqual(sut.collectionView.numberOfItems(inSection: 2), 1)
    }

    @MainActor
    func testReloadItems_reportsReloadUpdateWithItemIndexPath() {
        let sut = makeSUT()

        sut.collectionView.reloadItems(at: [IndexPath(item: 0, section: 2)])
        sut.settle()

        let reloads = sut.layout.updates.filter { $0.action == .reload }
        XCTAssertEqual(reloads.count, 1, sut.layout.report)
        XCTAssertEqual(reloads.first?.after, IndexPath(item: 0, section: 2), sut.layout.report)
        // UIKit flags delegate metrics on a single-row reload. This is why the cache must not treat
        // that flag as "drop everything": it would empty on every transfer event.
        XCTAssertTrue(sut.layout.sawFlowDelegateMetrics, sut.layout.report)
        XCTAssertFalse(sut.layout.sawEverything, "a row reload must not look like reloadData. \(sut.layout.report)")
    }

    @MainActor
    func testReloadSections_reportsReloadUpdateWithUsableSection() {
        let sut = makeSUT()

        sut.collectionView.performBatchUpdates {
            sut.collectionView.reloadSections([2])
        }
        sut.settle()

        let reloads = sut.layout.updates.filter { $0.action == .reload }
        XCTAssertEqual(reloads.count, 1, sut.layout.report)
        XCTAssertEqual(reloads.first?.after?.section, 2, sut.layout.report)
        XCTAssertEqual(reloads.first?.after?.item, NSNotFound, "section reloads carry no item; the cache resolves the message by section only. \(sut.layout.report)")
        XCTAssertTrue(sut.layout.sawFlowDelegateMetrics, sut.layout.report)
        XCTAssertFalse(sut.layout.sawEverything, "a section reload must not look like reloadData. \(sut.layout.report)")
    }

    @MainActor
    func testBareInvalidateLayout_doesNotInvalidateEverything() {
        let sut = makeSUT()

        sut.collectionView.collectionViewLayout.invalidateLayout()
        sut.settle()

        // A bare invalidateLayout() - what setEditing and the `editing` property use - does not
        // announce itself as reloadData. That is why `editing` drops the cache explicitly.
        XCTAssertFalse(sut.layout.sawEverything, sut.layout.report)
        XCTAssertTrue(sut.layout.sawFlowDelegateMetrics, sut.layout.report)
        XCTAssertTrue(sut.layout.updates.isEmpty, sut.layout.report)
    }

    // MARK: - What the item-size key must vary with

    /// The date and time labels above a bubble depend on the previous message, so deleting,
    /// inserting or prepending a sibling changes a row's height without changing the row. The
    /// cache copes by keying on those label heights rather than by tracking sibling updates.
    func testItemSizeKey_changesWhenANeighbourDependentLabelHeightChanges() {
        typealias Key = ChatViewMessagesFlowLayout.ItemSizeKey
        let base = Key(transferState: -1, cellTopLabelHeight: 0, messageTopLabelHeight: 0)

        XCTAssertEqual(base, Key(transferState: -1, cellTopLabelHeight: 0, messageTopLabelHeight: 0))
        XCTAssertNotEqual(base, Key(transferState: -1, cellTopLabelHeight: 30, messageTopLabelHeight: 0), "date label appeared: previous message is now on another day")
        XCTAssertNotEqual(base, Key(transferState: -1, cellTopLabelHeight: 0, messageTopLabelHeight: 28), "time label appeared: previous message is now another sender or minute")
        XCTAssertNotEqual(base, Key(transferState: 3, cellTopLabelHeight: 0, messageTopLabelHeight: 0), "transfer state changed")
    }

    @MainActor
    func testReloadData_invalidatesEverythingWithoutUpdateItems() {
        let sut = makeSUT()

        sut.collectionView.reloadData()
        sut.settle()

        XCTAssertTrue(sut.layout.sawEverything, sut.layout.report)
        XCTAssertTrue(sut.layout.updates.isEmpty, "reloadData does not go through prepare(forCollectionViewUpdates:). \(sut.layout.report)")
    }
}
