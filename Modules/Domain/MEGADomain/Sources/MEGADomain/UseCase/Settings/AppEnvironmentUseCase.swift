import MEGAInfrastructure

public typealias AppEnvironmentUseCaseProtocol = MEGAInfrastructure.AppEnvironmentUseCaseProtocol
public typealias AppEnvironmentUseCase = MEGAInfrastructure.AppEnvironmentUseCase

public extension AppEnvironmentUseCase {
    static let appShared = AppEnvironmentUseCase.shared
}
