import MEGAAppSDKRepo
import MEGADomain
import MEGASwift

public struct MockSetAndElementUpdatesProvider: SetAndElementUpdatesProviderProtocol {
    private let setUpdateStream: AsyncStream<[SetEntity]>
    private let setUpdateContinuation: AsyncStream<[SetEntity]>.Continuation
    private let setElementsUpdateStream: AsyncStream<[SetElementEntity]>
    private let setElementsUpdateContinuation: AsyncStream<[SetElementEntity]>.Continuation
    
    public init() {
        let setUpdateStreamTupple = AsyncStream.makeStream(of: [SetEntity].self, bufferingPolicy: .bufferingNewest(1))
        setUpdateStream = setUpdateStreamTupple.stream
        setUpdateContinuation = setUpdateStreamTupple.continuation
        
        let setElementsUpdateStreamTupple = AsyncStream.makeStream(of: [SetElementEntity].self, bufferingPolicy: .bufferingNewest(1))
        setElementsUpdateStream = setElementsUpdateStreamTupple.stream
        setElementsUpdateContinuation = setElementsUpdateStreamTupple.continuation
    }
    
    public func setUpdates(filteredBy: [SetTypeEntity]) -> AnyAsyncSequence<[SetEntity]> {
        setUpdateStream.eraseToAnyAsyncSequence()
    }
    
    public func setElementUpdates() -> AnyAsyncSequence<[SetElementEntity]> {
        setElementsUpdateStream.eraseToAnyAsyncSequence()
    }
    
    public func mockSendSetUpdate(setUpdate: [SetEntity]) {
        setUpdateContinuation.yield(setUpdate)
    }
    
    public func mockSendSetElementUpdate(setElementUpdate: [SetElementEntity]) {
        setElementsUpdateContinuation.yield(setElementUpdate)
    }
}
