import Accounts
import MEGADesignToken
import MEGADomain
import MEGASDKRepo
import SwiftUI

extension LaunchViewController {
    
    @objc func addRequestStatusProgressView() {
        let requestStatusProgressView = RequestStatusProgressView(viewModel: RequestStatusProgressViewModel(requestStatProgressUseCase: RequestStatProgressUseCase(repo: EventRepository.newRepo)))
        let hostingController = UIHostingController(rootView: requestStatusProgressView)
        
        addChild(hostingController)
        view.addSubview(hostingController.view)
        
        hostingController.view.translatesAutoresizingMaskIntoConstraints = false
        hostingController.view.backgroundColor = .clear
        let leadingConstraint = hostingController.view.leadingAnchor.constraint(equalTo: view.safeAreaLayoutGuide.leadingAnchor, constant: 20)
        let trailingConstraint = hostingController.view.trailingAnchor.constraint(equalTo: view.safeAreaLayoutGuide.trailingAnchor, constant: -20)
        let horizontalConstraint = hostingController.view.centerXAnchor.constraint(equalTo: view.centerXAnchor)
        let heightConstraint = hostingController.view.heightAnchor.constraint(equalToConstant: 4)
        let topConstraint = hostingController.view.topAnchor.constraint(equalTo: label.topAnchor, constant: 20)
        NSLayoutConstraint.activate([leadingConstraint, trailingConstraint, horizontalConstraint, heightConstraint, topConstraint])
        hostingController.didMove(toParent: self)
    }
}
