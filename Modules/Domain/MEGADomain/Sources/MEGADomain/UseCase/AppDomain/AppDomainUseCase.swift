import Foundation
import MEGAPreference

public protocol AppDomainUseCaseProtocol: Sendable {
    var domainName: String { get }
}

public struct AppDomainUseCase: AppDomainUseCaseProtocol {
    private enum DomainExtension {
        case app
        case nz

        var domain: String {
            switch self {
            case .app:
                return "mega.app"
            case .nz:
                return "mega.nz"
            }
        }
    }

    @PreferenceWrapper(key: PreferenceKeyEntity.isDomainNameMEGADotApp, defaultValue: false)
    private var isDomainNameMEGADotApp: Bool

    public var domainName: String {
        guard isDomainNameMEGADotApp else { return DomainExtension.nz.domain }
        return DomainExtension.app.domain
    }
    
    public init(
        preferenceUseCase: some PreferenceUseCaseProtocol,
        remoteFeatureFlagUseCase: some RemoteFeatureFlagUseCaseProtocol,
        isLocalFeatureFlagEnabled: Bool
    ) {
        $isDomainNameMEGADotApp.useCase = preferenceUseCase
        isDomainNameMEGADotApp = remoteFeatureFlagUseCase
            .isFeatureFlagEnabled(for: .dotAppDomainExtension) && isLocalFeatureFlagEnabled
    }
}
