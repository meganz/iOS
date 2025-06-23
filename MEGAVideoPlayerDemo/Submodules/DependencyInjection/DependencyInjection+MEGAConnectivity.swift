import MEGAConnectivity

extension DependencyInjection {
    static var connectionUseCase: some ConnectionUseCaseProtocol {
        MEGAConnectivity.DependencyInjection.singletonConnectionUseCase
    }
}
