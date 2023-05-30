import XCTest
import MEGADomain
import MEGADomainMock

final class AnalyticsEventUseCaseTests: XCTestCase {
    
    // MARK: - MediaDiscovery
    
    func testSendEvent_mediaDiscovery_clickMediaDiscovery() {
        let repo = MockAnalyticsRepository.newRepo
        let sut = AnalyticsEventUseCase(repository: repo)
        
        sut.sendAnalyticsEvent(.mediaDiscovery(.clickMediaDiscovery))
        
        XCTAssertTrue(repo.type == .mediaDiscovery(.clickMediaDiscovery))
    }
    
    func testSendEvent_mediaDiscovery_stayOnMediaDiscoveryOver10s() {
        let repo = MockAnalyticsRepository.newRepo
        let sut = AnalyticsEventUseCase(repository: repo)
        
        sut.sendAnalyticsEvent(.mediaDiscovery(.stayOnMediaDiscoveryOver10s))
        
        XCTAssertTrue(repo.type == .mediaDiscovery(.stayOnMediaDiscoveryOver10s))
    }
    
    func testSendEvent_mediaDiscovery_stayOnMediaDiscoveryOver30s() {
        let repo = MockAnalyticsRepository.newRepo
        let sut = AnalyticsEventUseCase(repository: repo)
        
        sut.sendAnalyticsEvent(.mediaDiscovery(.stayOnMediaDiscoveryOver30s))
        
        XCTAssertTrue(repo.type == .mediaDiscovery(.stayOnMediaDiscoveryOver30s))
    }
    
    func testSendEvent_mediaDiscovery_stayOnMediaDiscoveryOver60s() {
        let repo = MockAnalyticsRepository.newRepo
        let sut = AnalyticsEventUseCase(repository: repo)
        
        sut.sendAnalyticsEvent(.mediaDiscovery(.stayOnMediaDiscoveryOver60s))
        
        XCTAssertTrue(repo.type == .mediaDiscovery(.stayOnMediaDiscoveryOver60s))
    }
    
    func testSendEvent_mediaDiscovery_stayOnMediaDiscoveryOver180s() {
        let repo = MockAnalyticsRepository.newRepo
        let sut = AnalyticsEventUseCase(repository: repo)
        
        sut.sendAnalyticsEvent(.mediaDiscovery(.stayOnMediaDiscoveryOver180s))
        
        XCTAssertTrue(repo.type == .mediaDiscovery(.stayOnMediaDiscoveryOver180s))
    }
    
    // MARK: - Meetings
    
    func testSendEvent_meeting_endCallForAll() {
        let repo = MockAnalyticsRepository.newRepo
        let sut = AnalyticsEventUseCase(repository: repo)
        
        sut.sendAnalyticsEvent(.meetings(.endCallForAll))
        
        XCTAssertTrue(repo.type == .meetings(.endCallForAll))
    }
    
    func testSendEvent_meeting_endCallInNoParticipantsPopup() {
        let repo = MockAnalyticsRepository.newRepo
        let sut = AnalyticsEventUseCase(repository: repo)
        
        sut.sendAnalyticsEvent(.meetings(.endCallInNoParticipantsPopup))
        
        XCTAssertTrue(repo.type == .meetings(.endCallInNoParticipantsPopup))
    }
    
    func testSendEvent_meeting_stayOnCallInNoParticipantsPopup() {
        let repo = MockAnalyticsRepository.newRepo
        let sut = AnalyticsEventUseCase(repository: repo)
        
        sut.sendAnalyticsEvent(.meetings(.stayOnCallInNoParticipantsPopup))
        
        XCTAssertTrue(repo.type == .meetings(.stayOnCallInNoParticipantsPopup))
    }
    
    func testSendEvent_meeting_enableCallSoundNotifications() {
        let repo = MockAnalyticsRepository.newRepo
        let sut = AnalyticsEventUseCase(repository: repo)
        
        sut.sendAnalyticsEvent(.meetings(.enableCallSoundNotifications))
        
        XCTAssertTrue(repo.type == .meetings(.enableCallSoundNotifications))
    }
    
    func testSendEvent_meeting_disableCallSoundNotifications() {
        let repo = MockAnalyticsRepository.newRepo
        let sut = AnalyticsEventUseCase(repository: repo)
        
        sut.sendAnalyticsEvent(.meetings(.disableCallSoundNotifications))
        
        XCTAssertTrue(repo.type == .meetings(.disableCallSoundNotifications))
    }
    
    func testSendEvent_meeting_endCallWhenEmptyCallTimeout() {
        let repo = MockAnalyticsRepository.newRepo
        let sut = AnalyticsEventUseCase(repository: repo)
        
        sut.sendAnalyticsEvent(.meetings(.endCallWhenEmptyCallTimeout))
        
        XCTAssertTrue(repo.type == .meetings(.endCallWhenEmptyCallTimeout))
    }
    
    // MARK: - NSE
    
    func testSendEvent_nse_delayBetweenChatdAndApi() {
        let repo = MockAnalyticsRepository.newRepo
        let sut = AnalyticsEventUseCase(repository: repo)
        
        sut.sendAnalyticsEvent(.nse(.delayBetweenChatdAndApi))
        
        XCTAssertTrue(repo.type == .nse(.delayBetweenChatdAndApi))
    }
    
