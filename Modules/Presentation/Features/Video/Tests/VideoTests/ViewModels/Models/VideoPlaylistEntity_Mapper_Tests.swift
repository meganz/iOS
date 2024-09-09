import MEGADomain
import MEGAL10n
import MEGAPresentation
import SwiftUI
@testable import Video
import XCTest

final class VideoPlaylistEntity_Mapper_Tests: XCTestCase {
    
    // MARK: - ToVideoPlaylistCellPreviewEntity
    
    func testToVideoPlaylistCellPreviewEntity_whenHasNoVideo_deliversCorrectMappingFormat() {
        let videoPlaylistTypes = VideoPlaylistEntityType.allCases
        videoPlaylistTypes.enumerated().forEach { (index, type) in
            let duration = "02:02:02"
            let name = "A simple playlist"
            let videos: [NodeEntity] = []
            let sut = VideoPlaylistEntity(setIdentifier: SetIdentifier(handle: 1), name: name, count: videos.count, type: type, creationTime: Date(), modificationTime: Date(), sharedLinkStatus: .exported(false))
            
            let thumbnail = VideoPlaylistThumbnail(type: .empty, imageContainers: [])
            let previewEntity = sut.toVideoPlaylistCellPreviewEntity(videoPlaylistThumbnail: thumbnail, videosCount: videos.count, durationText: duration)
            
            assertThatMappingDeliversCorrectFormat(on: sut, forResult: previewEntity, at: index, duration: duration, name: name)
            XCTAssertEqual(previewEntity.count, Strings.Localizable.Videos.Tab.Playlist.Content.PlaylistCell.Subtitle.emptyPlaylist, "failed at index: \(index) for value: \(previewEntity.count)")
        }
    }
    
    func testToVideoPlaylistCellPreviewEntity_whenHasAVideo_deliversCorrectMappingFormat() {
        let videoPlaylistTypes = VideoPlaylistEntityType.allCases
        videoPlaylistTypes.enumerated().forEach { (index, type) in
            let duration = "02:02:02"
            let name = "A simple playlist"
            let videos = [ nodeEntity(name: "video-1", handle: HandleEntity(1), hasThumbnail: true) ]
            let thumbnailContainers = videos.map { _ in anyImageContainer() }
            let sut = VideoPlaylistEntity(setIdentifier: SetIdentifier(handle: 1), name: name, count: videos.count, type: type, creationTime: Date(), modificationTime: Date(), sharedLinkStatus: .exported(false))
            
            let thumbnail = VideoPlaylistThumbnail(type: .normal, imageContainers: thumbnailContainers)
            let previewEntity = sut.toVideoPlaylistCellPreviewEntity(videoPlaylistThumbnail: thumbnail, videosCount: videos.count, durationText: duration)
            
            assertThatMappingDeliversCorrectFormat(on: sut, forResult: previewEntity, at: index, duration: duration, name: name)
            XCTAssertEqual(previewEntity.count, "1" + " " + Strings.Localizable.video, "failed at index: \(index) for value: \(previewEntity.count)")
        }
    }
    
    func testToVideoPlaylistCellPreviewEntity_whenHasMoreThanOneVideos_deliversCorrectMappingFormat() {
        let videoPlaylistTypes = VideoPlaylistEntityType.allCases
        videoPlaylistTypes.enumerated().forEach { (index, type) in
            let duration = "02:02:02"
            let name = "A simple playlist"
            let videos = (0...1).map { nodeEntity(name: "video-\($0)", handle: HandleEntity($0), hasThumbnail: true) }
            let thumbnailContainers = videos.map { _ in anyImageContainer() }
            let sut = VideoPlaylistEntity(setIdentifier: SetIdentifier(handle: 1), name: name, count: videos.count, type: type, creationTime: Date(), modificationTime: Date(), sharedLinkStatus: .exported(false))
            
            let thumbnail = VideoPlaylistThumbnail(type: .normal, imageContainers: thumbnailContainers)
            let previewEntity = sut.toVideoPlaylistCellPreviewEntity(videoPlaylistThumbnail: thumbnail, videosCount: videos.count, durationText: duration)
            
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
    
    private func nodeEntity(
        name: String,
        handle: HandleEntity,
        hasThumbnail: Bool,
        isPublic: Bool = false,
        isShare: Bool = false,
        isFavorite: Bool = false,
        label: NodeLabelTypeEntity = .blue,
        size: UInt64 = 1,
        duration: Int = 60
    ) -> NodeEntity {
        NodeEntity(
            changeTypes: .name,
            nodeType: .folder,
            name: name,
            handle: handle,
            hasThumbnail: hasThumbnail,
            hasPreview: true,
            isPublic: isPublic,
            isShare: isShare,
            isFavourite: isFavorite,
            label: label,
            publicHandle: handle,
            size: size,
            duration: duration,
            mediaType: .video
        )
    }
    
    private func anyImageContainer() -> some ImageContaining {
        ImageContainer(image: Image(systemName: "person"), type: .placeholder)
    }
}
