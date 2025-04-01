import Combine
import MEGAAppPresentation
import MEGAL10n
import SwiftUI

final class MeetingInfoViewController: UIViewController {
    lazy var editBarButtonItem: UIBarButtonItem = UIBarButtonItem(title: Strings.Localizable.edit, style: .plain, target: self, action: #selector(editButtonItemTapped)
    )
    
    private(set) var viewModel: MeetingInfoViewModel

    lazy var hostingView = UIHostingController(rootView: MeetingInfoView(viewModel: viewModel))

    private var subscriptions = Set<AnyCancellable>()

    init(viewModel: MeetingInfoViewModel) {
        self.viewModel = viewModel
        super.init(nibName: nil, bundle: nil)
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        configureSubview()
        initSubscriptions()
        navigationItem.title = Strings.Localizable.info
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        addEditButton(isModerator: viewModel.isModerator)
        navigationItem.backButtonTitle = ""
    }
    
    @objc func editButtonItemTapped() {
        viewModel.editTapped()
    }
    
    private func addEditButton(isModerator: Bool) {
        navigationItem.rightBarButtonItem = isModerator ? editBarButtonItem : nil
    }
    
    private func initSubscriptions() {
        subscriptions = [
            viewModel.$isModerator.sink(receiveValue: { [weak self] isModerator in
                self?.addEditButton(isModerator: isModerator)
            })
        ]
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
