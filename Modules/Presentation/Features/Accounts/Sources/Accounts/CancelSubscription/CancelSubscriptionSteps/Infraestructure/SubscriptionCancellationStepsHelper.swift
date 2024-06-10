import MEGAL10n

public protocol CancelSubscriptionStepsHelperProtocol {
    func loadCancellationData() -> CancelSubscriptionData
}

enum SubscriptionType {
    case google, webClient
}

struct CancelSubscriptionStepsHelper: CancelSubscriptionStepsHelperProtocol {
    private let type: SubscriptionType
    
    init(type: SubscriptionType) {
        self.type = type
    }
    
    private var title: String {
        switch type {
        case .google: Strings.Localizable.Accounts.CancelSubscriptionSteps.GooglePlay.title
        case .webClient: ""
        }
    }
    
    private var message: String {
        switch type {
        case .google: Strings.Localizable.Accounts.CancelSubscriptionSteps.GooglePlay.message
        case .webClient: ""
        }
    }
    
    private var sections: [StepSection] {
        switch type {
        case .google: loadGoogleSteps()
        case .webClient: loadWebClientSteps()
        }
    }
    
    func loadCancellationData() -> CancelSubscriptionData {
        CancelSubscriptionData(
            title: title,
            message: message,
            sections: sections
        )
    }
    
    private func loadGoogleSteps() -> [StepSection] {
        [
            StepSection(
                title: Strings.Localizable.Accounts.CancelSubscriptionSteps.GooglePlay.WebBrowser.title,
                steps: [
                    Step(content: Strings.Localizable.Accounts.CancelSubscriptionSteps.GooglePlay.WebBrowser.Step.one),
                    Step(content: Strings.Localizable.Accounts.CancelSubscriptionSteps.GooglePlay.WebBrowser.Step.two),
                    Step(content: Strings.Localizable.Accounts.CancelSubscriptionSteps.GooglePlay.WebBrowser.Step.three),
                    Step(content: Strings.Localizable.Accounts.CancelSubscriptionSteps.GooglePlay.WebBrowser.Step.four),
                    Step(content: Strings.Localizable.Accounts.CancelSubscriptionSteps.GooglePlay.WebBrowser.Step.five),
                    Step(content: Strings.Localizable.Accounts.CancelSubscriptionSteps.GooglePlay.WebBrowser.Step.six)
                ]
            ),
            StepSection(
                title: Strings.Localizable.Accounts.CancelSubscriptionSteps.GooglePlay.AndroidDevice.title,
                steps: [
                    Step(content: Strings.Localizable.Accounts.CancelSubscriptionSteps.GooglePlay.AndroidDevice.Step.one),
                    Step(content: Strings.Localizable.Accounts.CancelSubscriptionSteps.GooglePlay.AndroidDevice.Step.two),
                    Step(content: Strings.Localizable.Accounts.CancelSubscriptionSteps.GooglePlay.AndroidDevice.Step.three),
                    Step(content: Strings.Localizable.Accounts.CancelSubscriptionSteps.GooglePlay.AndroidDevice.Step.four),
                    Step(content: Strings.Localizable.Accounts.CancelSubscriptionSteps.GooglePlay.AndroidDevice.Step.five),
                    Step(content: Strings.Localizable.Accounts.CancelSubscriptionSteps.GooglePlay.AndroidDevice.Step.six)
                ]
            )
        ]
    }
    
    private func loadWebClientSteps() -> [StepSection] {
        []
    }
}
