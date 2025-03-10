@testable import Accounts
import MEGASdk
import MEGASDKRepoMock
import Testing

@Suite("App loading repository tests")
struct AppLoadingRepositoryTests {
    
    @Test("Test new repo")
    func testNewRepo() {
        let repo = AppLoadingRepository.newRepo
        #expect(repo != nil)
        #expect(repo.sdk == MEGASdk.sharedSdk)
    }
    
    @Test("Test waiting reason")
    func testWaitingReason() {
        let mockSdk = MockSdk(retryReason: .apiLock)
        let repo = AppLoadingRepository(sdk: mockSdk)
        
        let waitingReason = repo.waitingReason
        #expect(waitingReason == mockSdk.waiting.toWaitingReasonEntity())
    }
}
