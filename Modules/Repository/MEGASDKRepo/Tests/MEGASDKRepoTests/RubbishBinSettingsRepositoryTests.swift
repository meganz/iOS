import MEGADomain
import MEGASDKRepo
import MEGASDKRepoMock
import MEGASwift
import Testing

@Suite("RubbishBinSettingsRepositoryTests")
struct RubbishBinSettingsRepositoryTests {
    
    @Suite("Rubbish Bin Settings Update Succeed")
    struct RequestFinishSuccessTests {
        
        @Test("Successful call back only")
        func onRequestFinishSuccess() async {
            let sut = makeSUT()
            
            var iterator = sut.onRubbishBinSettinghsRequestFinish.makeAsyncIterator()
            let result = await iterator.next()
            
            #expect(throws: Never.self) { try result?.get() }
        }
    }
    
    private static func makeSUT() -> RubbishBinSettingsRepository {
        let succeedResult: Result<RubbishBinSettingsEntity, any Error> = .success(RubbishBinSettingsEntity(rubbishBinAutopurgePeriod: 7, rubbishBinCleaningSchedulerEnabled: true))
        let mockProvider = MockRubbishBinSettingsUpdateProvider(onRubbishBinSettingsRequestFinish: SingleItemAsyncSequence(item: succeedResult).eraseToAnyAsyncSequence())
        
        return RubbishBinSettingsRepository(rubbishBinSettingsUpdatesProvider: mockProvider)
    }
}
