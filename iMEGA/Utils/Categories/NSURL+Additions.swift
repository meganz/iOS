import MEGAAppPresentation

extension NSURL {
    @objc var domainName: String {
        DIContainer.appDomainUseCase.domainName
    }
}

