@testable import MEGA
import MEGAAuthentication
import MEGADomain
import MEGADomainMock
import MEGAPreference
import Testing

struct ConfigureAuthEnvironmentUseCaseTests {

    @Test(arguments: [true, false])
    func isDebugLoggingEnabled(expected: Bool) {
        let preferenceUseCase = MockPreferenceUseCase(
            dict: [PreferenceKeyEntity.logging.rawValue: expected])
        let sut = Self.makeSUT(preferenceUseCase: preferenceUseCase)
        
        #expect(sut.isDebugLoggingEnabled == expected)
    }
    
    @Test func environments() {
        let expected = APIEnvironmentEntity.allCases.map { $0.rawValue }
        let sut = Self.makeSUT()
        
        #expect(sut.environments == expected)
    }
    
    @Test func toggleDebugLogging() {
        let metaData = LogMetadataEntity(suiteName: "Test")
        let manageLogsUseCase = MockManageLogsUseCase()
        let sut = Self.makeSUT(
            logMetadataEntity: metaData,
            manageLogsUseCase: manageLogsUseCase)
        
        sut.toggleDebugLogging()
        
        #expect(manageLogsUseCase.invocations == [.toggleLogs(logMetadata: metaData)])
    }
    
    @Test(arguments: [
            ("invalid", [MockAPIEnvironmentUseCase.Invocation]()),
            (APIEnvironmentEntity.staging.rawValue, [.changeAPIURL(environment: .staging)])
        ])
    func changeAPIURL(
        environment: APIEnvironmentTypeEntity,
        expectedInvocations: [MockAPIEnvironmentUseCase.Invocation]
    ) {
        let apiEnvironmentUseCase = MockAPIEnvironmentUseCase()
        var sut = Self.makeSUT(
            apiEnvironmentUseCase: apiEnvironmentUseCase)
        
        sut.changeAPIURL(environment)
        
        #expect(apiEnvironmentUseCase.invocations == expectedInvocations)
    }

    private static func makeSUT(
        logMetadataEntity: LogMetadataEntity = .init(),
        preferenceUseCase: any PreferenceUseCaseProtocol = MockPreferenceUseCase(),
        apiEnvironmentUseCase: some APIEnvironmentUseCaseProtocol = MockAPIEnvironmentUseCase(),
        manageLogsUseCase: some ManageLogsUseCaseProtocol = MockManageLogsUseCase()
    ) -> ConfigureAuthEnvironmentUseCase {
        .init(
            logMetadataEntity: logMetadataEntity,
            preferenceUseCase: preferenceUseCase,
            apiEnvironmentUseCase: apiEnvironmentUseCase,
            manageLogsUseCase: manageLogsUseCase)
    }
}
