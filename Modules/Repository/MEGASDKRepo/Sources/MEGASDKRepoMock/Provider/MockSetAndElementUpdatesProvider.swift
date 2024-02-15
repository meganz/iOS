import MEGADomain
import MEGASDKRepo
import MEGASwift

public struct MockSetAndElementUpdatesProvider: SetAndElementUpdatesProviderProtocol {
    
    private let (setUpdateStream, setUpdateContinuation) = AsyncStream
        .makeStream(of: [SetEntity].self, bufferingPolicy: .bufferingNewest(1))
    
    public init() { }
    
    public func setUpdates(filteredBy: [SetTypeEntity]) -> AnyAsyncSequence<[SetEntity]> {
        setUpdateStream.eraseToAnyAsyncSequence()
    }
    
    public func mockSendSetUpdate(setUpdate: [SetEntity]) {
        setUpdateContinuation.yield(setUpdate)
    }
}
