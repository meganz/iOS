import MEGADomain
import MEGADomainMock
import XCTest

final class MonitorCameraUploadUseCaseTests: XCTestCase {
    func testMonitorUploadStats_returnsExpectedResult() async {
        // Arrange
        let expected = CameraUploadStatsEntity(progress: 0.8, pendingFilesCount: 1, pendingVideosCount: 0)
        let cameraUploadRepository = MockCameraUploadsStatsRepository(currentStats: expected)
        
        let sut = makeSUT(
            cameraUploadRepository: cameraUploadRepository)
        
        // Act
        let result = await sut.monitorUploadStats().first(where: { _ in true })
        
        // Assert
        XCTAssertEqual(result, expected)
    }
    
    func testPossibleCameraUploadPausedReason_whenWiFiAndMobileDataOn_shouldReturnReasonNotPaused() {
        // Arrange
        let preferenceUseCase = MockPreferenceUseCase(dict: [.cameraUploadsCellularDataUsageAllowed: true])
        let networkMonitorUseCase = MockNetworkMonitorUseCase(
            connected: true,
            connectedViaWiFi: true)
        
        let sut = makeSUT(
            networkMonitorUseCase: networkMonitorUseCase,
            preferenceUseCase: preferenceUseCase)
        
        // Act
        let reason = sut.possibleCameraUploadPausedReason()
        
        // Assert
        XCTAssertEqual(reason, .notPaused)
    }
    
    func testPossibleCameraUploadPausedReason_whenWiFiOffAndMobileDataOnAndCellularDataUsageAllowedOff_shouldReturnReasonNoWifi() {
        // Arrange
        let preferenceUseCase = MockPreferenceUseCase(dict: [.cameraUploadsCellularDataUsageAllowed: false])
        let networkMonitorUseCase = MockNetworkMonitorUseCase(
            connected: true,
            connectedViaWiFi: false)
        
        let sut = makeSUT(
            networkMonitorUseCase: networkMonitorUseCase,
            preferenceUseCase: preferenceUseCase)
        
        // Act
        let reason = sut.possibleCameraUploadPausedReason()
        
        // Assert
        XCTAssertEqual(reason, .noWifi)
    }
    
    func testPossibleCameraUploadPausedReason_whenWiFiOffAndMobileDataOnAndCellularDataUsageAllowedOn_shouldReturnReasonNotPaused() {
        // Arrange
        let preferenceUseCase = MockPreferenceUseCase(dict: [.cameraUploadsCellularDataUsageAllowed: true])
        let networkMonitorUseCase = MockNetworkMonitorUseCase(
            connected: true,
            connectedViaWiFi: false)
        
        let sut = makeSUT(
            networkMonitorUseCase: networkMonitorUseCase,
            preferenceUseCase: preferenceUseCase)
        
        // Act
        let reason = sut.possibleCameraUploadPausedReason()
        
        // Assert
        XCTAssertEqual(reason, .notPaused)
    }
    
    func testPossibleCameraUploadPausedReason_whenWiFiOffAndMobileDataOffAndCellularDataUsageAllowedOn_shouldReturnReasonNoNetworkConnectivity() {
        // Arrange
        let preferenceUseCase = MockPreferenceUseCase(dict: [.cameraUploadsCellularDataUsageAllowed: true])
        let networkMonitorUseCase = MockNetworkMonitorUseCase(
            connected: false,
            connectedViaWiFi: false)
        
        let sut = makeSUT(
            networkMonitorUseCase: networkMonitorUseCase,
            preferenceUseCase: preferenceUseCase)
        
        // Act
        let reason = sut.possibleCameraUploadPausedReason()
        
        // Assert
        XCTAssertEqual(reason, .noNetworkConnectivity)
    }
    
    private func makeSUT(
        cameraUploadRepository: MockCameraUploadsStatsRepository = MockCameraUploadsStatsRepository(),
        networkMonitorUseCase: MockNetworkMonitorUseCase = MockNetworkMonitorUseCase(),
        preferenceUseCase: MockPreferenceUseCase = MockPreferenceUseCase()
    ) -> MonitorCameraUploadUseCase<MockCameraUploadsStatsRepository, MockNetworkMonitorUseCase, MockPreferenceUseCase> {
        MonitorCameraUploadUseCase(
            cameraUploadRepository: cameraUploadRepository,
            networkMonitorUseCase: networkMonitorUseCase,
            preferenceUseCase: preferenceUseCase)
    }
}