    func testSendEvent_nse_delayBetweenApiAndPushserver() {
        let repo = MockAnalyticsRepository.newRepo
        let sut = AnalyticsEventUseCase(repository: repo)
        
        sut.sendAnalyticsEvent(.nse(.delayBetweenApiAndPushserver))
        
        XCTAssertTrue(repo.type == .nse(.delayBetweenApiAndPushserver))
    }
    
    func testSendEvent_nse_delayBetweenPushserverAndNSE() {
        let repo = MockAnalyticsRepository.newRepo
        let sut = AnalyticsEventUseCase(repository: repo)
        
        sut.sendAnalyticsEvent(.nse(.delayBetweenPushserverAndNSE))
        
        XCTAssertTrue(repo.type == .nse(.delayBetweenPushserverAndNSE))
    }
    
    func testSendEvent_nse_willExpireAndMessageNotFound() {
        let repo = MockAnalyticsRepository.newRepo
        let sut = AnalyticsEventUseCase(repository: repo)
        
        sut.sendAnalyticsEvent(.nse(.willExpireAndMessageNotFound))
        
        XCTAssertTrue(repo.type == .nse(.willExpireAndMessageNotFound))
    }
    
    // MARK: - Extensions
    
    func testSendEvent_extensions_withoutNoDDatabase() {
        let repo = MockAnalyticsRepository.newRepo
        let sut = AnalyticsEventUseCase(repository: repo)
        
        sut.sendAnalyticsEvent(.extensions(.withoutNoDDatabase))
        
        XCTAssertTrue(repo.type == .extensions(.withoutNoDDatabase))
    }
    
    // MARK: - Download Behavior
    
    func testSendEvent_makeAvailableOfflinePhotosVideos() {
        let repo = MockAnalyticsRepository.newRepo
        let sut = AnalyticsEventUseCase(repository: repo)
        
        sut.sendAnalyticsEvent(.download(.makeAvailableOfflinePhotosVideos))
        
        XCTAssertTrue(repo.type == .download(.makeAvailableOfflinePhotosVideos))
    }
    
    func testSendEvent_saveToPhotos() {
        let repo = MockAnalyticsRepository.newRepo
        let sut = AnalyticsEventUseCase(repository: repo)
        
        sut.sendAnalyticsEvent(.download(.saveToPhotos))
        
        XCTAssertTrue(repo.type == .download(.saveToPhotos))
    }
    
    func testSendEvent_makeAvailableOffline() {
        let repo = MockAnalyticsRepository.newRepo
        let sut = AnalyticsEventUseCase(repository: repo)
        
        sut.sendAnalyticsEvent(.download(.makeAvailableOffline))
        
        XCTAssertTrue(repo.type == .download(.makeAvailableOffline))
    }
    
    func testSendEvent_exportFile() {
        let repo = MockAnalyticsRepository.newRepo
        let sut = AnalyticsEventUseCase(repository: repo)
        
        sut.sendAnalyticsEvent(.download(.exportFile))
        
        XCTAssertTrue(repo.type == .download(.exportFile))
    }
    
    // MARK: - Account Plan
    
    func testSendEvent_accountPlan_tappedFreePlan() {
        let repo = MockAnalyticsRepository.newRepo
        let sut = AnalyticsEventUseCase(repository: repo)
        
        sut.sendAnalyticsEvent(.accountPlans(.tapAccountPlanFreePlan))
        
        XCTAssertTrue(repo.type == .accountPlans(.tapAccountPlanFreePlan))
    }
    
    func testSendEvent_accountPlan_tappedProLite() {
        let repo = MockAnalyticsRepository.newRepo
        let sut = AnalyticsEventUseCase(repository: repo)
        
        sut.sendAnalyticsEvent(.accountPlans(.tapAccountPlanProLite))
        
        XCTAssertTrue(repo.type == .accountPlans(.tapAccountPlanProLite))
    }
    
    func testSendEvent_accountPlan_tappedProI() {
        let repo = MockAnalyticsRepository.newRepo
        let sut = AnalyticsEventUseCase(repository: repo)
        
        sut.sendAnalyticsEvent(.accountPlans(.tapAccountPlanProI))
        
        XCTAssertTrue(repo.type == .accountPlans(.tapAccountPlanProI))
    }
    
    func testSendEvent_accountPlan_tappedProII() {
        let repo = MockAnalyticsRepository.newRepo
        let sut = AnalyticsEventUseCase(repository: repo)
        
        sut.sendAnalyticsEvent(.accountPlans(.tapAccountPlanProII))
        
        XCTAssertTrue(repo.type == .accountPlans(.tapAccountPlanProII))
    }
    
    func testSendEvent_accountPlan_tappedProIII() {
        let repo = MockAnalyticsRepository.newRepo
        let sut = AnalyticsEventUseCase(repository: repo)
        
        sut.sendAnalyticsEvent(.accountPlans(.tapAccountPlanProIII))
        
        XCTAssertTrue(repo.type == .accountPlans(.tapAccountPlanProIII))
    }
}
