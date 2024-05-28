import MEGADomain
import MEGADomainMock
import XCTest

final class RemoteFeatureFlagUseCaseTests: XCTestCase {
    actor MockRemoteFeatureFlagRepository: RemoteFeatureFlagRepositoryProtocol {
        private var receivedFlags: [RemoteFeatureFlagName] = []
        private let valueToReturn: Int
        init(valueToReturn: Int = 0) {
            self.valueToReturn = valueToReturn
        }
        func remoteFeatureFlagValue(for flag: RemoteFeatureFlagName) async -> Int {
            receivedFlags.append(flag)
            return valueToReturn
        }
        
        func capturedReceivedFlags() async -> [RemoteFeatureFlagName] {
            receivedFlags
        }
        
        static var newRepo: MockRemoteFeatureFlagRepository {
            Self()
        }
    }
    
    func testRemoteValue_asksRepo() async {
        let repo = MockRemoteFeatureFlagRepository()
        let usecase = RemoteFeatureFlagUseCase(repository: repo)
        _ = await usecase.remoteFeatureFlagValue(for: "abc")
        let flags = await repo.capturedReceivedFlags()
        XCTAssertEqual(flags, ["abc"])
    }
    
    func testRemoteValue_returnsValueFromRepo() async {
        let repo = MockRemoteFeatureFlagRepository(valueToReturn: 123)
        let usecase = RemoteFeatureFlagUseCase(repository: repo)
        let value = await usecase.remoteFeatureFlagValue(for: "abc")
        XCTAssertEqual(value, 123)
    }
}
