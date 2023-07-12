import Combine
import Foundation
import MEGAData
import MEGADomain
import MEGASwift

final class AccountRepository: NSObject, AccountRepositoryProtocol {
    
    static var newRepo: AccountRepository {
        AccountRepository(sdk: MEGASdk.shared)
    }
    
    private let sdk: MEGASdk
    private let currentUserSource: CurrentUserSource
    
    private let requestResultSourcePublisher = PassthroughSubject<Result<AccountRequestEntity, Error>, Never>()
    var requestResultPublisher: AnyPublisher<Result<AccountRequestEntity, Error>, Never> {
        requestResultSourcePublisher.eraseToAnyPublisher()
    }
    
    private let contactRequestSourcePublisher = PassthroughSubject<[ContactRequestEntity], Never>()
    var contactRequestPublisher: AnyPublisher<[ContactRequestEntity], Never> {
        contactRequestSourcePublisher.eraseToAnyPublisher()
    }
    
    private let userAlertUpdateSourcePublisher = PassthroughSubject<[UserAlertEntity], Never>()
    var userAlertUpdatePublisher: AnyPublisher<[UserAlertEntity], Never> {
        userAlertUpdateSourcePublisher.eraseToAnyPublisher()
    }
    
    init(sdk: MEGASdk, currentUserSource: CurrentUserSource = .shared) {
        self.sdk = sdk
        self.currentUserSource = currentUserSource
    }

    func registerMEGARequestDelegate() async {
        sdk.add(self as (any MEGARequestDelegate))
    }
    
    func deRegisterMEGARequestDelegate() async {
        sdk.remove(self as (any MEGARequestDelegate))
    }
    
    func registerMEGAGlobalDelegate() async {
        sdk.add(self as (any MEGAGlobalDelegate))
    }
    
    func deRegisterMEGAGlobalDelegate() async {
        sdk.remove(self as (any MEGAGlobalDelegate))
    }

    var currentUserHandle: HandleEntity? {
        currentUserSource.currentUserHandle
    }
    
    func currentUser() async -> UserEntity? {
        await currentUserSource.currentUser()
    }
    
    var isGuest: Bool {
        currentUserSource.isGuest
    }
    
    var isMasterBusinessAccount: Bool {
        sdk.isMasterBusinessAccount
    }
    
    func isLoggedIn() -> Bool {
        currentUserSource.isLoggedIn
    }
    
    func contacts() -> [UserEntity] {
        sdk.contacts().toUserEntities()
    }
    
    func incomingContactsRequestsCount() -> Int {
        sdk.incomingContactRequests().size.intValue
    }
    
    func relevantUnseenUserAlertsCount() -> UInt {
        sdk.userAlertList().relevantUnseenCount
    }
    
    func getMyChatFilesFolder(completion: @escaping (Result<NodeEntity, AccountErrorEntity>) -> Void) {
        MyChatFilesFolderNodeAccess.shared.loadNode { myChatFilesFolderNode, _ in
            guard let myChatFilesFolderNode = myChatFilesFolderNode else {
                completion(.failure(AccountErrorEntity.nodeNotFound))
                return
            }
            
            completion(.success(myChatFilesFolderNode.toNodeEntity()))
        }
    }
    
    func totalNodesCount() -> UInt {
        sdk.totalNodes
    }
    
    func accountDetails() async throws -> AccountDetailsEntity {
        if let userAccountDetails = currentUserSource.accountDetails,
           !currentUserSource.shouldRefreshAccountDetails {
            return userAccountDetails
        }
        
        return try await withAsyncThrowingValue(in: { completion in
            sdk.getAccountDetails(with: RequestDelegate { [weak self] result in
                guard let self else { return }
                switch result {
                case .success(let request):
                    let userAccountDetails = request.megaAccountDetails.toAccountDetailsEntity()
                    currentUserSource.setAccountDetails(userAccountDetails)
                    currentUserSource.setShouldRefreshAccountDetails(false)
                    completion(.success(userAccountDetails))
                case .failure:
                    completion(.failure(AccountDetailsErrorEntity.generic))
                }
            })
        })
    }
    
    func upgradeSecurity() async throws -> Bool {
        try await withCheckedThrowingContinuation { continuation in
            guard Task.isCancelled == false else {
                continuation.resume(throwing: CancellationError())
                return
            }
            sdk.upgradeSecurity(with: RequestDelegate { (result) in
                guard Task.isCancelled == false else {
                    continuation.resume(throwing: CancellationError())
                    return
                }
                
                switch result {
                case .success:
                    continuation.resume(returning: true)
                case .failure:
                    continuation.resume(throwing: AccountErrorEntity.generic)
                }
            })
        }
    }
}

// MARK: - MEGARequestDelegate
extension AccountRepository: MEGARequestDelegate {
    func onRequestFinish(_ api: MEGASdk, request: MEGARequest, error: MEGAError) {
        guard error.type == .apiOk else {
            requestResultSourcePublisher.send(.failure(error))
            return
        }
        requestResultSourcePublisher.send(.success(request.toAccountRequestEntity()))
    }
}

// MARK: - MEGAGlobalDelegate
extension AccountRepository: MEGAGlobalDelegate {
    func onUserAlertsUpdate(_ api: MEGASdk, userAlertList: MEGAUserAlertList) {
        userAlertUpdateSourcePublisher.send(userAlertList.toUserAlertEntities())
    }
    
    func onContactRequestsUpdate(_ api: MEGASdk, contactRequestList: MEGAContactRequestList) {
        contactRequestSourcePublisher.send(contactRequestList.toContactRequestEntities())
    }
}
