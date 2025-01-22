import Accounts
import SwiftUI

final class RequestStatusProgressWindowManager {
    private var hostingController: UIHostingController<RequestStatusProgressView>?

    func showProgressView(with viewModel: RequestStatusProgressViewModel) {
        guard let window = UIApplication.shared.keyWindow else { return }
        if hostingController == nil {
            let progressView = RequestStatusProgressView(viewModel: viewModel)
            let hostingController = UIHostingController(rootView: progressView)
            hostingController.view.backgroundColor = .clear
            guard let hostingView = hostingController.view else { return }
            hostingView.translatesAutoresizingMaskIntoConstraints = false
            window.addSubview(hostingView)
            NSLayoutConstraint.activate([
                hostingView.topAnchor.constraint(equalTo: window.safeAreaLayoutGuide.bottomAnchor),
                hostingView.leadingAnchor.constraint(equalTo: window.safeAreaLayoutGuide.leadingAnchor),
                hostingView.trailingAnchor.constraint(equalTo: window.safeAreaLayoutGuide.trailingAnchor)
            ])
            
            self.hostingController = hostingController
        }
    }

    func hideProgressView() {
        hostingController?.removeFromParent()
        hostingController = nil
    }
}
