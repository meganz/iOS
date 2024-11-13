@testable import MEGA
import MEGAAnalyticsiOS
import MEGADomain
import MEGADomainMock
import MEGAPresentation
import MEGAPresentationMock
import MEGATest
import XCTest

class SlideshowViewModelTests: XCTestCase {
    private var nodeEntities: [NodeEntity] {
        var nodes = [NodeEntity]()
        
        for i in 1...40 {
            nodes.append(NodeEntity(name: "\(i).png", handle: HandleEntity(i), isFile: true))
        }
        return nodes
    }
    
    @MainActor
    private func makeSlideshowViewModel(
        configuration: SlideShowConfigurationEntity = SlideShowConfigurationEntity(playingOrder: .newest, timeIntervalForSlideInSeconds: .normal, isRepeat: false, includeSubfolders: false),
        tracker: some AnalyticsTracking = MockTracker()) throws -> SlideShowViewModel {
        SlideShowViewModel(
            dataSource: SlideShowDataSource(
                currentPhoto: try XCTUnwrap(nodeEntities.first),
                nodeEntities: nodeEntities,
                thumbnailUseCase: MockThumbnailUseCase(),
                fileDownloadUseCase: FileDownloadUseCase(fileCacheRepository: MockFileCacheRepository.newRepo, fileSystemRepository: MockFileSystemRepository.newRepo, downloadFileRepository: MockDownloadFileRepository.newRepo),
                mediaUseCase: MockMediaUseCase(),
                advanceNumberOfPhotosToLoad: 20
            ),
            slideShowUseCase: MockSlideShowUseCase(
                config: configuration,
                forUser: 1),
            accountUseCase: MockAccountUseCase(currentUser: UserEntity(handle: 3)),
            tracker: tracker
        )
    }
    
    @MainActor
    func testSlideShowViewModel_play_playbackStatusShouldBePlaying() throws {
        let slideShowViewModel = try makeSlideshowViewModel()

        slideShowViewModel.dispatch(.play)
        XCTAssertTrue(slideShowViewModel.playbackStatus == .playing)
    }
    
    @MainActor
    func testSlideShowViewModel_pause_playbackStatusShouldBePaused() throws {
        let slideShowViewModel = try makeSlideshowViewModel()
        slideShowViewModel.dispatch(.pause)

        XCTAssertTrue(slideShowViewModel.playbackStatus == .pause)
    }
    
    @MainActor
    func testSlideShowViewModel_finish_playbackStatusShouldBeComplete() throws {
        let slideShowViewModel = try makeSlideshowViewModel()

        slideShowViewModel.dispatch(.finish)
        XCTAssertTrue(slideShowViewModel.playbackStatus == .complete)
    }
    
    @MainActor
    func testSlideShowViewModel_resetTimer_playbackStatusShouldBePlaying() throws {
        let slideShowViewModel = try makeSlideshowViewModel()

        slideShowViewModel.dispatch(.play)
        slideShowViewModel.dispatch(.resetTimer)
        XCTAssertTrue(slideShowViewModel.playbackStatus == .playing)
    }
    
    @MainActor
    func testSlideShowViewModel_cancel_playbackStatusShouldBePlaying() throws {
        let slideShowViewModel = try makeSlideshowViewModel()
        let sut: some SlideShowViewModelPreferenceProtocol = slideShowViewModel
        
        slideShowViewModel.dispatch(.pause)
        XCTAssertTrue(slideShowViewModel.playbackStatus == .pause)
        
        sut.cancel()
        XCTAssertTrue(slideShowViewModel.playbackStatus == .playing)
    }
    
    @MainActor
    func testSlideShowViewModel_restart_repeatShouldBeTrueAndTimeShouldBe8AndCurrentSlideShouldBeNeg1() throws {
        let slideShowViewModel = try makeSlideshowViewModel(
            configuration: SlideShowConfigurationEntity(
                playingOrder: .oldest,
                timeIntervalForSlideInSeconds: .normal,
                isRepeat: false,
                includeSubfolders: false
            )
        )
        
        let sut: some SlideShowViewModelPreferenceProtocol = slideShowViewModel
        
        XCTAssertTrue(slideShowViewModel.playbackStatus == .initialized)
        slideShowViewModel.dispatch(.play)
        XCTAssertTrue(slideShowViewModel.playbackStatus == .playing)
        slideShowViewModel.dispatch(.pause)
        XCTAssertTrue(slideShowViewModel.playbackStatus == .pause)
        XCTAssertEqual(slideShowViewModel.currentSlideIndex, 0)
        XCTAssertTrue(slideShowViewModel.timeIntervalForSlideInSeconds == 4)
        XCTAssertTrue(slideShowViewModel.configuration.isRepeat == false)
        
        sut.restart(withConfig: SlideShowConfigurationEntity(
            playingOrder: .shuffled, timeIntervalForSlideInSeconds: .normal, isRepeat: true, includeSubfolders: false)
        )
        
        XCTAssertTrue(slideShowViewModel.playbackStatus == .pause)
        XCTAssertTrue(slideShowViewModel.timeIntervalForSlideInSeconds == 4)
        XCTAssertTrue(slideShowViewModel.configuration.isRepeat == true)
    }
    
    @MainActor
    func testSlideShowViewModel_invokeCommandRestartSlideShow_shouldExecuteCommandShowLoaderAndRestart() throws {
        let dataSource = MockSlideShowDataSource(nodeEntities: nodeEntities, thumbnailUseCase: MockThumbnailUseCase())

        let sut = SlideShowViewModel(
            dataSource: dataSource,
            slideShowUseCase: MockSlideShowUseCase(
                config: SlideShowConfigurationEntity(
                    playingOrder: .newest,
                    timeIntervalForSlideInSeconds: .normal,
                    isRepeat: false, includeSubfolders: false),
                forUser: 100),
            accountUseCase: MockAccountUseCase(), 
            tracker: MockTracker()
        )

        let expectation = expectation(description: "Initial Photo Download Callback")

        sut.invokeCommand = { command in
            if command == .restart {
                expectation.fulfill()
                return
            }
            XCTAssertTrue(command == .showLoader)
        }

        sut.currentSlideIndex = 1
        sut.restartSlideShow()
        XCTAssertTrue(sut.currentSlideIndex == 0)

        wait(for: [expectation], timeout: 1.0)
    }
    
    @MainActor
    func testActionOnViewDidAppear_shouldSendScreenEvent() throws {
        let tracker = MockTracker()
        let sut = try makeSlideshowViewModel(tracker: tracker)
        sut.dispatch(.viewDidAppear)
        assertTrackAnalyticsEventCalled(trackedEventIdentifiers: tracker.trackedEventIdentifiers, with: [SlideShowScreenEvent()])
    }
}
