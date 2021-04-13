import UIKit

class MeetingCreatingViewController: UIViewController {
    
    // MARK: - Internal properties
    let viewModel: MeetingCreatingViewModel

     init(viewModel: MeetingCreatingViewModel) {
        self.viewModel = viewModel
        super.init(nibName: nil, bundle: nil)
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) is not supported")
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        self.navigationController?.view.backgroundColor = .black
        
        navigationItem.leftBarButtonItem = UIBarButtonItem(
            image: UIImage(named: "backArrow"),
            style: .plain,
            target: self,
            action: #selector(dissmissVC(_:))
        )
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        navigationController?.navigationBar.isTranslucent = true
        navigationController?.navigationBar.barTintColor = .black
    }
    
    override func loadView() {
        view = MeetingCreatingView(viewModel: viewModel, vc: self)
    }
    
    // MARK: - Private methods.

    @objc private func dissmissVC(_ barButtonItem: UIBarButtonItem) {
        viewModel.dispatch(.didTapCloseButton)
    }
}
