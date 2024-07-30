import MEGADomain
import MEGATest
@testable import Video
import XCTest

final class VideoPlaylistContentSorterTests: XCTestCase {
    
    // MARK: - sort
    
    func testSort_whenDefaultAsc_returnsSortedVideosByNameAsc() async {
        let videos = [
            NodeEntity(name: "C.mp4", modificationTime: yesterdayDate),
            NodeEntity(name: "A.mp4", modificationTime: yesterdayDate),
            NodeEntity(name: "B.mp4", modificationTime: yesterdayDate)
        ]
        
        let sortedVideos = await VideoPlaylistContentSorter.sort(videos, by: .defaultAsc)
        XCTAssertEqual(sortedVideos.map { $0.name }, ["A.mp4", "B.mp4", "C.mp4"])
    }
    
    func testSort_whenDefaultDesc_returnsSortedVideosByNameDesc() async {
        let videos = [
            NodeEntity(name: "A.mp4", modificationTime: yesterdayDate),
            NodeEntity(name: "C.mp4", modificationTime: yesterdayDate),
            NodeEntity(name: "B.mp4", modificationTime: yesterdayDate)
        ]
        
        let sortedVideos = await VideoPlaylistContentSorter.sort(videos, by: .defaultDesc)
        XCTAssertEqual(sortedVideos.map { $0.name }, ["C.mp4", "B.mp4", "A.mp4"])
    }
    
    func testSort_whenModificationAsc_returnsSortedVideosByCreationTimeAsc() async {
        let videos = [
            NodeEntity(name: "A.mp4", modificationTime: aMonthAgoDate),
            NodeEntity(name: "B.mp4", modificationTime: yesterdayDate),
            NodeEntity(name: "C.mp4", modificationTime: aWeekAgoDate)
        ]
        
        let sortedVideos = await VideoPlaylistContentSorter.sort(videos, by: .modificationAsc)
        XCTAssertEqual(sortedVideos.map { $0.name }, ["A.mp4", "C.mp4", "B.mp4"])
    }
    
    func testSort_whenModificationDesc_returnsSortedVideosByCreationTimeDesc() async {
        let videos = [
            NodeEntity(name: "A.mp4", modificationTime: aMonthAgoDate),
            NodeEntity(name: "C.mp4", modificationTime: aWeekAgoDate),
            NodeEntity(name: "B.mp4", modificationTime: yesterdayDate)
        ]
        
        let sortedVideos = await VideoPlaylistContentSorter.sort(videos, by: .modificationDesc)
        XCTAssertEqual(sortedVideos.map { $0.name }, ["B.mp4", "C.mp4", "A.mp4"])
    }
    
    func testSort_whenUnwantedSortOrder_returnsUnsortedVideos() async {
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
        for await (index, sortOrder) in invalidSortOrders.enumerated().async {
            let sortedVideos = await VideoPlaylistContentSorter.sort(videos, by: sortOrder)
            XCTAssertEqual(sortedVideos, videos, "Failed at index: \(index), for value: \(sortOrder)")
        }
    }
}
