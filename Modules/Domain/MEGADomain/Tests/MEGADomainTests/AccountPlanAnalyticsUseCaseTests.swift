import MEGADomain
import MEGADomainMock
import XCTest

final class AccountPlanAnalyticsUseCaseTests: XCTestCase {
    
    func testSendEvent_tappedFreePlan_shouldReturnTrue() throws {
        let repo = MockAnalyticsRepository.newRepo
        let usecase = AccountPlanAnalyticsUseCase(repository: repo)
        
        usecase.sendAccountPlanTapStats(plan: .free)
        
        XCTAssertTrue(repo.type == .accountPlans(.tapAccountPlanFreePlan))
    }
    
    func testSendEvent_tappedProLite_shouldReturnTrue() throws {
        let repo = MockAnalyticsRepository.newRepo
        let usecase = AccountPlanAnalyticsUseCase(repository: repo)
        
        usecase.sendAccountPlanTapStats(plan: .lite)
        
        XCTAssertTrue(repo.type == .accountPlans(.tapAccountPlanProLite))
    }
    
    func testSendEvent_tappedProI_shouldReturnTrue() throws {
        let repo = MockAnalyticsRepository.newRepo
        let usecase = AccountPlanAnalyticsUseCase(repository: repo)
        
        usecase.sendAccountPlanTapStats(plan: .proI)
        
        XCTAssertTrue(repo.type == .accountPlans(.tapAccountPlanProI))
    }
    
    func testSendEvent_tappedProII_shouldReturnTrue() throws {
        let repo = MockAnalyticsRepository.newRepo
        let usecase = AccountPlanAnalyticsUseCase(repository: repo)
        
        usecase.sendAccountPlanTapStats(plan: .proII)
        
        XCTAssertTrue(repo.type == .accountPlans(.tapAccountPlanProII))
    }
    
    func testSendEvent_tappedProIII_shouldReturnTrue() throws {
        let repo = MockAnalyticsRepository.newRepo
        let usecase = AccountPlanAnalyticsUseCase(repository: repo)
        
        usecase.sendAccountPlanTapStats(plan: .proIII)
        
        XCTAssertTrue(repo.type == .accountPlans(.tapAccountPlanProIII))
    }
}
