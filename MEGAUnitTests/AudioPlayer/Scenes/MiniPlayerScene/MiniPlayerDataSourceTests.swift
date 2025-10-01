@testable import MEGA
import MEGAAppSDKRepoMock
import Testing
import UIKit

@MainActor
@Suite("MiniPlayerDataSource")
struct MiniPlayerDataSourceTests {
    private static let anyURL = URL(string: "https://some-file-link.com")!
    
    private static func makeSUT(
        currentTrack: AudioPlayerItem,
        queue: [AudioPlayerItem]?,
        loopMode: Bool = false
    ) -> MiniPlayerDataSource {
        MiniPlayerDataSource(currentTrack: currentTrack, queue: queue, loopMode: loopMode)
    }

    private static func sample() -> (currentTrack: AudioPlayerItem, queue: [AudioPlayerItem]) {
        let current = audioItem(name: "Song 1", node: anyNode(handle: 12345, name: "Song 1"))
        let queue = [
            audioItem(name: "Song 2", node: anyNode(handle: 54321, name: "Song 2")),
            audioItem(name: "Song 3", node: anyNode(handle: 67890, name: "Song 3"))
        ]
        return (current, queue)
    }

    private static func audioItem(name: String, node: MockNode) -> AudioPlayerItem {
        AudioPlayerItem(name: name, url: URL(string: "https://some-file-link.com")!, node: node)
    }

    private static func anyNode(handle: MEGAHandle, name: String) -> MockNode {
        MockNode(handle: handle, name: name)
    }

    // MARK: - Init
    @Suite("Init")
    @MainActor struct InitSuite {
        @Test("queue is nil -> tracks = [current]")
        func nilQueueSetsCurrentTrack() {
            let (current, _) = sample()
            let sut = makeSUT(currentTrack: current, queue: nil)
            #expect(sut.tracks == [current])
        }
        
        @Test("queue present & loopMode = false -> tracks = queue")
        func queuePresentLoopOffSetsQueue() {
            let (current, queue) = sample()
            let sut = makeSUT(currentTrack: current, queue: queue, loopMode: false)
            #expect(sut.tracks == queue)
            #expect(sut.tracks?.count == queue.count)
        }
        
        @Test("queue present & loopMode = true -> tracks = queue + [current]")
        func queuePresentLoopOnAppendsCurrent() {
            let (current, queue) = sample()
            let sut = makeSUT(currentTrack: current, queue: queue, loopMode: true)
            
            let expected = queue + [current]
            
            #expect(sut.tracks == expected)
            #expect(sut.tracks?.count == expected.count)
        }
    }

    // MARK: - Item Access
    @Suite("Item Access")
    @MainActor struct ItemAccessSuite {
        @Test("item(at:) returns expected item")
        func itemAtIndexPathReturnsExpectedItem() {
            let (current, queue) = sample()
            let sut = makeSUT(currentTrack: current, queue: queue)
            let indexPath = IndexPath(row: 1, section: 0)

            let item = sut.item(at: indexPath)

            #expect(item?.name == "Song 3")
            #expect(item?.url == anyURL)
            #expect(item?.node?.handle == 67890)
        }
    }

    // MARK: - Collection View
    @Suite("Collection View")
    @MainActor struct CollectionViewSuite {
        @Test("numberOfItemsInSection returns expected count")
        func numberOfItemsReturnsExpectedCount() {
            let (current, queue) = sample()
            let sut = makeSUT(currentTrack: current, queue: queue)
            let collectionView = UICollectionView(
                frame: .zero,
                collectionViewLayout: UICollectionViewFlowLayout()
            )

            let count = sut.collectionView(collectionView, numberOfItemsInSection: 0)

            #expect(count == 2)
        }
    }
}
