import MEGADomain
import MEGADomainMock
import MEGASwift
import Testing

@Suite("RubbishBinSettingsUseCaseTests")
struct RubbishBinSettingsUseCaseTests {
    
    @Suite("Rubbish Bin Settings Update Succeed")
    struct RequestFinishSuccessTests {
        
        @Test("Successful call back only")
        func onRequestFinishSuccess() async {
            let succeedResult: Result<RubbishBinSettingsEntity, any Error> = .success(RubbishBinSettingsEntity(rubbishBinAutopurgePeriod: 7, rubbishBinCleaningSchedulerEnabled: true))
            let mockRepo = MockRubbishBinSettingsRepository(onRubbishBinSettinghsRequestFinish: SingleItemAsyncSequence(item: succeedResult).eraseToAnyAsyncSequence())
            let sut = RubbishBinSettingsUseCase(rubbishBinSettingsRepository: mockRepo)
            
            var iterator = sut.onRubbishBinSettinghsRequestFinish.makeAsyncIterator()
            let result = await iterator.next()
            
            #expect(throws: Never.self) { try result?.get() }
        }
    }
}
