import Foundation

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

    private let remoteFeatureFlagUseCase: any RemoteFeatureFlagUseCaseProtocol
    private let isLocalFeatureFlagEnabled: Bool

    public var domainName: String {
        remoteFeatureFlagUseCase.isFeatureFlagEnabled(for: .dotAppDomainExtension) && isLocalFeatureFlagEnabled
        ? DomainExtension.app.domain
        : DomainExtension.nz.domain
    }
    
    public init(
        remoteFeatureFlagUseCase: some RemoteFeatureFlagUseCaseProtocol,
        isLocalFeatureFlagEnabled: Bool
    ) {
        self.remoteFeatureFlagUseCase = remoteFeatureFlagUseCase
        self.isLocalFeatureFlagEnabled = isLocalFeatureFlagEnabled
    }
}
