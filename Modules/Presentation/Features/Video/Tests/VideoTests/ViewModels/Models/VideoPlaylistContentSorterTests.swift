import MEGADomain
import MEGATest
@testable import Video
import XCTest

final class VideoPlaylistContentSorterTests: XCTestCase {
    
    // MARK: - sort
    
    func testSort_whenDefaultAsc_returnsSortedVideosByNameAsc() {
        let videos = [
            NodeEntity(name: "C.mp4", modificationTime: yesterdayDate),
            NodeEntity(name: "A.mp4", modificationTime: yesterdayDate),
            NodeEntity(name: "B.mp4", modificationTime: yesterdayDate)
        ]
        
        let sortedVideos = VideoPlaylistContentSorter.sort(videos, by: .defaultAsc)
        XCTAssertEqual(sortedVideos.map { $0.name }, ["A.mp4", "B.mp4", "C.mp4"])
    }
    
    func testSort_whenDefaultDesc_returnsSortedVideosByNameDesc() {
        let videos = [
            NodeEntity(name: "A.mp4", modificationTime: yesterdayDate),
            NodeEntity(name: "C.mp4", modificationTime: yesterdayDate),
            NodeEntity(name: "B.mp4", modificationTime: yesterdayDate)
        ]
        
        let sortedVideos = VideoPlaylistContentSorter.sort(videos, by: .defaultDesc)
        XCTAssertEqual(sortedVideos.map { $0.name }, ["C.mp4", "B.mp4", "A.mp4"])
    }
    
    func testSort_whenModificationAsc_returnsSortedVideosByCreationTimeAsc() {
        let videos = [
            NodeEntity(name: "A.mp4", modificationTime: aMonthAgoDate),
            NodeEntity(name: "B.mp4", modificationTime: yesterdayDate),
            NodeEntity(name: "C.mp4", modificationTime: aWeekAgoDate)
        ]
        
        let sortedVideos = VideoPlaylistContentSorter.sort(videos, by: .modificationAsc)
        XCTAssertEqual(sortedVideos.map { $0.name }, ["A.mp4", "C.mp4", "B.mp4"])
    }
    
    func testSort_whenModificationDesc_returnsSortedVideosByCreationTimeDesc() {
        let videos = [
            NodeEntity(name: "A.mp4", modificationTime: aMonthAgoDate),
            NodeEntity(name: "C.mp4", modificationTime: aWeekAgoDate),
            NodeEntity(name: "B.mp4", modificationTime: yesterdayDate)
        ]
        
        let sortedVideos = VideoPlaylistContentSorter.sort(videos, by: .modificationDesc)
        XCTAssertEqual(sortedVideos.map { $0.name }, ["B.mp4", "C.mp4", "A.mp4"])
    }
    
    func testSort_whenUnwantedSortOrder_returnsUnsortedVideos() {
        let videos = [
            NodeEntity(name: "A.mp4", modificationTime: aMonthAgoDate),
            NodeEntity(name: "C.mp4", modificationTime: aWeekAgoDate),
            NodeEntity(name: "B.mp4", modificationTime: yesterdayDate)
        ]
        
        let invalidSortOrders: [SortOrderEntity] = SortOrderEntity.allCases
            .filter { $0 != .defaultAsc
                && $0 != .defaultDesc
                && $0 != .modificationAsc
                && $0 != .modificationDesc
            }
        invalidSortOrders.enumerated().forEach { (index, sortOrder) in
            let sortedVideos = VideoPlaylistContentSorter.sort(videos, by: sortOrder)
            XCTAssertEqual(sortedVideos, videos, "Failed at index: \(index), for value: \(sortOrder)")
        }
    }
}
