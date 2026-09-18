import Foundation
import MEGAAppPresentation
import MEGADomain
import MEGASwift

public struct ContentLibraries: Sendable {
    
    nonisolated(unsafe) static var _configuration: Atomic<Configuration?> = Atomic(wrappedValue: nil)
    
    public static var configuration: Configuration {
        get {
            guard let configuration = _configuration.wrappedValue else {
                fatalError("Module has not been configured before usage")
            }
            return configuration
        }
        set { _configuration.mutate { $0 = newValue } }
    }
    
    public static func makeOfflineFileOpenGuard() -> (any OfflineFileOpenGuarding)? {
        _configuration.wrappedValue?.makeOfflineFileOpenGuard?()
    }
    
    public struct Configuration: Sendable {
        let sensitiveNodeUseCase: any SensitiveNodeUseCaseProtocol
        let remoteFeatureFlagUseCase: any RemoteFeatureFlagUseCaseProtocol
        let featureFlagProvider: any FeatureFlagProviderProtocol
        let nodeUseCase: any NodeUseCaseProtocol
        public let makeOfflineFileOpenGuard: (@Sendable () -> any OfflineFileOpenGuarding)?
        
        public init(
            sensitiveNodeUseCase: some SensitiveNodeUseCaseProtocol,
            remoteFeatureFlagUseCase: some RemoteFeatureFlagUseCaseProtocol,
            featureFlagProvider: some FeatureFlagProviderProtocol,
            nodeUseCase: some NodeUseCaseProtocol,
            makeOfflineFileOpenGuard: (@Sendable () -> any OfflineFileOpenGuarding)? = nil
        ) {
            self.sensitiveNodeUseCase = sensitiveNodeUseCase
            self.remoteFeatureFlagUseCase = remoteFeatureFlagUseCase
            self.nodeUseCase = nodeUseCase
            self.featureFlagProvider = featureFlagProvider
            self.makeOfflineFileOpenGuard = makeOfflineFileOpenGuard
        }
    }
}
