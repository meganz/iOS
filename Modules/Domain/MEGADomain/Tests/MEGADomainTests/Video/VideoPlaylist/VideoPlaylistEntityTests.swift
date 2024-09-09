@testable import MEGADomain
import XCTest

final class VideoPlaylistEntityTests: XCTestCase {
    
    // MARK: - isSystemVideoPlaylist
    
    func testIsSystemVideoPlaylist_whenTypeIsFavorite_returnsTrue() {
        let sut = makeSUT(type: .favourite)
        
        let isSystemVideoPlaylist = sut.isSystemVideoPlaylist
        
        XCTAssertTrue(isSystemVideoPlaylist)
    }
    
    func testIsSystemVideoPlaylist_whenTypeIsNotFavorite_returnsFalse() {
        let sut = makeSUT(type: .user)
        
        let isSystemVideoPlaylist = sut.isSystemVideoPlaylist
        
        XCTAssertFalse(isSystemVideoPlaylist)
    }
    
    // MARK: - isLinkShared
    
    func testIsLinkShared_whenSharedLinkStatusIsExported_returnsTrue() {
        let sut = makeSUT(sharedLinkStatus: .exported(true))
        
        let isLinkShared = sut.isLinkShared
        
        XCTAssertTrue(isLinkShared)
    }
    
    func testIsLinkShared_whenSharedLinkStatusIsNotExported_returnsFalse() {
        let samples: [SharedLinkStatusEntity] = [ .exported(false), .unavailable ]
        samples.enumerated().forEach { (index, sharedLinkStatus) in
            let sut = makeSUT(sharedLinkStatus: sharedLinkStatus)
            
            let isLinkShared = sut.isLinkShared
            
            XCTAssertFalse(isLinkShared, "failed at index: \(index) on status: \(sharedLinkStatus)")
        }
    }
    
    // MARK: - Helpers
    
    private func makeSUT(
        type: VideoPlaylistEntityType = VideoPlaylistEntityType.favourite,
        sharedLinkStatus: SharedLinkStatusEntity = .unavailable
    ) -> VideoPlaylistEntity {
        VideoPlaylistEntity(
            setIdentifier: SetIdentifier(handle: 1),
            name: "any-name",
            count: 1,
            type: type,
            creationTime: Date(),
            modificationTime: Date(),
            sharedLinkStatus: sharedLinkStatus
        )
    }
}
