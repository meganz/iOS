import MEGAAnalyticsiOS
import MEGAAppPresentation
import MEGAAppSDKRepo
import MEGADomain

/// Where an action was picked from. The revamped screen offers its two main actions in two places, and
/// the events are split by entry point so the anchored buttons can be told apart from the sheet.
package enum FileLinkActionSource: Sendable {
    /// One of the two buttons anchored above the bottom safe area.
    case anchoredButton
    /// A row of the more options sheet behind the navigation bar more button.
    case moreOptionsMenu
}

package protocol FileLinkTrackingUseCaseProtocol: Sendable {
    /// Needs no feature flag gate, unlike the folder link's: `MEGALinkManager.showFileLinkView` only
    /// reaches this module when the revamp is on, and sends the pre-revamp arm to a different view
    /// controller entirely.
    func trackScreenView()
    /// Reported once the link has resolved, which is what the pre-revamp screen did too.
    func trackFileLinkOpened()
    func trackAction(_ option: FileLinkMoreOption, from source: FileLinkActionSource)
}

package struct FileLinkTrackingUseCase: FileLinkTrackingUseCaseProtocol {
    private let tracker: any AnalyticsTracking
    private let accountUseCase: any AccountUseCaseProtocol

    package init(
        tracker: some AnalyticsTracking = DIContainer.tracker,
        accountUseCase: some AccountUseCaseProtocol = AccountUseCase(repository: AccountRepository.newRepo)
    ) {
        self.tracker = tracker
        self.accountUseCase = accountUseCase
    }

    package func trackScreenView() {
        tracker.trackAnalyticsEvent(with: FileLinkScreenEvent())
    }

    package func trackFileLinkOpened() {
        let authStatus: ShareLinkOpened.AuthStatus = accountUseCase.isLoggedIn() ? .loggedin : .loggedout
        tracker.trackAnalyticsEvent(
            with: ShareLinkOpenedEvent(linkType: .file, authStatus: authStatus)
        )
    }

    /// Share link and Send to chat are not here: the first is shared straight from the sheet's own
    /// `ShareLink` row and was never tracked, and the second is reported by the app layer's action
    /// handler through the events it already had.
    package func trackAction(_ option: FileLinkMoreOption, from source: FileLinkActionSource) {
        let eventIdentifier: (any EventIdentifier)? = switch (option, source) {
        case (.saveToMEGA, .anchoredButton):
            FileLinkSaveToMegaAnchoredButtonPressedEvent()
        case (.saveToMEGA, .moreOptionsMenu):
            FileLinkSaveToMegaMoreOptionsButtonPressedEvent()
        case (.download, .anchoredButton):
            FileLinkDownloadAnchoredButtonPressedEvent()
        case (.download, .moreOptionsMenu):
            FileLinkDownloadMoreOptionsButtonPressedEvent()
        case (.saveToPhotos, .moreOptionsMenu):
            FileLinkSaveToPhotosMoreOptionsButtonPressedEvent()
        case (.copyToOffline, .moreOptionsMenu):
            FileLinkCopyToOfflineMoreOptionsButtonPressedEvent()
        // Save to Photos and Copy to Offline have no anchored button of their own, so those combinations
        // cannot happen.
        default:
            nil
        }
        guard let eventIdentifier else { return }
        tracker.trackAnalyticsEvent(with: eventIdentifier)
    }
}
