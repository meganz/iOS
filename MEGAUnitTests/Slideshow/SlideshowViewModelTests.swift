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
            configuration: .init(playingOrder: .shuffled, timeIntervalForSlideInSeconds: .normal, isRepeat: false, includeSubfolders: false)
        )
    }
    
    private func emptyImage(with size: CGSize) throws -> UIImage {
        UIGraphicsBeginImageContext(size)
        let image = UIGraphicsGetImageFromCurrentImageContext()
        UIGraphicsEndImageContext()
        return try XCTUnwrap(image)
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
        
        await sut.thumbnailLoadingTask?.value
        sut.currentSlideNumber = 11
        await sut.thumbnailLoadingTask?.value
        XCTAssertTrue(sut.photos.count == 40)
    }
    
    func testSlideshowPlaying_reloadUnusedPhoto_firstPhotoInPhotosShouldBeNotNil() async throws {
        let sut = try makeSlideshowViewModel()
        
        sut.currentSlideNumber = 11
        await sut.thumbnailLoadingTask?.value
        sut.currentSlideNumber = 20
        XCTAssertNil(sut.photos[0].image)
        
        sut.currentSlideNumber = 19
        await sut.thumbnailLoadingTask?.value
        XCTAssertNotNil(sut.photos[0].image)
    }
    
    func testSlideshowPlaying_removeUnusedPhotos_firstPhotoInPhotosShouldBeNil() async throws {
        let sut = try makeSlideshowViewModel()
        
        sut.currentSlideNumber = 11
        await sut.thumbnailLoadingTask?.value
        sut.currentSlideNumber = 20
        
        XCTAssertNil(sut.photos[0].image)
    }
    
    func testSlideShowViewModel_play_playbackStatusShouldBePlaying() throws {
        let slideShowViewModel = try makeSlideshowViewModel()

        slideShowViewModel.dispatch(.play)
        XCTAssertTrue(slideShowViewModel.playbackStatus == .playing)
    }
    
    func testSlideShowViewModel_pause_playbackStatusShouldBePaused() throws {
        let slideShowViewModel = try makeSlideshowViewModel()
        slideShowViewModel.dispatch(.pause)

        XCTAssertTrue(slideShowViewModel.playbackStatus == .pause)
    }
    
    func testSlideShowViewModel_finish_playbackStatusShouldBeComplete() throws {
        let slideShowViewModel = try makeSlideshowViewModel()

        slideShowViewModel.dispatch(.finish)
        XCTAssertTrue(slideShowViewModel.playbackStatus == .complete)
    }
    
    func testSlideShowViewModel_resetTimer_playbackStatusShouldBePlaying() throws {
        let slideShowViewModel = try makeSlideshowViewModel()

        slideShowViewModel.dispatch(.play)
        slideShowViewModel.dispatch(.resetTimer)
        XCTAssertTrue(slideShowViewModel.playbackStatus == .playing)
    }
    
    func testSlideShowViewModel_cancel_playbackStatusShouldBePlaying() throws {
        let slideShowViewModel = try makeSlideshowViewModel()
        let sut: SlideShowViewModelPreferenceProtocol = slideShowViewModel
        
        slideShowViewModel.dispatch(.pause)
        XCTAssertTrue(slideShowViewModel.playbackStatus == .pause)
        
        sut.cancel()
        XCTAssertTrue(slideShowViewModel.playbackStatus == .playing)
    }
    
    func testSlideShowViewModel_restart_repeatShouldBeTrueAndTimeShouldBe8AndCurrentSlideShouldBeNeg1() throws {
        let slideShowViewModel = try makeSlideshowViewModel()
        let sut: SlideShowViewModelPreferenceProtocol = slideShowViewModel
        
        XCTAssertTrue(slideShowViewModel.playbackStatus == .initialized)
        slideShowViewModel.dispatch(.play)
        XCTAssertTrue(slideShowViewModel.playbackStatus == .playing)
        slideShowViewModel.dispatch(.pause)
        XCTAssertTrue(slideShowViewModel.playbackStatus == .pause)
        XCTAssertTrue(slideShowViewModel.currentSlideNumber == 0)
        XCTAssertTrue(slideShowViewModel.timeIntervalForSlideInSeconds == 4)
        XCTAssertTrue(slideShowViewModel.configuration.isRepeat == false)
        
        sut.restart(withConfig: SlideShowViewConfiguration(
            playingOrder: .shuffled, timeIntervalForSlideInSeconds: .normal, isRepeat: true, includeSubfolders: false)
        )
        
        XCTAssertTrue(slideShowViewModel.playbackStatus == .playing)
        XCTAssertTrue(slideShowViewModel.timeIntervalForSlideInSeconds == 4)
        XCTAssertTrue(slideShowViewModel.configuration.isRepeat == true)
    }
}
