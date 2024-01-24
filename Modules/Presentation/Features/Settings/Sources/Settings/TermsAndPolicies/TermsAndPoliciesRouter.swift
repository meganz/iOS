import Foundation
import MEGADomain
import MEGAL10n
import MEGAPresentation
import SwiftUI
import UIKit

public struct TermsAndPoliciesRouter: Routing {
    private weak var navigationController: UINavigationController?
    private let accountUseCase: any AccountUseCaseProtocol
    
    public init(
        accountUseCase: some AccountUseCaseProtocol,
        navigationController: UINavigationController? = nil
    ) {
        self.accountUseCase = accountUseCase
        self.navigationController = navigationController
    }

    public func build() -> UIViewController {
        let termsAndPoliciesView = TermsAndPoliciesView(viewModel: TermsAndPoliciesViewModel(accountUseCase: accountUseCase))
        return UIHostingController(rootView: termsAndPoliciesView)
    }
    
    public func start() {
        navigationController?.pushViewController(build(), animated: true)
    }
}
