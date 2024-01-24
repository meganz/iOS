import MEGAAnalyticsiOS
import MEGAPresentation

final class CustomModalAlertViewModel: NSObject {
    struct CustomModalAlertViewAnalyticEvents {
        let dialogDisplayedEventIdentifier: (any DialogDisplayedEventIdentifier)?
        let fistButtonPressedEventIdentifier: (any ButtonPressedEventIdentifier)?
    }
    
    private let invalidLinkTapAction: (() -> Void)?
    private let configureSnackBarPresenter: (() -> Void)?
    private let removeSnackBarPresenter: (() -> Void)?
    private(set) var snackBarContainerView: UIView?
    
    private let tracker: any AnalyticsTracking
    private let analyticsEvents: CustomModalAlertViewAnalyticEvents?
    
    init(invalidLinkTapAction: (() -> Void)? = nil,
         configureSnackBarPresenter: (() -> Void)? = nil,
         removeSnackBarPresenter: (() -> Void)? = nil,
         tracker: some AnalyticsTracking,
         analyticsEvents: CustomModalAlertViewAnalyticEvents?) {
        self.invalidLinkTapAction = invalidLinkTapAction
        self.configureSnackBarPresenter = configureSnackBarPresenter
        self.removeSnackBarPresenter = removeSnackBarPresenter
        self.tracker = tracker
        self.analyticsEvents = analyticsEvents
    }
    
    @objc func onViewDidLoad() {
        guard let dialogDisplayedEventIdentifier = analyticsEvents?.dialogDisplayedEventIdentifier else { return }
        tracker.trackAnalyticsEvent(with: dialogDisplayedEventIdentifier)
    }
    
    @objc func firstButtonTapped() {
        guard let fistButtonPressedEventIdentifier = analyticsEvents?.fistButtonPressedEventIdentifier else { return }
        tracker.trackAnalyticsEvent(with: fistButtonPressedEventIdentifier)
    }
    
    @objc func configureSnackBar() {
        configureSnackBarPresenter?()
    }
    
    @objc func removeSnackBarConfig() {
        removeSnackBarPresenter?()
    }
    
    @objc func invalidLinkTapped() {
        invalidLinkTapAction?()
    }
    
    func setSnackBarContainerView(_ view: UIView?) {
        snackBarContainerView = view
    }
}
