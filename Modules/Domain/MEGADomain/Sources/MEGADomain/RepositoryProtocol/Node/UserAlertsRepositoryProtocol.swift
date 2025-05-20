import MEGASwift

public protocol UserAlertsRepositoryProtocol: RepositoryProtocol, Sendable {
    var userAlertsUpdates: AnyAsyncSequence<[UserAlertEntity]> { get }
    var userContactRequestsUpdates: AnyAsyncSequence<[ContactRequestEntity]> { get }
    var notification: [UserAlertEntity]? { get }
    var incomingContactRequest: [ContactRequestEntity] { get }
}
