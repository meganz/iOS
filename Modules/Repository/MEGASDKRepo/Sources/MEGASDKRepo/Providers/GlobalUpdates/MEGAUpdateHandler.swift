import Foundation
import MEGADomain
import MEGASdk

final class MEGAUpdateHandler: NSObject, Sendable {
    typealias NodesUpdateHandler = @Sendable ([NodeEntity]) -> Void
    typealias UsersUpdateHandler = @Sendable ([UserEntity]) -> Void
    
    typealias RequestStartHandler = @Sendable (RequestEntity) -> Void
    typealias RequestFinishHandler = @Sendable (Result<RequestEntity, ErrorEntity>) -> Void
    
    let onNodesUpdate: NodesUpdateHandler?
    let onUsersUpdate: UsersUpdateHandler?
    
    let onRequestStart: RequestStartHandler?
    let onRequestFinish: RequestFinishHandler?
    
    init(
        onNodesUpdate: NodesUpdateHandler? = nil,
        onUsersUpdate: UsersUpdateHandler? = nil,
        onRequestStart: RequestStartHandler? = nil,
        onRequestFinish: RequestFinishHandler? = nil
    ) {
        self.onNodesUpdate = onNodesUpdate
        self.onUsersUpdate = onUsersUpdate
        self.onRequestStart = onRequestStart
        self.onRequestFinish = onRequestFinish
    }
}
