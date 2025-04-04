@testable import MEGA
import MEGAAppSDKRepoMock
import MEGATest
import UIKit
import XCTest

final class MiniPlayerDataSourceTests: XCTestCase {
    
    // MARK: - Init
    
    func testInit_whenQueueIsNil_setCurrentTrackAsTracks() {
        let currentTrack = sampleItem().currentTrack
        let sut = makeSUT(currentTrack: currentTrack, queue: nil)
        
        XCTAssertEqual(sut.tracks, [currentTrack])
    }
    
    func testInit_whenHasQueueAndLoopModeIsFalse_setsQueueAsTracks() {
        let currentTrack = sampleItem().currentTrack
        let queue = sampleItem().queue
        let sut = makeSUT(currentTrack: currentTrack, queue: queue, loopMode: false)
        
        XCTAssertEqual(sut.tracks, queue)
        XCTAssertEqual(sut.tracks?.count, queue.count)
    }
    
    func testInit_whenHasQueueAndLoopModeIsTrue_setsCurrentTrackAndQueueAsTracks() {
        let currentTrack = sampleItem().currentTrack
        let queue = sampleItem().queue
        let sut = makeSUT(currentTrack: currentTrack, queue: queue, loopMode: true)
        
        XCTAssertEqual(sut.tracks, queue + [currentTrack])
        XCTAssertEqual(sut.tracks?.count, queue.count + 1)
    }
    
    // MARK: - itemAtIndexPath
    
    func testItem_atIndexPath_ReturnsExpectedItem() {
        let currentTrack = sampleItem().currentTrack
        let queue = sampleItem().queue
        let sut = makeSUT(currentTrack: currentTrack, queue: queue)
        let indexPath = IndexPath(row: 1, section: 0)
        
        let item = sut.item(at: indexPath)
        
        XCTAssertEqual(item?.name, "Song 3")
        XCTAssertEqual(item?.url, anyURL())
        XCTAssertEqual(item?.node?.handle, 67890)
    }
    
    // MARK: - collectionViewNumberOfItemsInSection
    
    func testCollectionView_numberOfItemsInSection_ReturnsExpectedCount() {
        let currentTrack = sampleItem().currentTrack
        let queue = sampleItem().queue
        let sut = makeSUT(currentTrack: currentTrack, queue: queue)
        let collectionView = UICollectionView(frame: .zero, collectionViewLayout: UICollectionViewFlowLayout())
        
        let count = sut.collectionView(collectionView, numberOfItemsInSection: 0)
        
        XCTAssertEqual(count, 2)
    }
    
    // MARK: - Helpers
    
    private func makeSUT(currentTrack: AudioPlayerItem, queue: [AudioPlayerItem]?, loopMode: Bool = false, file: StaticString = #filePath, line: UInt = #line) -> MiniPlayerDataSource {
        let sut = MiniPlayerDataSource(currentTrack: currentTrack, queue: queue, loopMode: loopMode)
        trackForMemoryLeaks(on: sut, file: file, line: line)
        return sut
    }
    
    private func sampleItem() -> (currentTrack: AudioPlayerItem, queue: [AudioPlayerItem]) {
        let currentTrack = audioPlayerItem(name: "Song 1", node: anyNode(handle: 12345, name: "Song 1"))
        let queue = [
            audioPlayerItem(name: "Song 2", node: anyNode(handle: 54321, name: "Song 2")),
            audioPlayerItem(name: "Song 3", node: anyNode(handle: 67890, name: "Song 3"))
        ]
        return (currentTrack, queue)
    }
    
    private func audioPlayerItem(name: String, node: MockNode) -> AudioPlayerItem {
        AudioPlayerItem(name: name, url: anyURL(), node: node)
    }
    
    private func anyURL() -> URL {
        URL(string: "https://some-file-link.com")!
    }
    
    private func anyNode(handle: MEGAHandle, name: String) -> MockNode {
        MockNode(handle: handle, name: name)
    }
}
