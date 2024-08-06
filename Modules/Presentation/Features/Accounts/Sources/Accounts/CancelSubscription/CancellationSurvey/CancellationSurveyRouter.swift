import MEGADomain
import MEGAPresentation
import MEGASwift
import StoreKit
import SwiftUI

public protocol CancellationSurveyRouting: Routing {
    func showAppleManageSubscriptions()
}

public final class CancellationSurveyRouter: CancellationSurveyRouting {
    private weak var baseViewController: UIViewController?
    private weak var presenter: UIViewController?
    
    private var appleIDSubscriptionsURL: URL? {
        URL(string: "https://apps.apple.com/account/subscriptions")
    }

    public init(presenter: UIViewController?) {
        self.presenter = presenter
    }
    
    public func build() -> UIViewController {
        let viewModel = CancellationSurveyViewModel(router: self)
        let hostingController = UIHostingController(
            rootView: CancellationSurveyView(viewModel: viewModel)
        )
        baseViewController = hostingController
        return hostingController
    }
    
    public func start() {
        presenter?.present(build(), animated: true)
    }
    
    public func showAppleManageSubscriptions() {
        guard let scene = UIApplication.shared.connectedScenes
            .compactMap({ $0 as? UIWindowScene })
            .first(where: { $0.activationState == .foregroundActive }),
              !ProcessInfo.processInfo.isiOSAppOnMac else {
            openAppleIDSubscriptionsPage()
            return
        }
        
        Task {
            do {
                try await AppStore.showManageSubscriptions(in: scene)
            } catch {
                openAppleIDSubscriptionsPage()
            }
        }
    }
    
    private func openAppleIDSubscriptionsPage() {
        guard let url = appleIDSubscriptionsURL else { return }
        UIApplication.shared.open(url, options: [:], completionHandler: nil)
    }
}
