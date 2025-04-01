import MEGADomain
import MEGASdk
@testable import MEGASDKRepo
import MEGASDKRepoMock
import Testing

@Suite("TransfersListenerRepository Tests")
struct TransfersListenerRepositoryTests {
    @Test("Pause transfers")
    func shouldPauseTransfers() {
        let sdk = MockSdk()
        let repository = TransfersListenerRepository(sdk: sdk)
        
        #expect(sdk.pausedTransfersCall == nil)
        
        repository.pauseTransfers()
        
        #expect(sdk.pausedTransfersCall == true)
    }
    
    @Test("Resume transfers")
    func shouldNotPauseTransfers() {
        let sdk = MockSdk()
        let repository = TransfersListenerRepository(sdk: sdk)
        
        #expect(sdk.pausedTransfersCall == nil)
        
        repository.resumeTransfers()
        
        #expect(sdk.pausedTransfersCall == false)
    }
}
