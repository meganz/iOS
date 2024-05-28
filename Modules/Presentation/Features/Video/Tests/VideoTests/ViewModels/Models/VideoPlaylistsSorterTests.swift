import MEGADomain
@testable import Video
import XCTest

final class VideoPlaylistsSorterTests: XCTestCase {
    
    // MARK: - sort
    
    func testSort_whenEmptyPlaylists_returnsEmptyPlaylists() {
        let emptyVideoPlaylists = [VideoPlaylistEntity]()
        let anySortOrder = SortOrderEntity.creationAsc
        
        let sortedVideoPlaylists = VideoPlaylistsSorter.sort(emptyVideoPlaylists, by: anySortOrder)
        
        XCTAssertEqual(sortedVideoPlaylists, emptyVideoPlaylists)
    }
    
    func testSort_whenModificationAsc_returnsProperlySortedPlaylists() {
        let unsortedVideoPlaylists = [
            yesterdayPlaylist,
            aMonthAgoPlaylist,
            aWeekAgoPlaylist
        ]
        
        let sortedVideoPlaylists = VideoPlaylistsSorter.sort(unsortedVideoPlaylists, by: .modificationAsc)
        
        XCTAssertEqual(sortedVideoPlaylists.map(\.id), [
            aMonthAgoPlaylist.id,
            aWeekAgoPlaylist.id,
            yesterdayPlaylist.id
        ])
    }
    
    func testSort_whenModificationDesc_returnsProperlySortedPlaylists() {
        let unsortedVideoPlaylists = [
            yesterdayPlaylist,
            aMonthAgoPlaylist,
            aWeekAgoPlaylist
        ]
        
        let sortedVideoPlaylists = VideoPlaylistsSorter.sort(unsortedVideoPlaylists, by: .modificationDesc)
        
        XCTAssertEqual(sortedVideoPlaylists.map(\.id), [
            yesterdayPlaylist.id,
            aWeekAgoPlaylist.id,
            aMonthAgoPlaylist.id,
        ])
    }
    
    func testSort_whenUnwantedSortOrder_doesNotSortOrder() {
        let unsortedVideoPlaylists = [
            yesterdayPlaylist,
            aMonthAgoPlaylist,
            aWeekAgoPlaylist
        ]
        let unwantedSortOrders = SortOrderEntity.allCases
            .filter { $0 != .modificationAsc }
            .filter { $0 != .modificationDesc }
        
        unwantedSortOrders.enumerated().forEach { (index, sortOrder) in
            let sortedVideoPlaylists = VideoPlaylistsSorter.sort(unsortedVideoPlaylists, by: sortOrder)
            
            XCTAssertEqual(sortedVideoPlaylists, unsortedVideoPlaylists, "Expect not to do sort, but failed at: \(index) for sortOrder: \(sortOrder)")
        }
    }
    
}
