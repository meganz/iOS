import Foundation
import MEGADomain
import MEGASdk

final class MEGAUpdateHandler: NSObject, Sendable {
    typealias NodesUpdateHandler = @Sendable ([NodeEntity]) -> Void
    typealias UsersUpdateHandler = @Sendable ([UserEntity]) -> Void
    
    typealias RequestStartHandler = @Sendable (RequestEntity) -> Void
    typealias RequestUpdateHandler = @Sendable (RequestEntity) -> Void
    typealias RequestTemporaryErrorHandler = @Sendable (Result<RequestEntity, ErrorEntity>) -> Void
    typealias RequestFinishHandler = @Sendable (Result<RequestEntity, ErrorEntity>) -> Void
    
    let onNodesUpdate: NodesUpdateHandler?
    let onUsersUpdate: UsersUpdateHandler?
    
    let onRequestStart: RequestStartHandler?
    let onRequestUpdate: RequestUpdateHandler?
    let onRequestTemporaryError: RequestTemporaryErrorHandler?
    let onRequestFinish: RequestFinishHandler?
    
    init(
        onNodesUpdate: NodesUpdateHandler? = nil,
        onUsersUpdate: UsersUpdateHandler? = nil,
        onRequestStart: RequestStartHandler? = nil,
        onRequestUpdate: RequestUpdateHandler? = nil,
        onRequestTemporaryError: RequestTemporaryErrorHandler? = nil,
        onRequestFinish: RequestFinishHandler? = nil
    ) {
        self.onNodesUpdate = onNodesUpdate
        self.onUsersUpdate = onUsersUpdate
        self.onRequestStart = onRequestStart
        self.onRequestUpdate = onRequestUpdate
        self.onRequestTemporaryError = onRequestTemporaryError
        self.onRequestFinish = onRequestFinish
    }
}
