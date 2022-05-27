
protocol ___VARIABLE_useCaseName:identifier___UseCaseProtocol {
}

struct ___VARIABLE_useCaseName:identifier___UseCase<T: ___VARIABLE_useCaseName:identifier___RepositoryProtocol>: ___VARIABLE_useCaseName:identifier___UseCaseProtocol {
    private let repository: T
    
    init(repository: T) {
        self.repository = repository
    }
}
