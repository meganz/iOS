import MEGADomain
import MEGADomainMock
import Testing

struct RemoteFeatureFlagUseCaseTests {
    
    @Suite("Remote feature flags")
    struct RemoteFeatureFlags {
        
        @Test("When requesting remote feature flag it should return value from repository",
              arguments: [(1, true), (0, false)])
        func returnValueFromRepository(flagValue: Int, expectedResult: Bool) {
            let repo = MockRemoteFeatureFlagRepository(valueToReturn: flagValue)
            let sut = RemoteFeatureFlagUseCaseTests.makeSUT(repository: repo)
            
            #expect(sut.isFeatureFlagEnabled(for: .chatMonetisation) == expectedResult)
            #expect(repo.receivedFlags == [.chatMonetisation])
        }
    }
    
    private static func makeSUT(
        repository: MockRemoteFeatureFlagRepository = MockRemoteFeatureFlagRepository()
    ) -> RemoteFeatureFlagUseCase<MockRemoteFeatureFlagRepository> {
        RemoteFeatureFlagUseCase(repository: repository)
    }
}
