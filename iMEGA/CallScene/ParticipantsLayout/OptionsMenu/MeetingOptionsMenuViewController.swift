
class MeetingOptionsMenuViewController: ActionSheetViewController, ViewType {
    
    private var viewModel: MeetingOptionsMenuViewModel?

    convenience init(viewModel: MeetingOptionsMenuViewModel, sender: UIBarButtonItem) {
        self.init(nibName: nil, bundle: nil)
        self.viewModel = viewModel
        configurePresentationStyle(from: sender as Any)
    }
    
    override init(nibName nibNameOrNil: String?, bundle nibBundleOrNil: Bundle?) {
        super.init(nibName: nibNameOrNil, bundle: nibBundleOrNil)
    }
    
    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        if #available(iOS 13.0, *) {
            overrideUserInterfaceStyle = .dark
        }
        viewModel?.invokeCommand = { [weak self] in
            self?.executeCommand($0)
        }
        
        dismissCompletion = { [weak self] in
            self?.viewModel?.dispatch(.dismiss)
        }
        
        viewModel?.dispatch(.onViewReady)
    }
    
    func executeCommand(_ command: MeetingOptionsMenuViewModel.Command) {
        switch command {
        case .configView(actions: let actions):
            self.actions = actions
        }
    }
}
