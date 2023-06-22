import MEGADomain
import MEGADomainMock
import XCTest

final class MediaDiscoveryAnalyticsUseCaseTests: XCTestCase {
    
    func testSendEvent_onMediaDiscoveryVisited_shouldReturnTrue() throws {
        let repo = MockAnalyticsRepository.newRepo
        let usecase = MediaDiscoveryAnalyticsUseCase(repository: repo)
        
        usecase.sendPageVisitedStats()
        
        XCTAssertTrue(repo.type == .mediaDiscovery(.clickMediaDiscovery))
    }
    
    func testSendEvent_onMediaDiscoveryOver10s_shouldReturnTrue() throws {
        let repo = MockAnalyticsRepository.newRepo
        let usecase = MediaDiscoveryAnalyticsUseCase(repository: repo)
        
        usecase.sendPageStayStats(with: 11)
        
        XCTAssertTrue(repo.type == .mediaDiscovery(.stayOnMediaDiscoveryOver10s))
    }
    
    func testSendEvent_onMediaDiscoveryOver30s_shouldReturnTrue() throws {
        let repo = MockAnalyticsRepository.newRepo
        let usecase = MediaDiscoveryAnalyticsUseCase(repository: repo)
        
        usecase.sendPageStayStats(with: 31)
        
        XCTAssertTrue(repo.type == .mediaDiscovery(.stayOnMediaDiscoveryOver30s))
    }
    
    func testSendEvent_onMediaDiscoveryOver60s_shouldReturnTrue() throws {
        let repo = MockAnalyticsRepository.newRepo
        let usecase = MediaDiscoveryAnalyticsUseCase(repository: repo)
        
        usecase.sendPageStayStats(with: 61)
        
        XCTAssertTrue(repo.type == .mediaDiscovery(.stayOnMediaDiscoveryOver60s))
    }
    
    func testSendEvent_onMediaDiscoveryOver180s_shouldReturnTrue() throws {
        let repo = MockAnalyticsRepository.newRepo
        let usecase = MediaDiscoveryAnalyticsUseCase(repository: repo)
        
        usecase.sendPageStayStats(with: 181)
        
        XCTAssertTrue(repo.type == .mediaDiscovery(.stayOnMediaDiscoveryOver180s))
    }
    
    func testSendEvent_onMediaDiscoveryLessThan10s_shouldReturnFalse() throws {
        let repo = MockAnalyticsRepository.newRepo
        let usecase = MediaDiscoveryAnalyticsUseCase(repository: repo)
        
        usecase.sendPageStayStats(with: 3)
        
        XCTAssertFalse(repo.type == .mediaDiscovery(.stayOnMediaDiscoveryOver180s))
    }
    
    func testSendEvent_onMediaDiscoveryEqual10s_shouldReturnNil() throws {
        let repo = MockAnalyticsRepository.newRepo
        let usecase = MediaDiscoveryAnalyticsUseCase(repository: repo)
        
        usecase.sendPageStayStats(with: 10)
        
        XCTAssertNil(repo.type)
    }
    
    func testSendEvent_onMediaDiscoveryEqual30s_shouldReturnTrue() throws {
        let repo = MockAnalyticsRepository.newRepo
        let usecase = MediaDiscoveryAnalyticsUseCase(repository: repo)
        
        usecase.sendPageStayStats(with: 30)
        
        XCTAssertTrue(repo.type == .mediaDiscovery(.stayOnMediaDiscoveryOver10s))
    }
    
    func testSendEvent_onMediaDiscoveryEqual60s_shouldReturnTrue() throws {
        let repo = MockAnalyticsRepository.newRepo
        let usecase = MediaDiscoveryAnalyticsUseCase(repository: repo)
        
        usecase.sendPageStayStats(with: 60)
        
        XCTAssertTrue(repo.type == .mediaDiscovery(.stayOnMediaDiscoveryOver30s))
    }
    
    func testSendEvent_onMediaDiscoveryEqual180s_shouldReturnTrue() throws {
        let repo = MockAnalyticsRepository.newRepo
        let usecase = MediaDiscoveryAnalyticsUseCase(repository: repo)
        
        usecase.sendPageStayStats(with: 180)
        
        XCTAssertTrue(repo.type == .mediaDiscovery(.stayOnMediaDiscoveryOver60s))
    }
}
