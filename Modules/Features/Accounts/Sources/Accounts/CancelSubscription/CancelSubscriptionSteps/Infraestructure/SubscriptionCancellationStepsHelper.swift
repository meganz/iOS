import MEGAL10n

public protocol CancelSubscriptionStepsHelperProtocol {
    func loadCancellationData() -> CancelSubscriptionData
}

public enum SubscriptionType {
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
        case .webClient: Strings.Localizable.Accounts.CancelSubscriptionSteps.WebClient.title
        }
    }
    
    private var message: String {
        switch type {
        case .google: Strings.Localizable.Accounts.CancelSubscriptionSteps.GooglePlay.message
        case .webClient: Strings.Localizable.Accounts.CancelSubscriptionSteps.WebClient.message
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
                    Step(text: Strings.Localizable.Accounts.CancelSubscriptionSteps.GooglePlay.WebBrowser.Step.one),
                    Step(text: Strings.Localizable.Accounts.CancelSubscriptionSteps.GooglePlay.WebBrowser.Step.two),
                    Step(text: Strings.Localizable.Accounts.CancelSubscriptionSteps.GooglePlay.WebBrowser.Step.three),
                    Step(text: Strings.Localizable.Accounts.CancelSubscriptionSteps.GooglePlay.WebBrowser.Step.four),
                    Step(text: Strings.Localizable.Accounts.CancelSubscriptionSteps.GooglePlay.WebBrowser.Step.five),
                    Step(text: Strings.Localizable.Accounts.CancelSubscriptionSteps.GooglePlay.WebBrowser.Step.six)
                ]
            ),
            StepSection(
                title: Strings.Localizable.Accounts.CancelSubscriptionSteps.GooglePlay.AndroidDevice.title,
                steps: [
                    Step(text: Strings.Localizable.Accounts.CancelSubscriptionSteps.GooglePlay.AndroidDevice.Step.one),
                    Step(text: Strings.Localizable.Accounts.CancelSubscriptionSteps.GooglePlay.AndroidDevice.Step.two),
                    Step(text: Strings.Localizable.Accounts.CancelSubscriptionSteps.GooglePlay.AndroidDevice.Step.three),
                    Step(text: Strings.Localizable.Accounts.CancelSubscriptionSteps.GooglePlay.AndroidDevice.Step.four),
                    Step(text: Strings.Localizable.Accounts.CancelSubscriptionSteps.GooglePlay.AndroidDevice.Step.five),
                    Step(text: Strings.Localizable.Accounts.CancelSubscriptionSteps.GooglePlay.AndroidDevice.Step.six)
                ]
            )
        ]
    }
    
    private func loadWebClientSteps() -> [StepSection] {
        [
            StepSection(
                title: Strings.Localizable.Accounts.CancelSubscriptionSteps.WebClient.Computer.title,
                steps: [
                    Step(
                        text: Strings.Localizable.Accounts.CancelSubscriptionSteps.WebClient.Computer.Step.one(
                            DependencyInjection.appDomain()
                        )
                    ),
                    Step(text: Strings.Localizable.Accounts.CancelSubscriptionSteps.WebClient.Computer.Step.two),
                    Step(text: Strings.Localizable.Accounts.CancelSubscriptionSteps.WebClient.Computer.Step.three),
                    Step(text: Strings.Localizable.Accounts.CancelSubscriptionSteps.WebClient.Computer.Step.four),
                    Step(text: Strings.Localizable.Accounts.CancelSubscriptionSteps.WebClient.Computer.Step.five),
                    Step(text: Strings.Localizable.Accounts.CancelSubscriptionSteps.WebClient.Computer.Step.six)
                ]
            ),
            StepSection(
                title: Strings.Localizable.Accounts.CancelSubscriptionSteps.WebClient.Mobile.title,
                steps: [
                    Step(
                        text: Strings.Localizable.Accounts.CancelSubscriptionSteps.WebClient.Mobile.Step.one(
                            DependencyInjection.appDomain()
                        )
                    ),
                    Step(text: Strings.Localizable.Accounts.CancelSubscriptionSteps.WebClient.Mobile.Step.two),
                    Step(text: Strings.Localizable.Accounts.CancelSubscriptionSteps.WebClient.Mobile.Step.three),
                    Step(text: Strings.Localizable.Accounts.CancelSubscriptionSteps.WebClient.Mobile.Step.four)
                ]
            )
        ]
    }
}
