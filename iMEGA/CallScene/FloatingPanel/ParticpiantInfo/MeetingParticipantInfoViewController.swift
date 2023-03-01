import UIKit
import MEGAPresentation

class MeetingParticipantInfoViewController: ActionSheetViewController, ViewType {
    
    private var viewModel: MeetingParticpiantInfoViewModel?
    
    convenience init(viewModel: MeetingParticpiantInfoViewModel, sender: UIButton) {
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
        viewModel?.invokeCommand = { [weak self] in
            self?.executeCommand($0)
        }
        viewModel?.dispatch(.onViewReady)
    }
    
    @MainActor
    func executeCommand(_ command: MeetingParticpiantInfoViewModel.Command) {
        switch command {
        case .configView(let email, let actions):
            configureHeaderView(email: email)
            self.actions = actions
        case .updateAvatarImage(let image):
            guard let meetingContactInfoHeaderView = headerView?.subviews.first(where: { $0 is MeetingContactInfoHeaderView }) as? MeetingContactInfoHeaderView else { return }
            meetingContactInfoHeaderView.avatarImageView.image = image
        case .updateName(let name):
            guard let meetingContactInfoHeaderView = headerView?.subviews.first(where: { $0 is MeetingContactInfoHeaderView }) as? MeetingContactInfoHeaderView else { return }
            meetingContactInfoHeaderView.nameLabel.text = name
        }
    }
    
    private func configureHeaderView(email: String?) {
        guard let headerView = headerView else { return }
        
        let meetingContactInfoHeaderView = MeetingContactInfoHeaderView.instanceFromNib
        meetingContactInfoHeaderView.emailLabel.text = email
        headerView.wrap(meetingContactInfoHeaderView)
        
        headerView.frame = CGRect(origin: .zero, size: CGSize(width: view.bounds.width, height: meetingContactInfoHeaderView.bounds.height))
    }
}
