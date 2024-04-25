import MEGADomain
import MEGAL10n
import XCTest
@testable import Video

final class VideoPlaylistEntity_Mapper_Tests: XCTestCase {
    
    // MARK: - ToVideoPlaylistCellPreviewEntity
    
    func testToVideoPlaylistCellPreviewEntity_whenHasNoVideo_deliversCorrectMappingFormat() {
        let videoPlaylistTypes = VideoPlaylistEntityType.allCases
        videoPlaylistTypes.enumerated().forEach { (index, type) in
            let duration = "02:02:02"
            let name = "A simple playlist"
            let sut = VideoPlaylistEntity(id: 1, name: name, count: 0, type: type, sharedLinkStatus: .exported(false))
            
            let previewEntity = sut.toVideoPlaylistCellPreviewEntity(thumbnailContainers: [], durationText: duration)
            
            assertThatMappingDeliversCorrectFormat(on: sut, forResult: previewEntity, at: index, duration: duration, name: name)
            XCTAssertEqual(previewEntity.count, Strings.Localizable.Videos.Tab.Playlist.Content.PlaylistCell.Subtitle.emptyPlaylist, "failed at index: \(index) for value: \(previewEntity.count)")
        }
    }
    
    func testToVideoPlaylistCellPreviewEntity_whenHasAVideo_deliversCorrectMappingFormat() {
        let videoPlaylistTypes = VideoPlaylistEntityType.allCases
        videoPlaylistTypes.enumerated().forEach { (index, type) in
            let duration = "02:02:02"
            let name = "A simple playlist"
            let sut = VideoPlaylistEntity(id: 1, name: name, count: 1, type: type, sharedLinkStatus: .exported(false))
            
            let previewEntity = sut.toVideoPlaylistCellPreviewEntity(thumbnailContainers: [], durationText: duration)
            
            assertThatMappingDeliversCorrectFormat(on: sut, forResult: previewEntity, at: index, duration: duration, name: name)
            XCTAssertEqual(previewEntity.count, "1" + " " + Strings.Localizable.video, "failed at index: \(index) for value: \(previewEntity.count)")
        }
    }
    
    func testToVideoPlaylistCellPreviewEntity_whenHasMoreThanOneVideos_deliversCorrectMappingFormat() {
        let videoPlaylistTypes = VideoPlaylistEntityType.allCases
        videoPlaylistTypes.enumerated().forEach { (index, type) in
            let duration = "02:02:02"
            let name = "A simple playlist"
            let sut = VideoPlaylistEntity(id: 1, name: name, count: 2, type: type, sharedLinkStatus: .exported(false))
            
            let previewEntity = sut.toVideoPlaylistCellPreviewEntity(thumbnailContainers: [], durationText: duration)
            
            assertThatMappingDeliversCorrectFormat(on: sut, forResult: previewEntity, at: index, duration: duration, name: name)
            XCTAssertEqual(previewEntity.count, "2" + " " + Strings.Localizable.videos, "failed at index: \(index) for value: \(previewEntity.count)")
        }
    }
    
    // MARK: - Helpers
    
    private func assertThatMappingDeliversCorrectFormat(
        on sut: VideoPlaylistEntity,
        forResult previewEntity: VideoPlaylistCellPreviewEntity,
        at index: Int,
        duration: String,
        name: String,
        file: StaticString = #filePath,
        line: UInt = #line
    ) {
        XCTAssertEqual(previewEntity.duration, duration, "failed at index: \(index) for value: \(previewEntity.duration)", file: file, line: line)
        XCTAssertEqual(previewEntity.title, name, "failed at index: \(index) for value: \(previewEntity.title)", file: file, line: line)
        XCTAssertEqual(previewEntity.isExported, sut.isLinkShared, "failed at index: \(index) for value: \(previewEntity.isExported)", file: file, line: line)
    }
}
