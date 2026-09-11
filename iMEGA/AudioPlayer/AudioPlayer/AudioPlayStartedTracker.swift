import MEGAAnalyticsiOS
import MEGAAppPresentation
import MEGAAppSDKRepo
import MEGADomain

/// Sends `AudioPlayStartedEvent`, the share-link funnel event
enum AudioPlayStartedTracker {

    @MainActor
    static func trackShareLinkPlayStarted(
        fileLink: String?,
        isFolderLink: Bool,
        tracker: some AnalyticsTracking = DIContainer.tracker,
        accountUseCase: some AccountUseCaseProtocol = AccountUseCase(repository: AccountRepository.newRepo)
    ) {
        let linkType: AudioPlayStarted.LinkType
        if fileLink != nil {
            linkType = .file
        } else if isFolderLink {
            linkType = .folder
        } else {
            return
        }

        let authStatus: AudioPlayStarted.AuthStatus = accountUseCase.isLoggedIn() ? .loggedin : .loggedout
        tracker.trackAnalyticsEvent(
            with: AudioPlayStartedEvent(linkType: linkType, authStatus: authStatus)
        )
    }
}
