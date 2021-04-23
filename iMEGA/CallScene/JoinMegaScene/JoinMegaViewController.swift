import UIKit

class JoinMegaViewController: UIViewController {
    
    // MARK: - Internal properties
    private let viewModel: JoinMegaViewModel
    
    init(viewModel: JoinMegaViewModel) {
        self.viewModel = viewModel
        super.init(nibName: nil, bundle: nil)
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) is not supported")
    }
    
    override func viewDidLoad() {
        title = NSLocalizedString("Join MEGA", comment: "")
    }
    
    override func loadView() {
        view = JoinMegaView(viewModel: viewModel)
    }
    
}
