import Foundation
import MEGAInfrastructure

extension DependencyInjection {
    static func composeInfrastructure() {
        MEGAInfrastructure.DependencyInjection.sharedSdk = .sharedSdk
    }

    static var defaultCacheService: some CacheServiceProtocol {
        UserDefaultsCacheService(userDefaults: userDefaults)
    }

    static var permanentCacheService: some CacheServiceProtocol {
        UserDefaultsCacheService(userDefaults: permanentUserDefaults)
    }

    static var userDefaults: UserDefaults {
        UserDefaults(suiteName: "nz.mega.MEGAVideoPlayerDemo") ?? .standard
    }

    static var permanentUserDefaults: UserDefaults {
        UserDefaults(suiteName: "nz.mega.MEGAVideoPlayerDemo.permanent") ?? .standard
    }

    static var keychainServiceName: String {
        "MEGAVideoPlayerDemo"
    }

    static var keychainAccount: String {
        "session"
    }
}
