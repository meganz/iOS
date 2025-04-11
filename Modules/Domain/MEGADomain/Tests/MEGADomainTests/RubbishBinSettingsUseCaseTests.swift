import MEGADomain
import MEGADomainMock
import MEGASwift
import Testing

@Suite("RubbishBinSettingsUseCaseTests")
struct RubbishBinSettingsUseCaseTests {
    
    @Suite("Get rubbish bin auto purge period")
    struct RubbishBinGetAutoPurgePeriodTests {
        
        @Test("Get auto purge period")
        func getRubbishBinAutopurgePeriod() async throws {
            let rubbishBinSettingsEntity: RubbishBinSettingsEntity = RubbishBinSettingsEntity(rubbishBinAutopurgePeriod: 7, rubbishBinCleaningSchedulerEnabled: true)
            let mockRepo = MockRubbishBinSettingsRepository(rubbishBinSettingsEntity: rubbishBinSettingsEntity)
            let sut = RubbishBinSettingsUseCase(rubbishBinSettingsRepository: mockRepo)
            
            let result = try await sut.getRubbishBinAutopurgePeriod()
            
            #expect(result.rubbishBinAutopurgePeriod == 7)
            #expect(result.rubbishBinCleaningSchedulerEnabled == true)
        }
    }
    
    @Suite("Rubbish bin clean tests")
    struct RubbishBinCleanTests {
        @Test("Clean rubbish bin")
        func cleanRubbishBin() async {
            let mockRepo = MockRubbishBinSettingsRepository()
            
            let sut = RubbishBinSettingsUseCase(rubbishBinSettingsRepository: mockRepo)
            
            do {
                try await sut.cleanRubbishBin()
                #expect(mockRepo.cleanRubbishBinCalled)
            } catch {
                Issue.record("Expect cleanRubbishBinCalled, but not")
            }
        }
        
        @Test("Catch up with SDK")
        func catchupWithSDK() async {
            let mockRepo = MockRubbishBinSettingsRepository()
            
            let sut = RubbishBinSettingsUseCase(rubbishBinSettingsRepository: mockRepo)
            
            do {
                try await sut.catchupWithSDK()
                #expect(mockRepo.catchupWithSDKCalled)
            } catch {
                Issue.record("Expect catchupWithSDKCalled, but not")
            }
        }
    }
    
    @Suite("Set rubbish bin auto purge period")
    struct RubbishBinSetAutoPurgePeriodTests {
        @Test("Set auto purge period")
        func setAutoPurgePerid() async {
            let mockRepo = MockRubbishBinSettingsRepository()
            let days = 14
            
            let sut = RubbishBinSettingsUseCase(rubbishBinSettingsRepository: mockRepo)
            
            await sut.setRubbishBinAutopurgePeriod(in: days)
            
            #expect(mockRepo.rubbishBinAutopurgePeriodDays == days)
            #expect(mockRepo.setRubbishBinAutopurgePeriodCalled)
        }
    }
}
