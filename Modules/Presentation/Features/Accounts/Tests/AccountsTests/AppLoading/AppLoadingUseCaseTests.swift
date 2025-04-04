@testable import Accounts
import MEGAAppSDKRepo
import MEGADomain
import MEGADomainMock
import MEGASwift
import Testing

@Suite("App loading use case tests")
struct AppLoadingUseCaseTests {
    
    static func makeSUT(
        requestStatesRepository: MockRequestStatesRepository = MockRequestStatesRepository(),
        appLoadingRepository: AppLoadingRepositoryMock = AppLoadingRepositoryMock()
    ) -> AppLoadingUseCase {
        AppLoadingUseCase(requestStatesRepository: requestStatesRepository, appLoadingRepository: appLoadingRepository)
    }
    
    @Suite("Waiting reason")
    struct WaitingReasonTests {
        @Test("Should yield correct waiting reason")
        func shouldYieldCorrectReason() {
            let expectedWaitingReason = WaitingReasonEntity.connectivity
            let appLoadingRepositoryMock = AppLoadingRepositoryMock()
            appLoadingRepositoryMock.waitingReason = expectedWaitingReason
            
            let sut = makeSUT(appLoadingRepository: appLoadingRepositoryMock)
            
            #expect(sut.waitingReason == expectedWaitingReason)
        }
    }
    
    @Suite("App loading start updates")
    struct AppLoadingStartUpdatesTests {
        @Test
        func shouldFilterFetchNodesRequestOnly() async {
            let requestStatesRepository = MockRequestStatesRepository(
                requestStartUpdates: [
                    RequestEntity(type: .fetchNodes),
                    RequestEntity(type: .accountDetails)
                ].async.eraseToAnyAsyncSequence()
            )
            let sut = makeSUT(requestStatesRepository: requestStatesRepository)
            
            var requestEntities: [RequestEntity] = []
            for await requestEntity in sut.appLoadingStartUpdates {
                requestEntities.append(requestEntity)
            }
            
            #expect(requestEntities.map(\.type) == [.fetchNodes])
        }
    }
    @Suite("App loading updates")
    struct AppLoadingUpdatesTests {
        @Test
        func shouldFilterFetchNodesRequestOnly() async {
            let requestStatesRepository = MockRequestStatesRepository(
                requestUpdates: [
                    RequestEntity(type: .fetchNodes),
                    RequestEntity(type: .accountDetails)
                ].async.eraseToAnyAsyncSequence()
            )
            let sut = makeSUT(requestStatesRepository: requestStatesRepository)
            
            var requestEntities: [RequestEntity] = []
            for await requestEntity in sut.appLoadingUpdates {
                requestEntities.append(requestEntity)
            }
            
            #expect(requestEntities.map(\.type) == [.fetchNodes])
        }
    }
    
    @Suite("App loading temporary error updates")
    struct AppLoadingTemporaryErrorUpdatesTests {
        @Test(
            "Failure with error",
            arguments: zip(
                [
                    RequestResponseEntity(requestEntity: .init(type: .login), error: .init(type: .tryAgain, name: "", value: 1)),
                    RequestResponseEntity(requestEntity: .init(type: .login), error: .init(type: .badArguments, name: "", value: 1))
                ],
                [false, true]
            )
        )
        func shouldYieldUpdatesIfNotTryAgainError(requestResponseEntity: RequestResponseEntity, shouldYieldUpdates: Bool) async {
            let requestStatesRepository = MockRequestStatesRepository(requestTemporaryErrorUpdates: [requestResponseEntity].async.eraseToAnyAsyncSequence())
            let sut = makeSUT(requestStatesRepository: requestStatesRepository)
            
            var iterator = sut.appLoadingTemporaryErrorUpdates.makeAsyncIterator()
            let result = await iterator.next() != nil
            
            #expect(result == shouldYieldUpdates)
        }
    }
    
    @Suite("App loading finish updates")
    struct AppLoadingFinishUpdatesTests {
        @Test(
            "Request finish successfully",
            arguments: zip(
                [
                    RequestResponseEntity(requestEntity: .init(type: .login), error: .init(type: .ok, name: "", value: 1)),
                    RequestResponseEntity(requestEntity: .init(type: .login), error: .init(type: .tryAgain, name: "", value: 1)),
                    RequestResponseEntity(requestEntity: .init(type: .fetchNodes), error: .init(type: .ok, name: "", value: 1))
                ],
                [false, false, true]
            )
        )
        func shouldYiedUpdatesIfCompletedFetchNodesRequests(requestResponseEntity: RequestResponseEntity, shouldYieldUpdates: Bool) async {
            let requestStatesRepository = MockRequestStatesRepository(requestFinishUpdates: [requestResponseEntity].async.eraseToAnyAsyncSequence()
            )
            let sut = makeSUT(requestStatesRepository: requestStatesRepository)
            
            var iterator = sut.appLoadingFinishUpdates.makeAsyncIterator()
            let result = await iterator.next() != nil
            
            #expect(result == shouldYieldUpdates)
        }
    }
}

// Mocks
final class AppLoadingRepositoryMock: AppLoadingRepositoryProtocol, @unchecked Sendable {
    static let newRepo: AppLoadingRepositoryMock = {
        AppLoadingRepositoryMock()
    }()
    
    var waitingReason: WaitingReasonEntity = .apiLock
}
