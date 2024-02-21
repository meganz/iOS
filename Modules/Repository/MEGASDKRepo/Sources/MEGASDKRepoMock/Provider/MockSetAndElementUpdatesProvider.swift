import MEGADomain
import MEGASDKRepo
import MEGASwift

public struct MockSetAndElementUpdatesProvider: SetAndElementUpdatesProviderProtocol {
    
    private let (setUpdateStream, setUpdateContinuation) = AsyncStream
        .makeStream(of: [SetEntity].self, bufferingPolicy: .bufferingNewest(1))
    
    private let (setElementsUpdateStream, setElementsUpdateContinuation) = AsyncStream
        .makeStream(of: [SetElementEntity].self, bufferingPolicy: .bufferingNewest(1))
    
    public init() { }
    
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
