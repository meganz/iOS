import MEGADomain
import MEGAPresentation
import SwiftUI
import UIKit

@MainActor
protocol HangOrEndCallRouting: AnyObject {
    func leaveCall()
    func endCallForAll()
    func dismiss(animated flag: Bool, completion: (() -> Void)?)
}

public final class HangOrEndCallRouter: HangOrEndCallRouting {
    private weak var presenter: UIViewController?
    private weak var baseViewController: UIViewController?
    private let completion: (HangOrEndCallAction) -> Void
    
    public init(
        presenter: UIViewController,
        completion: @escaping (HangOrEndCallAction) -> Void
    ) {
        self.presenter = presenter
        self.completion = completion
    }
    
    public func build() -> UIViewController {
        let viewModel = HangOrEndCallViewModel(
            router: self,
            tracker: DIContainer.tracker
        )
        let hangOrEndCallView = HangOrEndCallView(viewModel: viewModel)
        let hostingController = UIHostingController(rootView: hangOrEndCallView)
        hostingController.view.backgroundColor = .clear
        hostingController.overrideUserInterfaceStyle = .dark
        return hostingController
    }
    
    public func start() {
        let viewController = build()
        baseViewController = viewController
        presenter?.present(viewController, animated: true)
    }
    
    func leaveCall() {
        baseViewController?.dismiss(animated: true, completion: { [weak self] in
            self?.completion(.leaveCall)
        })
    }
    
    func endCallForAll() {
        baseViewController?.dismiss(animated: true, completion: { [weak self] in
            self?.completion(.endCallForAll)
        })
    }
    
    func dismiss(animated flag: Bool, completion: (() -> Void)? = nil) {
        baseViewController?.dismiss(animated: flag, completion: completion)
    }
}
