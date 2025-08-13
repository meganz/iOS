import MEGADomain

public struct MockAppDomainUseCase: AppDomainUseCaseProtocol {
    public let domainName: String

    public init(domainName: String) {
        self.domainName = domainName
    }
}
