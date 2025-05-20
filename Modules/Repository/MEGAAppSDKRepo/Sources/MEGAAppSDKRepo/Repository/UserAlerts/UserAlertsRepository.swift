import Foundation
import MEGADomain
import MEGASdk
import MEGASwift

public struct UserAlertsRepository: UserAlertsRepositoryProtocol {
    public static var newRepo: UserAlertsRepository {
        UserAlertsRepository()
    }
    
    public var userAlertsUpdates: AnyAsyncSequence<[UserAlertEntity]> {
        MEGAUpdateHandlerManager.shared.userAlertUpdates
    }
    
    public var userContactRequestsUpdates: AnyAsyncSequence<[ContactRequestEntity]> {
        MEGAUpdateHandlerManager.shared.contactRequestUpdates
    }
    
    public var notification: [UserAlertEntity]? {
        MEGASdk.sharedSdk.userAlertList().toUserAlertEntities()
    }

    public var incomingContactRequest: [ContactRequestEntity] {
        MEGASdk.sharedSdk.incomingContactRequests().toContactRequestEntities()
    }
}
