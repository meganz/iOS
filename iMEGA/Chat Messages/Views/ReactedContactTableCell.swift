

class MessageOptionItemTableCell: UITableViewCell {
    @IBOutlet weak var usernameLabel: UILabel!
    @IBOutlet weak var avatarImageView: UIImageView!
    @IBOutlet weak var seperatorView: UIView!

    var userHandle: UInt64? {
        didSet {
            guard let handle = userHandle else {
                return
            }
            
            avatarImageView.mnz_setImageAvatarOrColor(forUserHandle: handle)
            let user = MEGAStore.shareInstance()?.fetchUser(withUserHandle: handle)
            usernameLabel.text = user?.displayName
        }
    }
    
}
