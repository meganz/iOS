extension ___VARIABLE_repositoryName:identifier___Repository {
    static let `default` = ___VARIABLE_repositoryName:identifier___Repository(sdk: MEGASdkManager.sharedMEGASdk())
}

struct ___VARIABLE_repositoryName:identifier___Repository: ___VARIABLE_repositoryName:identifier___RepositoryProtocol {
    private let sdk: MEGASdk
    
    init(sdk: MEGASdk) {
        self.sdk = sdk
    }
}
