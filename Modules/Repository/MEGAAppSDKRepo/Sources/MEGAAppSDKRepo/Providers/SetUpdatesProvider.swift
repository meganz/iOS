import MEGADomain
import MEGASdk
import MEGASwift

public protocol SetAndElementUpdatesProviderProtocol: Sendable {
    
    /// Set updates from `MEGAGlobalDelegate` `onSetsUpdate` as an `AnyAsyncSequence`
    /// - Parameter filteredBy: By setting which SetTypeEntities you want to filter the yielded results. If either no filter is set or an empty filter is provided, then it will not filter yielded updates.
    /// - Returns: `AnyAsyncSequence` that will call sdk.add on creation and sdk.remove onTermination of `AsyncStream`.
    /// It will yield `[SetEntity]` items until sequence terminated
    func setUpdates(filteredBy: [SetTypeEntity]) -> AnyAsyncSequence<[SetEntity]>
    
    /// SetElement updates from `MEGAGlobalDelegate` `onSetElementsUpdate` as an `AnyAsyncSequence`
    /// - Returns: `AnyAsyncSequence` that will call sdk.add on creation and sdk.remove onTermination of `AsyncStream`.
    /// It will yield `[SetElementEntity]` items until sequence terminated
    func setElementUpdates() -> AnyAsyncSequence<[SetElementEntity]>
}

public struct SetAndElementUpdatesProvider: SetAndElementUpdatesProviderProtocol {
    
    public init() { }
    
    public func setUpdates(filteredBy: [SetTypeEntity]) -> AnyAsyncSequence<[SetEntity]> {
        let updateHandlerManager = MEGAUpdateHandlerManager.shared
        return if filteredBy.isNotEmpty {
            updateHandlerManager.setsUpdates.filter {
                $0.contains(where: { set in filteredBy.contains(set.setType) })
            }
            .eraseToAnyAsyncSequence()
        } else {
            updateHandlerManager.setsUpdates
        }
    }
    
    public func setElementUpdates() -> AnyAsyncSequence<[SetElementEntity]> {
        MEGAUpdateHandlerManager.shared.setElementsUpdates
    }
}
