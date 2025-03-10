@testable import Accounts
import MEGADomain
import MEGASDKRepo
import MEGASwift
import Testing

@Suite("App loading use case tests")
struct AppLoadingUseCaseTests {
    
    private var requestProviderMock: RequestProviderMock
    private var appLoadingRepositoryMock: AppLoadingRepositoryMock
    private var sut: AppLoadingUseCase
    
    init() {
        requestProviderMock = RequestProviderMock()
        appLoadingRepositoryMock = AppLoadingRepositoryMock()
        sut = AppLoadingUseCase(requestProvider: requestProviderMock, appLoadingRepository: appLoadingRepositoryMock)
    }
    
    @Test("Test waiting reason")
    func testWaitingReason() {
        let expectedWaitingReason = WaitingReasonEntity.connectivity
        appLoadingRepositoryMock.waitingReason = expectedWaitingReason
        
        let waitingReason = sut.waitingReason
        
        #expect(waitingReason == expectedWaitingReason)
    }
    
    @Test("Test app loading start updates")
    func testAppLoadingStartUpdates() async {
        let requestEntity = RequestEntity(type: .fetchNodes)
        requestProviderMock.requestStartUpdates = AsyncStream { continuation in
            continuation.yield(requestEntity)
            continuation.finish()
        }.eraseToAnyAsyncSequence()
        
        let updates = await sut.appLoadingStartUpdates.first { requestEntity in
            requestEntity.type == .fetchNodes
        }
        
        #expect(updates == requestEntity)
    }
    
    @Test("Test app loading updates")
    func testAppLoadingUpdates() async {
        let requestEntity = RequestEntity(type: .fetchNodes)
        requestProviderMock.requestUpdates = AsyncStream { continuation in
            continuation.yield(requestEntity)
            continuation.finish()
        }.eraseToAnyAsyncSequence()
        
        let updates = await sut.appLoadingUpdates.first { requestEntity in
            requestEntity.type == .fetchNodes
        }
        
        #expect(updates == requestEntity)
    }
    
    @Test("Test app loading temporary error updates should return nil if success")
    func testAppLoadingTemporaryErrorUpdates_resultSuccess() async {
        let requestEntity = RequestEntity(type: .login)
        let result = Result<RequestEntity, ErrorEntity>.success(requestEntity)
        requestProviderMock.requestTemporaryErrorUpdates = AsyncStream { continuation in
            continuation.yield(result)
            continuation.finish()
        }.eraseToAnyAsyncSequence()
        
        let updates = await sut.appLoadingTemporaryErrorUpdates.first { _ in
            true
        }
        
        #expect(updates == nil)
    }
    
    @Test("Test app loading temporary error updates should return nil if error is try again")
    func testAppLoadingTemporaryErrorUpdates_errorTryAgain() async {
        let errorEntity = ErrorEntity(type: .tryAgain, name: "", value: 1)
        let result = Result<RequestEntity, ErrorEntity>.failure(errorEntity)
        requestProviderMock.requestTemporaryErrorUpdates = AsyncStream { continuation in
            continuation.yield(result)
            continuation.finish()
        }.eraseToAnyAsyncSequence()
        
        let updates = await sut.appLoadingTemporaryErrorUpdates.first { _ in
            true
        }
        
        #expect(updates == nil)
    }
    
    @Test("Test app loading temporary error updates")
    func testAppLoadingTemporaryErrorUpdates() async {
        let errorEntity = ErrorEntity(type: .badArguments, name: "", value: 1)
        let result = Result<RequestEntity, ErrorEntity>.failure(errorEntity)
        requestProviderMock.requestTemporaryErrorUpdates = AsyncStream { continuation in
            continuation.yield(result)
            continuation.finish()
        }.eraseToAnyAsyncSequence()
        
        let updates = await sut.appLoadingTemporaryErrorUpdates.first { _ in
            true
        }
        
        #expect(updates == result)
    }
    
    @Test("Test app loading finish updates")
    func testAppLoadingFinishUpdates() async {
        let requestEntity = RequestEntity(type: .login)
        let result = Result<RequestEntity, ErrorEntity>.success(requestEntity)
        requestProviderMock.requestFinishUpdates = AsyncStream { continuation in
            continuation.yield(result)
            continuation.finish()
        }.eraseToAnyAsyncSequence()
        
        let updates = await sut.appLoadingFinishUpdates.first { _ in
            true
        }
        
        #expect(updates == result)
    }
}

// Mocks
final class RequestProviderMock: RequestProviderProtocol, @unchecked Sendable {
    var requestStartUpdates: AnyAsyncSequence<RequestEntity> = AsyncStream { _ in }.eraseToAnyAsyncSequence()
    var requestUpdates: AnyAsyncSequence<RequestEntity> = AsyncStream { _ in }.eraseToAnyAsyncSequence()
    var requestTemporaryErrorUpdates: AnyAsyncSequence<Result<RequestEntity, ErrorEntity>> = AsyncStream { _ in }.eraseToAnyAsyncSequence()
    var requestFinishUpdates: AnyAsyncSequence<Result<RequestEntity, ErrorEntity>> = AsyncStream { _ in }.eraseToAnyAsyncSequence()
}

final class AppLoadingRepositoryMock: AppLoadingRepositoryProtocol, @unchecked Sendable {
    static let newRepo: AppLoadingRepositoryMock = {
        AppLoadingRepositoryMock()
    }()
    
    var waitingReason: WaitingReasonEntity = .apiLock
}
