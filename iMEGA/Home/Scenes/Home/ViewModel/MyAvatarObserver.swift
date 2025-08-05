import ChatRepo
import Combine
import Foundation
import MEGAAppPresentation
import MEGAAppSDKRepo
import MEGAAssets
import MEGADesignToken
import MEGADomain
import MEGARepo
import MEGASwift
import SwiftUI

@MainActor
final class MyAvatarObserver: MyAvatarObserverProtocol {
    private let avatarImageSubject = CurrentValueSubject<UIImage?, Never>(nil)
    private let userAlertCountSubject = CurrentValueSubject<Int, Never>(0)
    private let unreadNotificationCountSubject = CurrentValueSubject<Int, Never>(0)
    private let incomingContactRequestCountSubject = CurrentValueSubject<Int, Never>(0)
    private let avatarInitialSubject = CurrentValueSubject<String, Never>("")
    private let avatarBackgroundColorSubject = CurrentValueSubject<Color, Never>(TokenColors.Text.primary.swiftUI)
    private var monitorUserAlertsTask: Task<Void, Never>? {
        didSet {
            oldValue?.cancel()
        }
    }
    private var monitorContactRequestsTask: Task<Void, Never>? {
        didSet {
            oldValue?.cancel()
        }
    }
    private var monitorAvatarUpdatesTask: Task<Void, Never>? {
        didSet {
            oldValue?.cancel()
        }
    }
    private var monitorAvatarInitialUpdatesTask: Task<Void, Never>? {
        didSet {
            oldValue?.cancel()
        }
    }
    private var loadAvatarTask: Task<Void, Never>? {
        didSet {
            oldValue?.cancel()
        }
    }
    private var loadAvatarInitialTask: Task<Void, Never>? {
        didSet {
            oldValue?.cancel()
        }
    }
    
    // MARK: - Dependencies
    private let megaNotificationUseCase: any MEGANotificationUseCaseProtocol
    private var userImageUseCase: any UserImageUseCaseProtocol
    private let megaHandleUseCase: any MEGAHandleUseCaseProtocol
    private let accountUseCase: any AccountUseCaseProtocol
    private let userUpdatesRepository: any UserUpdateRepositoryProtocol
    private let userAttributeUseCase: any UserAttributeUseCaseProtocol
    
    private var myUserHandle: HandleEntity? {
        accountUseCase.currentUserHandle
    }
    
    // MARK: - MyAvatarObserverProtocol
    
    lazy var avatarInitial: AnyPublisher<String, Never> = avatarInitialSubject.removeDuplicates().eraseToAnyPublisher()
    lazy var avatarBackgroundColor: AnyPublisher<Color, Never> = avatarBackgroundColorSubject.removeDuplicates().eraseToAnyPublisher()
    lazy var avatar: AnyPublisher<UIImage?, Never> = avatarImageSubject.eraseToAnyPublisher()
    lazy var badge: AnyPublisher<String?, Never> = Publishers.CombineLatest3(
        userAlertCountSubject,
        unreadNotificationCountSubject,
        incomingContactRequestCountSubject
    ).map { (userAlertCount, unreadNotificationCount, incomingContactRequestCount) in
        let totalNumber = userAlertCount + incomingContactRequestCount + unreadNotificationCount
        return if totalNumber <= 0 {
            nil
        } else if totalNumber <= 99 {
            String(totalNumber)
        } else {
            "99+"
        }
    }
    .removeDuplicates()
    .eraseToAnyPublisher()
    
    static let shared = MyAvatarObserver(
        megaNotificationUseCase: MEGANotificationUseCase(
            userAlertsRepository: UserAlertsRepository.newRepo,
            notificationsUseCase: NotificationsUseCase(repository: NotificationsRepository.newRepo)
        ),
        userImageUseCase: UserImageUseCase(
            userImageRepo: UserImageRepository.newRepo,
            userStoreRepo: UserStoreRepository.newRepo,
            thumbnailRepo: ThumbnailRepository.newRepo,
            fileSystemRepo: FileSystemRepository.sharedRepo
        ),
        megaHandleUseCase: MEGAHandleUseCase(repo: MEGAHandleRepository.newRepo),
        accountUseCase: AccountUseCase(repository: AccountRepository.newRepo),
        userUpdatesRepository: UserUpdateRepository.newRepo,
        userAttributeUseCase: UserAttributeUseCase(repo: UserAttributeRepository.newRepo)
    )
    
    private init(
        megaNotificationUseCase: some MEGANotificationUseCaseProtocol,
        userImageUseCase: some UserImageUseCaseProtocol,
        megaHandleUseCase: some MEGAHandleUseCaseProtocol,
        accountUseCase: some AccountUseCaseProtocol,
        userUpdatesRepository: some UserUpdateRepositoryProtocol,
        userAttributeUseCase: some UserAttributeUseCaseProtocol
    ) {
        self.megaNotificationUseCase = megaNotificationUseCase
        self.userImageUseCase = userImageUseCase
        self.megaHandleUseCase = megaHandleUseCase
        self.accountUseCase = accountUseCase
        self.userUpdatesRepository = userUpdatesRepository
        self.userAttributeUseCase = userAttributeUseCase
        loadData()
        startMonitoringUpdates()
    }
    
    func onAppear() async {
        loadUserAlerts()
        loadUserContactRequest()
        await refreshUnreadNotificationCount()
    }
    
    // MARK: - Privates
    
