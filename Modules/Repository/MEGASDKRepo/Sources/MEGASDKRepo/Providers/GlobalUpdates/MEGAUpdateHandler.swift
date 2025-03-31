import Foundation
import MEGADomain
import MEGASdk

final class MEGAUpdateHandler: NSObject, Sendable {
    typealias NodesUpdateHandler = @Sendable ([NodeEntity]) -> Void
    typealias UsersUpdateHandler = @Sendable ([UserEntity]) -> Void
    
    typealias RequestStartHandler = @Sendable (RequestEntity) -> Void
    typealias RequestUpdateHandler = @Sendable (RequestEntity) -> Void
    typealias RequestTemporaryErrorHandler = @Sendable (RequestResponseEntity) -> Void
    typealias RequestFinishHandler = @Sendable (RequestResponseEntity) -> Void
    
    typealias TransferFinishHandler = @Sendable (Result<TransferEntity, ErrorEntity>) -> Void
    
    let onNodesUpdate: NodesUpdateHandler?
    let onUsersUpdate: UsersUpdateHandler?
    
    let onRequestStart: RequestStartHandler?
    let onRequestUpdate: RequestUpdateHandler?
    let onRequestTemporaryError: RequestTemporaryErrorHandler?
    let onRequestFinish: RequestFinishHandler?
    
    let onTransferFinish: TransferFinishHandler?
    
    init(
        onNodesUpdate: NodesUpdateHandler? = nil,
        onUsersUpdate: UsersUpdateHandler? = nil,
        onRequestStart: RequestStartHandler? = nil,
        onRequestUpdate: RequestUpdateHandler? = nil,
        onRequestTemporaryError: RequestTemporaryErrorHandler? = nil,
        onRequestFinish: RequestFinishHandler? = nil,
        onTransferFinish: TransferFinishHandler? = nil
    ) {
        self.onNodesUpdate = onNodesUpdate
        self.onUsersUpdate = onUsersUpdate
        self.onRequestStart = onRequestStart
        self.onRequestUpdate = onRequestUpdate
        self.onRequestTemporaryError = onRequestTemporaryError
        self.onRequestFinish = onRequestFinish
        self.onTransferFinish = onTransferFinish
    }
}
