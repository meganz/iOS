
import UIKit

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
        
        viewModel?.dispatch(.onViewReady(imageSize: CGSize(width: 40, height: 40)))
    }
    
    func executeCommand(_ command: MeetingParticpiantInfoViewModel.Command) {
        switch command {
        case .configView(let email, let actions):
            configureHeaderView(email: email)
            self.actions = actions
        case .updateAvatarImage(let image):
            guard let meetingContactInfoHeaderView = headerView?.subviews.filter({ $0 is MeetingContactInfoHeaderView }).first as? MeetingContactInfoHeaderView else { return }
            meetingContactInfoHeaderView.avatarImageView.image = image
        case .updateName(let name):
            guard let meetingContactInfoHeaderView = headerView?.subviews.filter({ $0 is MeetingContactInfoHeaderView }).first as? MeetingContactInfoHeaderView else { return }
            meetingContactInfoHeaderView.nameLabel.text = name
        }
    }
    
    private func configureHeaderView(email: String?) {
        guard let headerView = headerView else { return }
        
        let meetingContactInfoHeaderView = MeetingContactInfoHeaderView.instanceFromNib
        meetingContactInfoHeaderView.emailLabel.text = email
        headerView.addSubview(meetingContactInfoHeaderView)
        
        meetingContactInfoHeaderView.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            meetingContactInfoHeaderView.heightAnchor.constraint(equalTo: headerView.heightAnchor),
            meetingContactInfoHeaderView.widthAnchor.constraint(equalTo: headerView.widthAnchor)
        ])
        
        headerView.frame = CGRect(origin: .zero, size: CGSize(width: view.bounds.width, height: meetingContactInfoHeaderView.bounds.height))
    }
    
    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = super.tableView(tableView, cellForRowAt: indexPath)
        cell.backgroundColor = #colorLiteral(red: 0.1098039216, green: 0.1098039216, blue: 0.1176470588, alpha: 1)
        cell.textLabel?.textColor = #colorLiteral(red: 1.0, green: 1.0, blue: 1.0, alpha: 1.0)
        return cell
    }
}
