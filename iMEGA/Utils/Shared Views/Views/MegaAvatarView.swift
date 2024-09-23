import ChatRepo
import GKContactImage
import MEGADomain
import UIKit

@objc enum MegaAvatarViewMode: Int {
    case single
    case multiple
}

class MegaAvatarView: UIView {
    
    @IBOutlet weak var avatarImageView: UIImageView!
    @IBOutlet weak var firstPeerAvatarImageView: UIImageView!
    @IBOutlet weak var secondPeerAvatarImageView: UIImageView!
    
    private var customView: UIView?
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        customInit()
    }
    
    required init?(coder: NSCoder) {
        super.init(coder: coder)
        customInit()
    }
    
    func customInit() {
        customView = Bundle.init(for: type(of: self)).loadNibNamed("MegaAvatarView", owner: self, options: nil)?.first as? UIView
        if let view = customView {
            addSubview(view)
            view.frame = bounds
        }
        
        firstPeerAvatarImageView.layer.masksToBounds = true
        firstPeerAvatarImageView.layer.borderWidth = 1
        firstPeerAvatarImageView.layer.borderColor = UIColor.systemBackground.cgColor
        firstPeerAvatarImageView.layer.cornerRadius = firstPeerAvatarImageView.bounds.width / CGFloat(2)
        
        avatarImageView.accessibilityIgnoresInvertColors            = true
        firstPeerAvatarImageView.accessibilityIgnoresInvertColors   = true
        secondPeerAvatarImageView.accessibilityIgnoresInvertColors  = true
    }
    
    @objc func configure(mode: MegaAvatarViewMode) {
        switch mode {
        case .single:
            avatarImageView.isHidden            = false
            firstPeerAvatarImageView.isHidden   = true
            secondPeerAvatarImageView.isHidden  = true
        case .multiple:
            avatarImageView.isHidden            = true
            firstPeerAvatarImageView.isHidden   = false
            secondPeerAvatarImageView.isHidden  = false
        }
    }
    
    @objc func setup(for chatRoom: MEGAChatRoom) {
        if chatRoom.peerCount == 0 {
            let font = UIFont.systemFont(ofSize: avatarImageView.frame.size.width / CGFloat(2.0))
            avatarImageView.image = UIImage.init(forName: chatRoom.title?.uppercased(),
                                                 size: avatarImageView.frame.size,
                                                 backgroundColor: UIColor.mnz_secondaryGray(),
                                                 backgroundGradientColor: UIColor.grayDBDBDB,
                                                 textColor: UIColor.whiteFFFFFF,
                                                 font: font)
            configure(mode: .single)
        } else {
            let firstPeerHandle = chatRoom.peerHandle(at: 0)
            userFullName(forPeerId: firstPeerHandle,
                         chatId: chatRoom.chatId,
                         sdk: MEGAChatSdk.shared) { [weak self] result in
                guard let self else { return }
                switch result {
                case .success(let name):
                    let imageView = chatRoom.peerCount == 1 ? self.avatarImageView : self.firstPeerAvatarImageView
                    imageView?.mnz_setImage(forUserHandle: firstPeerHandle, name: name)
                case .failure(let error):
                    MEGALogDebug("not able to fetch the image for peer \(error)")
                }
            }
            
            if chatRoom.peerCount > 1 {
                let secondPeerHandle = chatRoom.peerHandle(at: 1)
                userFullName(forPeerId: secondPeerHandle,
                             chatId: chatRoom.chatId,
                             sdk: MEGAChatSdk.shared) { [weak self] result in
                    switch result {
                    case .success(let name):
                        self?.secondPeerAvatarImageView.mnz_setImage(forUserHandle: secondPeerHandle, name: name)
                    case .failure(let error):
                        MEGALogDebug("not able to fetch the image for peer \(error)")
                    }
                }
            }
            
            configure(mode: (chatRoom.peerCount == 1) ? .single :.multiple)
        }
    }
    
    func userFullName(forPeerId peerId: HandleEntity,
                      chatId: HandleEntity,
                      sdk: MEGAChatSdk,
                      completion: @escaping (Result<String, ChatRoomErrorEntity>) -> Void) {
        if let name = sdk.userFullnameFromCache(byUserHandle: peerId) {
            completion(.success(name))
            return
        }
        
        MEGALogDebug("Load user attributes for \(MEGASdk.base64Handle(forUserHandle: peerId) ?? "No name")")
        sdk.loadUserAttributes(forChatId: chatId, usersHandles: [NSNumber(value: peerId)], delegate: ChatRequestDelegate { result in
            switch result {
            case .success:
                guard let name = sdk.userFullnameFromCache(byUserHandle: peerId) else {
                    MEGALogDebug("Error fetching name for \(MEGASdk.base64Handle(forUserHandle: peerId) ?? "No name")")
                    completion(.failure(.generic))
                    return
                }
                completion(.success(name))
                
            case .failure(let error):
                MEGALogDebug("error fetching attributes for \(MEGASdk.base64Handle(forUserHandle: peerId) ?? "No name") attributes \(error.type) : \(error.name ?? "")")
                completion(.failure(.generic))
            }
        })
    }
    
    override func traitCollectionDidChange(_ previousTraitCollection: UITraitCollection?) {
        super.traitCollectionDidChange(previousTraitCollection)
        
        if traitCollection.hasDifferentColorAppearance(comparedTo: previousTraitCollection) {
            updateAppearance()
        }
    }
    
    func updateAppearance() {
        firstPeerAvatarImageView.layer.borderColor = UIColor.systemBackground.cgColor
    }
}
