import SwiftUI

final class ScheduledMeetingOccurrencesViewController: UIViewController {
    private(set) var viewModel: ScheduledMeetingOccurrencesViewModel

    lazy var hostingView = UIHostingController(rootView: ScheduledMeetingOccurrencesView(viewModel: viewModel))

    init(viewModel: ScheduledMeetingOccurrencesViewModel) {
        self.viewModel = viewModel
        super.init(nibName: nil, bundle: nil)
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        configureSubview()
        navigationItem.titleView = UILabel().customNavigationBarLabel(title: viewModel.title, subtitle: viewModel.subtitle)
    }
    
    private func configureSubview() {
        addChild(hostingView)
        view.addSubview(hostingView.view)
        hostingView.view.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            hostingView.view.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            hostingView.view.centerYAnchor.constraint(equalTo: view.centerYAnchor),
            hostingView.view.widthAnchor.constraint(equalTo: view.widthAnchor),
            hostingView.view.heightAnchor.constraint(equalTo: view.heightAnchor)
        ])
    }
}
