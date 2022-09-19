import XCTest
import MEGADomainMock
import MEGADomain
@testable import MEGA

class SlideshowViewModelTests: XCTestCase {
    private var nodeEntities: [NodeEntity] {
        var nodes = [NodeEntity]()
        
        for i in 1...40 {
            nodes.append(NodeEntity(name: "\(i).png", handle: HandleEntity(i), isFile: true))
        }
        return nodes
    }
    
    private func saveImage(_ image: UIImage, name: String) throws -> URL? {
        let imageData = try XCTUnwrap(image.jpegData(compressionQuality: 1))
        let url = try XCTUnwrap(FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first)
        let imageURL = url.appendingPathComponent(name)
        try XCTUnwrap(imageData.write(to: imageURL))
        return imageURL
    }
    
    private func makeSlideshowViewModel() throws -> SlideShowViewModel {
        let thumbnailUrl = try XCTUnwrap(saveImage(try emptyImage(with: CGSize(width: 1, height: 1)), name: "slideshow.jpg"))

        return SlideShowViewModel(
            thumbnailUseCase: MockThumbnailUseCase(
                loadPreviewResult: .success(try XCTUnwrap(thumbnailUrl))
            ),
            dataProvider: MockPhotoBrowserDataProvider(
                currentPhoto: try XCTUnwrap(nodeEntities.first),
                allPhotos: nodeEntities,
                sdk: MockSdk()
            ),
            mediaUseCase: MockMediaUseCase(isURLVideo: false, isURLImage: true),
            configuration: .init(playingOrder: .shuffled, timeIntervalForSlideInSeconds: 4)
        )
    }
    
    private func emptyImage(with size: CGSize) throws -> UIImage {
        UIGraphicsBeginImageContext(size)
        let image = UIGraphicsGetImageFromCurrentImageContext()
        UIGraphicsEndImageContext()
        return try XCTUnwrap(image)
    }
    
    func testSlideshowPlay_UpdatePlaybackStatus_toPlaying() throws {
        let sut = try makeSlideshowViewModel()
        sut.dispatch(.playOrPause)
        XCTAssert(sut.playbackStatus == .playing)
    }
    
    func testSlideshowPause_UpdatePlaybackStatus_toPause() throws {
        let sut = try makeSlideshowViewModel()
        sut.dispatch(.playOrPause)
        sut.dispatch(.playOrPause)
        XCTAssert(sut.playbackStatus == .pause)
    }
    
    func testSlideshowExit_UpdatePlaybackStatus_toComplete() throws {
        let sut = try makeSlideshowViewModel()
        sut.dispatch(.finishPlaying)
        XCTAssert(sut.playbackStatus == .complete)
    }
    
    func testSlideshowPlaying_isInitialDownloads_shouldReturnTrue() async throws {
        let sut = try makeSlideshowViewModel()
        
        await sut.thumbnailLoadingTask?.value
        sut.currentSlideNumber = 1
        XCTAssertTrue(sut.isInitialDownload)
    }
    
    func testSlideshowPlaying_isInitialDownloads_shouldReturnFalse() async throws {
        let sut = try makeSlideshowViewModel()
        await sut.thumbnailLoadingTask?.value
        
        sut.thumbnailLoadingTask = nil
        sut.currentSlideNumber = 11
        await sut.thumbnailLoadingTask?.value
        XCTAssertFalse(sut.isInitialDownload)
    }
    
    func testSlideshowPlaying_startInitialDownload_photosShouldReturn20() async throws {
        let sut = try makeSlideshowViewModel()
        
        await sut.thumbnailLoadingTask?.value
        XCTAssertTrue(sut.photos.count == 20)
    }
    
    func testSlideshowPlaying_secondPageDownload_photosShouldReturn40() async throws {
        let sut = try makeSlideshowViewModel()
        
        sut.currentSlideNumber = 11
        await sut.thumbnailLoadingTask?.value
        XCTAssertTrue(sut.photos.count == 40)
    }
}
