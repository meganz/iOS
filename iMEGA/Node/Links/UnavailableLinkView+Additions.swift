import MEGAAppPresentation

extension UnavailableLinkView {
    @objc var domainName: String {
        DIContainer.appDomainUseCase.domainName
    }
}
