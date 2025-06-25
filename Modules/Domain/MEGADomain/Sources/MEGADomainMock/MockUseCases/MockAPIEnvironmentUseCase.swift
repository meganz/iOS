import MEGADomain
import MEGASwift

public final class MockAPIEnvironmentUseCase: APIEnvironmentUseCaseProtocol, @unchecked Sendable {
    public enum Invocation: Equatable, Sendable {
        case changeAPIURL(environment: APIEnvironmentEntity)
    }
    @Atomic public var invocations = [Invocation]()
    
    public init() {}
    
    public func changeAPIURL(_ environment: APIEnvironmentEntity) {
        $invocations.mutate { $0.append(.changeAPIURL(environment: environment)) }
    }
}
