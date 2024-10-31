import Foundation
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
    
    public struct Configuration: Sendable {
        let sensitiveNodeUseCase: any SensitiveNodeUseCaseProtocol
        let nodeUseCase: any NodeUseCaseProtocol
        let isAlbumPerformanceImprovementsEnabled: @Sendable () -> Bool
        
        public init(
            sensitiveNodeUseCase: some SensitiveNodeUseCaseProtocol,
            nodeUseCase: some NodeUseCaseProtocol,
            isAlbumPerformanceImprovementsEnabled: @escaping @Sendable () -> Bool
        ) {
            self.sensitiveNodeUseCase = sensitiveNodeUseCase
            self.nodeUseCase = nodeUseCase
            self.isAlbumPerformanceImprovementsEnabled = isAlbumPerformanceImprovementsEnabled
        }
    }
}
