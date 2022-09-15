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
    
    private func saveImage(_ image: UIImage, name: String) -> URL? {
        guard let imageData = image.jpegData(compressionQuality: 1) else {
            return nil
        }
        do {
            let imageURL = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first!.appendingPathComponent(name)
            try imageData.write(to: imageURL)
            return imageURL
        } catch {
            return nil
        }
    }
    
    private func slideshowViewModel() -> SlideShowViewModel {
        let url = saveImage(emptyImage(with: CGSize(width: 1, height: 1))!, name: "slideshow.jpg")
        
        return SlideShowViewModel(
            thumbnailUseCase: MockThumbnailUseCase(
                loadPreviewResult: .success(url ?? URL(string: "https://MEGA.NZ")!)
            ),
            dataProvider: MockPhotoBrowserDataProvider(
                currentPhoto: nodeEntities.first!,
                allPhotos: nodeEntities,
                sdk: MockSdk()
            ),
            mediaUseCase: MockMediaUseCase(isURLVideo: false, isURLImage: true),
            configuration: .init(playingOrder: .shuffled, timeIntervalForSlideInSeconds: 4)
        )
    }
    
    private func emptyImage(with size: CGSize) -> UIImage? {
        UIGraphicsBeginImageContext(size)
        let image = UIGraphicsGetImageFromCurrentImageContext()
        UIGraphicsEndImageContext()
        return image
    }
    
    func testSlideshowPlay_UpdatePlaybackStatus_toPlaying() throws {
        let sut = slideshowViewModel()
        sut.dispatch(.playOrPause)
        XCTAssert(sut.playbackStatus == .playing)
    }
    
    func testSlideshowPause_UpdatePlaybackStatus_toPause() throws {
        let sut = slideshowViewModel()
        sut.dispatch(.playOrPause)
        sut.dispatch(.playOrPause)
        XCTAssert(sut.playbackStatus == .pause)
    }
    
    func testSlideshowExit_UpdatePlaybackStatus_toComplete() throws {
        let sut = slideshowViewModel()
        sut.dispatch(.finishPlaying)
        XCTAssert(sut.playbackStatus == .complete)
    }
    
    func testSlideshowPlaying_isInitialDownloads_shouldReturnTrue() throws {
        let expectation = self.expectation(description: "Is Initial Download should be true")
        let sut = slideshowViewModel()
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
           expectation.fulfill()
        }
        wait(for: [expectation], timeout: 0.5)
        sut.currentSlideNumber = 1
        XCTAssertTrue(sut.isInitialDownload)
    }
    
    func testSlideshowPlaying_isInitialDownloads_shouldReturnFalse() throws {
        let expectation = self.expectation(description: "Is Initial Download should be false")
        let sut = slideshowViewModel()
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
           expectation.fulfill()
        }
        wait(for: [expectation], timeout: 0.5)
        sut.currentSlideNumber = 11
        XCTAssertFalse(sut.isInitialDownload)
    }
    
    func testSlideshowPlaying_startInitialDownload_photosShouldReturn20() throws {
        let expectation = self.expectation(description: "Initial Download should load 20 photos")
        let sut = slideshowViewModel()
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
           expectation.fulfill()
        }
        wait(for: [expectation], timeout: 0.5)
        XCTAssertTrue(sut.photos.count == 20)
    }
    
    func testSlideshowPlaying_secondPageDownload_photosShouldReturn40() throws {
        let expectation = self.expectation(description: "Second Page Download should load 40 photos")
        let sut = slideshowViewModel()
        sut.currentSlideNumber = 11
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
           expectation.fulfill()
        }
        wait(for: [expectation], timeout: 0.5)
        XCTAssertTrue(sut.photos.count == 40)
    }
}