    private func loadData() {
        loadAvatarInitial()
        loadAvatarBackgroundColor()
        loadUserAlerts()
        loadUserContactRequest()
        loadAvatar()
    }
    
    private func startMonitoringUpdates() {
        observeUserAlertsAndContactRequests()
        observeAvatarUpdates()
        observeAvatarInitialUpdates()
        observeAccountDidLogin()
        observeAccountDidLogout()
    }
    
    private func stopMonitoringUpdates() {
        monitorUserAlertsTask?.cancel()
        monitorContactRequestsTask?.cancel()
        monitorAvatarUpdatesTask?.cancel()
        monitorAvatarInitialUpdatesTask?.cancel()
        loadAvatarInitialTask?.cancel()
        loadAvatarTask?.cancel()
    }
    
    private func refreshUnreadNotificationCount() async {
        let unreadNotificationCount = await megaNotificationUseCase.unreadNotificationsCount()
        guard !Task.isCancelled else { return }
        unreadNotificationCountSubject.send(unreadNotificationCount)
    }
    
    private func observeUserAlertsAndContactRequests() {
        monitorUserAlertsTask = Task {
            for await _ in megaNotificationUseCase.userContactRequestsUpdates {
                guard !Task.isCancelled else { break }
                loadUserContactRequest()
            }
        }
        
        monitorContactRequestsTask = Task {
            for await _ in megaNotificationUseCase.userAlertsUpdates {
                guard !Task.isCancelled else { break }
                loadUserAlerts()
            }
        }
    }

    private func loadUserContactRequest() {
        let incomingContactRequestCount = megaNotificationUseCase.incomingContactRequest().count
        incomingContactRequestCountSubject.send(incomingContactRequestCount)
    }

    private func loadUserAlerts() {
        let userAlertCount = megaNotificationUseCase.relevantAndNotSeenAlerts()?.count ?? 0
        userAlertCountSubject.send(userAlertCount)
    }
    
    private func loadAvatar() {
        loadAvatarTask = Task {
            await loadAvatarImage(forceDownload: false)
        }
    }
    
    private func loadAvatarImage(forceDownload: Bool) async {
        guard let myUserHandle else { return }
        guard let base64Handle = megaHandleUseCase.base64Handle(forUserHandle: myUserHandle) else {
            MEGALogDebug("[MyAvatarViewModel] Base64 handle not found for handle")
            return
        }
        do {
            let path = try await userImageUseCase.fetchAvatar(base64Handle: base64Handle, forceDownload: forceDownload)
            guard !Task.isCancelled else { return }
            avatarImageSubject.send(UIImage(contentsOfFile: path))
        } catch {
            MEGALogDebug("[MyAvatarViewModel] Failed to fetch avatar for \(base64Handle) with \(error.localizedDescription)")
        }
    }
    
    private func observeAvatarUpdates() {
        monitorAvatarUpdatesTask = Task {
            for await userEntities in userUpdatesRepository.usersUpdates {
                guard userEntities.contains(where: { $0.handle == myUserHandle && $0.changes.contains(.avatar) }) else { continue }
                guard !Task.isCancelled else { break }
                await loadAvatarImage(forceDownload: true)
            }
        }
    }
    
    private func observeAvatarInitialUpdates() {
        monitorAvatarInitialUpdatesTask = Task {
            for await userEntities in userUpdatesRepository.usersUpdates {
                guard userEntities.contains(where: { $0.handle == myUserHandle && !$0.changes.isDisjoint(with: [.firstname, .lastname]) }) else { continue }
                guard !Task.isCancelled else { break }
                loadAvatarInitial()
            }
        }
    }
    
    private func observeAccountDidLogin() {
        Task {
            for await _ in NotificationCenter.default.publisher(for: .accountDidLogin).values {
                guard !Task.isCancelled else { break }
                loadData()
                startMonitoringUpdates()
            }
        }
    }
    
    private func observeAccountDidLogout() {
        Task {
            for await _ in NotificationCenter.default.publisher(for: .accountDidLogout).values {
                stopMonitoringUpdates()
            }
        }
    }
    
    private func loadAvatarInitial() {
        loadAvatarInitialTask = Task {
            let firstName = try? await userAttributeUseCase.getUserAttribute(for: .firstName)
            let avatarInitial = if let avatarInitial = firstName?.initialForAvatar(), !avatarInitial.isEmpty {
                avatarInitial
            } else {
                "M"
            }
            guard !Task.isCancelled else { return }
            avatarInitialSubject.send(avatarInitial)
        }
    }
    
    private func loadAvatarBackgroundColor() {
        let uiColor = if
            let myUserHandle,
            let base64Handle = megaHandleUseCase.base64Handle(forUserHandle: myUserHandle),
            let avatarBackgroundHexColor = userImageUseCase.avatarColorHex(forBase64UserHandle: base64Handle),
            let uiColor = UIColor.colorFromHexString(avatarBackgroundHexColor) {
            uiColor
        } else {
            TokenColors.Text.primary
        }
        
        avatarBackgroundColorSubject.send(uiColor.swiftUI)
    }
}

@MainActor
protocol MyAvatarObserverProtocol {
    var avatarInitial: AnyPublisher<String, Never> { get }
    var avatarBackgroundColor: AnyPublisher<Color, Never> { get }
    var avatar: AnyPublisher<UIImage?, Never> { get }
    var badge: AnyPublisher<String?, Never> { get }
    
    func onAppear() async
}
