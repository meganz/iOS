import UIKit
import PanModal

class EndMeetingOptionsViewViewController: UIViewController {
    private let viewModel: EndMeetingOptionsViewModel
    
    @IBOutlet weak var leaveButton: UIButton!
    @IBOutlet weak var cancelButton: UIButton!
    
    init(viewModel: EndMeetingOptionsViewModel) {
        self.viewModel = viewModel
        super.init(nibName: nil, bundle: nil)
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        leaveButton.setTitle(NSLocalizedString("leave", comment: ""), for: .normal)
        cancelButton.setTitle(NSLocalizedString("cancel", comment: ""), for: .normal)
    }
    
    @IBAction func leaveButtonTapped(_ sender: UIButton) {
        viewModel.dispatch(.onLeave)
    }
    
    @IBAction func cancelButtonTapped(_ sender: UIButton) {
        viewModel.dispatch(.onCancel)
    }
}

extension EndMeetingOptionsViewViewController: PanModalPresentable {
    var panScrollable: UIScrollView? {
        nil
    }
    
    var longFormHeight: PanModalHeight {
        shortFormHeight
    }
    
    var shortFormHeight: PanModalHeight {
        .contentHeight(170.0)
    }
    
    var panModalBackgroundColor: UIColor {
        #colorLiteral(red: 0, green: 0, blue: 0, alpha: 0.3955365646)
    }

    var allowsTapToDismiss: Bool {
        false
    }
    
    var allowsDragToDismiss: Bool {
        false
    }
    
    var backgroundInteraction: PanModalBackgroundInteraction {
        .none
    }
    
    var showDragIndicator: Bool {
        false
    }
}

