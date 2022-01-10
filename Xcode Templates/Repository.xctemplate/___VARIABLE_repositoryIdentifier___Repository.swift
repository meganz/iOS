
protocol ___VARIABLE_repositoryName:identifier___RepositoryProtocol {
}

struct ___VARIABLE_repositoryName:identifier___Repository: ___VARIABLE_repositoryName:identifier___RepositoryProtocol {
    private let sdk: MEGASdk
    
    init(sdk: MEGASdk) {
        self.sdk = sdk
    }
}
