import MEGADomain
import MEGADomainMock
import MEGAPreference
import MEGASwift
import Testing
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
        let preferenceUseCase = MockPreferenceUseCase(dict: [PreferenceKeyEntity.cameraUploadsCellularDataUsageAllowed.rawValue: true])
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
        let preferenceUseCase = MockPreferenceUseCase(dict: [PreferenceKeyEntity.cameraUploadsCellularDataUsageAllowed.rawValue: false])
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
        let preferenceUseCase = MockPreferenceUseCase(dict: [PreferenceKeyEntity.cameraUploadsCellularDataUsageAllowed.rawValue: true])
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
        let preferenceUseCase = MockPreferenceUseCase(dict: [PreferenceKeyEntity.cameraUploadsCellularDataUsageAllowed.rawValue: true])
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
    
    func testStatsEventSentOnBothNetworkAndStatsChangedEvents_shouldReturnTwoStatsResult() async {
        // Arrange
        let (networkStream, networkContinuation) = AsyncStream.makeStream(of: Bool.self, bufferingPolicy: .bufferingNewest(1))
        let networkMonitorUseCase = MockNetworkMonitorUseCase(
            connected: true,
            connectedViaWiFi: true,
            connectionSequence: networkStream.eraseToAnyAsyncSequence()
        )
        let cameraUploadRepository = MockCameraUploadsStatsRepository()
        let sut = makeSUT(
            cameraUploadRepository: cameraUploadRepository,
            networkMonitorUseCase: networkMonitorUseCase)
        
        // Act
        let exp = expectation(description: "For 2 results to be received")
        let task = Task<[CameraUploadStatsEntity], Never> {
            let result = await sut.monitorUploadStats()
                .prefix(2)
                .reduce(into: [CameraUploadStatsEntity]()) { $0.append($1) }
            exp.fulfill()
            return result
        }
        
        networkContinuation.yield(false)
        
        // Assert
        await fulfillment(of: [exp], timeout: 1)
        
        let results = await task.value
        XCTAssertEqual(results.count, 2)
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

@Suite("MonitorCameraUploadUseCase Tests")
struct MonitorCameraUploadUseCaseTestSuite {
    
    @Test
    func cameraUploadStats() async {
        let expected = CameraUploadStatsEntity(
            progress: 0.8, pendingFilesCount: 1, pendingVideosCount: 0)
        let cameraUploadRepository = MockCameraUploadsStatsRepository(
            currentStats: expected)
        let networkMonitorUseCase = MockNetworkMonitorUseCase(
            connected: true,
            connectedViaWiFi: true)
        let sut = Self.makeSUT(
            cameraUploadRepository: cameraUploadRepository,
            networkMonitorUseCase: networkMonitorUseCase)
        
        var sequence = sut.cameraUploadState.makeAsyncIterator()
        
        #expect(await sequence.next() == .uploadStats(expected))
    }
    
    @Test(arguments: [
        (false, false, false, CameraUploadStateEntity.PausedReason.NetworkIssue.noConnection),
        (true, false, false, .noWifi)
    ])
    func networkIssue(
        isConnected: Bool,
        isConnectedToWiFi: Bool,
        isCellularDataUsageAllowed: Bool,
        expectedNetworkIssue: CameraUploadStateEntity.PausedReason.NetworkIssue
    ) async {
        let cameraUploadRepository = MockCameraUploadsStatsRepository(
            currentStats: .init(
                progress: 0.8, pendingFilesCount: 1, pendingVideosCount: 0))
        let networkMonitorUseCase = MockNetworkMonitorUseCase(
            connected: isConnected,
            connectedViaWiFi: isConnectedToWiFi)
        let preferenceUseCase = MockPreferenceUseCase(
            dict: [PreferenceKeyEntity.cameraUploadsCellularDataUsageAllowed.rawValue: isCellularDataUsageAllowed])
        let sut = Self.makeSUT(
            cameraUploadRepository: cameraUploadRepository,
            networkMonitorUseCase: networkMonitorUseCase,
            preferenceUseCase: preferenceUseCase)
        
        var sequence = sut.cameraUploadState.makeAsyncIterator()
        
        #expect(await sequence.next() == .paused(reason: .networkIssue(expectedNetworkIssue)))
    }
    
    @Test
    func thermalState() async {
        let pausedReasonAsyncSequence = SingleItemAsyncSequence(
            item: CameraUploadMediaTypePausedReasonEntity.thermalState(.critical))
        .eraseToAnyAsyncSequence()
        let cameraUploadRepository = MockCameraUploadsStatsRepository(
            currentStats: .init(
                progress: 0.8, pendingFilesCount: 1, pendingVideosCount: 0),
            photosUploadPausedReason: pausedReasonAsyncSequence,
            videosUploadPausedReason: pausedReasonAsyncSequence)
        let networkMonitorUseCase = MockNetworkMonitorUseCase(
            connected: true,
            connectedViaWiFi: true)
        let sut = Self.makeSUT(
            cameraUploadRepository: cameraUploadRepository,
            networkMonitorUseCase: networkMonitorUseCase)
        
        var sequence = sut.cameraUploadState.makeAsyncIterator()
        
        #expect(await sequence.next() == .paused(reason: .highThermalState))
    }
    
    private static func makeSUT(
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
