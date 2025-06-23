import Foundation
import MEGAAuthentication
import MEGAPresentation
import MEGAInfrastructure

extension DependencyInjection {
    static func composeAuthentication() {
        MEGAAuthentication.DependencyInjection.sharedSdk = .sharedSdk
        MEGAAuthentication.DependencyInjection.secondarySceneViewModel = secondarySceneViewModel
        MEGAAuthentication.DependencyInjection.snackbarDisplayer = snackbarDisplayer
        MEGAAuthentication.DependencyInjection.permanentCacheService = permanentCacheService
        MEGAAuthentication.DependencyInjection.keychainServiceName = keychainServiceName
        MEGAAuthentication.DependencyInjection.keychainAccount = keychainAccount
        MEGAAuthentication.DependencyInjection.fetchNodesEnabled = true
        MEGAAuthentication.DependencyInjection.shouldIncludeFastLoginTimeout = true
        MEGAAuthentication.DependencyInjection.updateDuplicateSessionForLogin = true
    }

    static var loginAPIRepository: some LoginAPIRepositoryProtocol {
        MEGAAuthentication.DependencyInjection.loginAPIRepository
    }

    static var loginStoreRepository: some LoginStoreRepositoryProtocol {
        MEGAAuthentication.DependencyInjection.loginStoreRepository
    }
}
