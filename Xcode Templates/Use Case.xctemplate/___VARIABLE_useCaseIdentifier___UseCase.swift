
protocol ___VARIABLE_useCaseName:identifier___UseCaseProtocol {
}

struct ___VARIABLE_useCaseName:identifier___UseCase: ___VARIABLE_useCaseName:identifier___UseCaseProtocol {
    private let repo: ___VARIABLE_useCaseName:identifier___RepositoryProtocol
    
    init(repo: ___VARIABLE_useCaseName:identifier___RepositoryProtocol) {
        self.repo = repo
    }
}
