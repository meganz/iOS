import Foundation
import MEGAAppPresentation
import MEGADomain
import MEGAL10n
import SwiftUI
import UIKit

public protocol TermsAndPoliciesRouting: Routing {
    func dismiss()
}

public struct TermsAndPoliciesRouter: TermsAndPoliciesRouting {
    private weak var navigationController: UINavigationController?
    private weak var presenter: UIViewController?
    private let accountUseCase: any AccountUseCaseProtocol
    private let appDomainUseCase: any AppDomainUseCaseProtocol

    public init(
        accountUseCase: some AccountUseCaseProtocol,
        appDomainUseCase: some AppDomainUseCaseProtocol,
        navigationController: UINavigationController? = nil,
        presenter: UIViewController? = nil
    ) {
        self.accountUseCase = accountUseCase
        self.appDomainUseCase = appDomainUseCase
        self.navigationController = navigationController
        self.presenter = presenter
    }

    public func build() -> UIViewController {
        let termsAndPoliciesView = TermsAndPoliciesView(
            viewModel: TermsAndPoliciesViewModel(
                accountUseCase: accountUseCase,
                appDomainUseCase: appDomainUseCase,
                router: self
            ),
            isPresented: presenter != nil
        )

        return UIHostingController(rootView: termsAndPoliciesView)
    }
    
    public func start() {
        if let navigationController {
            navigationController.pushViewController(build(), animated: true)
        } else if let presenter {
            presenter.present(build(), animated: true)
        }
    }
    
    public func dismiss() {
        if let presenter {
            presenter.dismiss(animated: true)
        }
    }
}
