@testable import MEGA
import MEGADomain
import Testing
import XCTest

@Suite("Home Banner ViewModel Tests Suite - Tests the behavior of HomeBannerViewModel.")
struct HomeBannerViewModelTests {
    // MARK: - Helpers
    private func makeSUT(bannersResult: Result<[BannerEntity], BannerErrorEntity>? = nil) -> (HomeBannerViewModel, MockUserBannerUseCase, MockHomeBannerRouter) {
        let mockUserBannerUseCase = MockUserBannerUseCase(bannersResult: bannersResult)
        let mockRouter = MockHomeBannerRouter()
        let sut = HomeBannerViewModel(
            userBannerUseCase: mockUserBannerUseCase,
            router: mockRouter
        )
        return (sut, mockUserBannerUseCase, mockRouter)
    }
    
    let anyURL = URL(string: "https://example.com")!
    
    // MARK: - Test Methods
    @Test
    func dismissBanner_withBannerId_callsDismissOnUseCase() {
        let (sut, mockUserBannerUseCase, _) = makeSUT()
        let bannerId = 1
        
        sut.dismissBanner(withBannerId: bannerId)
        
        #expect(mockUserBannerUseCase.lastDismissedBannerId == bannerId, "Expected dismissBanner to be called with bannerId \(bannerId).")
    }
    
    @Test
    func didSelectBanner_withValidURL_callsRouter() {
        let (sut, _, mockRouter) = makeSUT()
        let actionURL = anyURL
        
        sut.didSelectBanner(actionURL: actionURL)
        
        #expect(mockRouter.didTrigger_calledTimes == 1, "Expected router to be called once.")
        #expect(mockRouter.lastTriggeredURL == actionURL, "Expected router to be triggered with URL \(actionURL).")
    }
    
    @Test
    func didSelectBanner_withNilURL_doesNotCallRouter() {
        let (sut, _, mockRouter) = makeSUT()
        
        sut.didSelectBanner(actionURL: nil)
        
        #expect(mockRouter.didTrigger_calledTimes == 0, "Expected router not to be called when URL is nil.")
    }
}

final class HomeBannerVMTests: XCTestCase {
    // MARK: - Helpers
    private func makeSUT(bannersResult: Result<[BannerEntity], BannerErrorEntity>? = nil) -> HomeBannerViewModel {
        let mockUserBannerUseCase = MockUserBannerUseCase(bannersResult: bannersResult)
        let mockRouter = MockHomeBannerRouter()
        let sut = HomeBannerViewModel(
            userBannerUseCase: mockUserBannerUseCase,
            router: mockRouter
        )
        trackForMemoryLeaks(on: sut)
        trackForMemoryLeaks(on: mockUserBannerUseCase)
        trackForMemoryLeaks(on: mockRouter)
        return sut
    }
    
    let anyURL = URL(string: "https://example.com")!
    
    private func anyBanner() -> BannerEntity {
        BannerEntity(
            identifier: 1,
            title: "Test Banner",
            description: "Description",
            backgroundImageURL: self.anyURL,
            imageURL: self.anyURL
        )
    }
    
    func testViewIsReady_withBanners_notifyUpdateCalled() async {
        let banners = [anyBanner()]
        let sut = makeSUT(bannersResult: .success(banners))
        
        let expectation = expectation(description: "Expect notifyUpdate to be called")
        
        sut.notifyUpdate = { lastOutput in
            XCTAssertEqual(lastOutput.state.banners.count, banners.count)
            XCTAssertEqual(lastOutput.state.banners.first?.title, banners.first?.title)
            expectation.fulfill()
        }
        
        sut.viewIsReady()
        
        await fulfillment(of: [expectation], timeout: 1.0)
    }
    
    func testViewIsReady_whenBannersFetchFails_notifyUpdateNotCalled() async {
        let sut = makeSUT(bannersResult: .failure(BannerErrorEntity.internal))
        
        let expectation = expectation(description: "Expect notifyUpdate to not be called")
        expectation.isInverted = true
        
        sut.notifyUpdate = { _ in
            XCTFail("notifyUpdate should not be called on failure")
        }
        
        sut.viewIsReady()
        
        await fulfillment(of: [expectation], timeout: 1.0)
    }
}
