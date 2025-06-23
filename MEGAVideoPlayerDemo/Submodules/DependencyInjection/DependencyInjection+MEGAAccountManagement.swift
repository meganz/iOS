import MEGAAccountManagement

extension DependencyInjection {
    static func composeAccountManagement() {
        MEGAAccountManagement.DependencyInjection.sharedSdk = .sharedSdk
        MEGAAccountManagement.DependencyInjection.snackbarDisplayer = snackbarDisplayer
        MEGAAccountManagement.DependencyInjection.cacheService = defaultCacheService
        MEGAAccountManagement.DependencyInjection.permanentCacheService = permanentCacheService
        MEGAAccountManagement.DependencyInjection.refreshUserDataUseCase = refreshUserDataUseCase
        MEGAAccountManagement.DependencyInjection.passwordReminderUseLocalCache = true
    }

    static var offboardingUseCase: some OffboardingUseCaseProtocol {
        singletonOffboardingUseCase
    }

    static var refreshUserDataUseCase: some RefreshUserDataNotificationUseCaseProtocol {
        singletonRefreshUserDataUseCase
    }

    static var passwordReminderUseCase: any PasswordReminderUseCaseProtocol {
        MEGAAccountManagement.DependencyInjection.passwordReminderUseCase
    }

    // MARK: - Private

    private static var singletonOffboardingUseCase: OffboardingUseCase = {
        OffboardingUseCase(
            loginAPIRepository: loginAPIRepository,
            loginStoreRepository: loginStoreRepository,
            appLoadingManager: appLoadingManager,
            passwordReminderUseCase: passwordReminderUseCase,
            analyticsTracker: nil,
            connectionUseCase: connectionUseCase,
            snackbarDisplayer: snackbarDisplayer,
            preLogoutAction: {},
            postLogoutAction: {
                await PlayerAppViewModel.shared.launchViewModel.didLogout()
            }
        )
    }()

    private static var singletonRefreshUserDataUseCase: RefreshUserDataUseCase {
        RefreshUserDataUseCase()
    }
}

extension OffboardingViewModel {
    static var liveValue: OffboardingViewModel {
        OffboardingViewModel(offboardingUseCase: DependencyInjection.offboardingUseCase)
    }
}
