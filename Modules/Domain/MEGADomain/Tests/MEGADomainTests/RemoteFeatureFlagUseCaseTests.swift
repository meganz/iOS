import MEGADomain
import MEGADomainMock
import XCTest

final class RemoteFeatureFlagUseCaseTests: XCTestCase {
    actor MockRemoteFeatureFlagRepository: RemoteFeatureFlagRepositoryProtocol {
        private var receivedFlags: [RemoteFeatureFlag] = []
        private let valueToReturn: Int
        init(valueToReturn: Int = 0) {
            self.valueToReturn = valueToReturn
        }
        func remoteFeatureFlagValue(for flag: RemoteFeatureFlag) async -> Int {
            receivedFlags.append(flag)
            return valueToReturn
        }
        
        func capturedReceivedFlags() async -> [RemoteFeatureFlag] {
            receivedFlags
        }
        
        static var newRepo: MockRemoteFeatureFlagRepository {
            Self()
        }
    }
    
    func testRemoteValue_asksRepo() async {
        let repo = MockRemoteFeatureFlagRepository()
        let usecase = RemoteFeatureFlagUseCase(repository: repo)
        _ = await usecase.isFeatureFlagEnabled(for: .chatMonetisation)
        let flags = await repo.capturedReceivedFlags()
        XCTAssertEqual(flags, [.chatMonetisation])
    }
    
    func testRemoteValue_returnsValueFromRepo() async {
        let repo = MockRemoteFeatureFlagRepository(valueToReturn: 123)
        let usecase = RemoteFeatureFlagUseCase(repository: repo)
        let value = await usecase.isFeatureFlagEnabled(for: .chatMonetisation)
        XCTAssertTrue(value)
    }
}
