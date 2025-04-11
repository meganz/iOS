import MEGAAppSDKRepo
import MEGAAppSDKRepoMock
import MEGADomain
import MEGASwift
import Testing

@Suite("RubbishBinSettingsRepositoryTests")
struct RubbishBinSettingsRepositoryTests {
    
    @Suite("Get rubbish bin auto purge period")
    struct RubbishBinGetAutoPurgePeriodTests {
        
        @Test("Get auto purge period")
        func getRubbishBinAutopurgePeriod() async throws {
            let sut = makeSUT()
            
            let result = try await sut.getRubbishBinAutopurgePeriod()
            
            #expect(result.rubbishBinAutopurgePeriod == 90)
        }
    }
    
    @Suite("Clear Rubbish bin")
    struct RubbishBinCleanTests {
        @Test("Clean rubbish bin")
        func cleanRubbishBin() async throws {
            let sdk = MockSdk(requestResult: .success(MockRequest(handle: 1)))
            let sut = makeSUT(sdk: sdk)
            
            do {
                try await sut.cleanRubbishBin()
                #expect(sdk.cleanRubbishBinCallCount == 1)
            } catch {
                Issue.record("Expect success, but got an error")
            }
        }
        
        @Test("Catch up with SDK")
        func catchupWithSDK() async throws {
            let sdk = MockSdk(requestResult: .success(MockRequest(handle: 1)))
            let sut = makeSUT(sdk: sdk)
            
            do {
                try await sut.catchupWithSDK()
                #expect(sdk.catchupWithSDKCallCount == 1)
            } catch {
                Issue.record("Expect success, but got an error")
            }
        }
    }
    
    @Suite("Set rubbish bin auto purge period")
    struct RubbishBinSetAutoPurgePeriodTests {
        @Test("Set auto purge period")
        func setAutoPurgePerid() async {
            let sdk = MockSdk()
            let days = 14
            
            let sut = makeSUT(sdk: sdk)
            
            await sut.setRubbishBinAutopurgePeriod(in: days)
            
            #expect(sdk.rubbishBinAutopurgePeriodDays == days)
            #expect(sdk.setRubbishBinAutopurgePeriodCallCount == 1)
        }
    }
    
    private static func makeSUT(
        sdk: MockSdk = MockSdk(),
        isPaidAccount: Bool = false,
        serverSideRubbishBinAutopurgeEnabled: Bool = false
    ) -> RubbishBinSettingsRepository {
        RubbishBinSettingsRepository(
            sdk: sdk,
            isPaidAccount: isPaidAccount,
            serverSideRubbishBinAutopurgeEnabled: serverSideRubbishBinAutopurgeEnabled
        )
    }
}
