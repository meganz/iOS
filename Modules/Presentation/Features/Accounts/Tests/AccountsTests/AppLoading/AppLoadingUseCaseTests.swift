@testable import Accounts
import MEGADomain
import MEGADomainMock
import MEGASDKRepo
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
        @Test("Success result")
        func shouldSkipUpdates() async {
            let requestStatesRepository = MockRequestStatesRepository(requestTemporaryErrorUpdates: [Result.success(RequestEntity(type: .login))].async.eraseToAnyAsyncSequence()
            )
            let sut = makeSUT(requestStatesRepository: requestStatesRepository)
            var iterator = sut.appLoadingTemporaryErrorUpdates.makeAsyncIterator()
            #expect(await iterator.next() == nil)
        }
        
        @Test("Failure with tryAgain error")
        func shouldSkipUpdatesWithTryAgainError() async {
            let requestStatesRepository = MockRequestStatesRepository(requestTemporaryErrorUpdates: [Result.failure(ErrorEntity(type: .tryAgain, name: "", value: 1))].async.eraseToAnyAsyncSequence()
            )
            let sut = makeSUT(requestStatesRepository: requestStatesRepository)
            var iterator = sut.appLoadingTemporaryErrorUpdates.makeAsyncIterator()
            #expect(await iterator.next() == nil)
        }
        
        @Test("Failure with error other than tryAgain")
        func shouldYieldUpdates() async {
            let requestStatesRepository = MockRequestStatesRepository(requestTemporaryErrorUpdates: [Result.failure(ErrorEntity(type: .badArguments, name: "", value: 1))].async.eraseToAnyAsyncSequence()
            )
            let sut = makeSUT(requestStatesRepository: requestStatesRepository)
            var iterator = sut.appLoadingTemporaryErrorUpdates.makeAsyncIterator()
            let result = await iterator.next()
            
            #expect(performing: {
                try result?.get()
            }, throws: { error in
                if let errorEntity = error as? ErrorEntity, errorEntity.type == .badArguments {
                    true
                } else {
                    false
                }
            })
        }
    }
    
    @Suite("App loading finish updates")
    struct AppLoadingFinishUpdatesTests {
        @Test("Request finish successfully")
        func shouldYiedSuccessUpdates() async {
            let requestStatesRepository = MockRequestStatesRepository(requestFinishUpdates: [Result.success(RequestEntity(type: .login))].async.eraseToAnyAsyncSequence()
            )
            let sut = makeSUT(requestStatesRepository: requestStatesRepository)
            var iterator = sut.appLoadingFinishUpdates.makeAsyncIterator()
            let result = try? await iterator.next()?.get()
            #expect(result?.type == .login)
        }
        
        @Test("Request finish with error")
        func shouldYiedErrorUpdates() async {
            let requestStatesRepository = MockRequestStatesRepository(requestFinishUpdates: [Result.failure(ErrorEntity(type: .badArguments, name: "", value: 1))].async.eraseToAnyAsyncSequence()
            )
            let sut = makeSUT(requestStatesRepository: requestStatesRepository)
            var iterator = sut.appLoadingFinishUpdates.makeAsyncIterator()
            
            await #expect(performing: {
                try await iterator.next()?.get()
            }, throws: { error in
                if let errorEntity = error as? ErrorEntity, errorEntity.type == .badArguments {
                    true
                } else {
                    false
                }
            })
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
