
import UIKit

enum OnboardingInfoViewType {
    case encryptionInfo
    case chatInfo
    case contactsInfo
    case cameraUploadsInfo
    case photosPermission
    case microphoneAndCameraPermissions
    case notificationsPermission
}

class OnboardingInfoView: UIView {
    
    let type:OnboardingInfoViewType
    private let imageView: UIImageView = {
        let view = UIImageView.newAutoLayout()
        view.contentMode = .scaleAspectFit
        view.setContentCompressionResistancePriority(.defaultLow, for: .vertical)
        return view
    }()
    private let titleLabel: UILabel = {
        let label = UILabel.newAutoLayout()
        label.font = UIFont.mnz_SFUIMedium(withSize: 19)
        label.setContentHuggingPriority(.defaultHigh, for: .vertical)
        return label
    }()
    private let descriptionLabel: UILabel = {
        let label = UILabel.newAutoLayout()
        label.lineBreakMode = .byWordWrapping
        label.numberOfLines = 0
        label.font = UIFont.mnz_SFUIRegular(withSize: 14)
        label.textAlignment = .center
        label.setContentHuggingPriority(.defaultHigh, for: .vertical)
        return label
    }()
    
    private var didSetupConstraints = false
    
    
    
    // MARK: Lifecycle
    
    public init(type: OnboardingInfoViewType) {
        self.type = type
        super.init(frame: CGRect.zero)
        
        switch type {
        case .encryptionInfo:
            imageView.image = UIImage(named: "privacy_warning_ico")
            titleLabel.text = "You hold the keys".localized(withComment: "Title shown in a page of the on boarding screens explaining that the user keeps the encryption keys")
            descriptionLabel.text = "Security is why we exist, your files are safe with us behind a well oiled encryption machine where only you can access your files.".localized(withComment: "Description shown in a page of the onboarding screens explaining the encryption paradigm")
        case .chatInfo:
            imageView.image = UIImage(named: "privacy_warning_ico")
            titleLabel.text = "Encrypted chat".localized(withComment: "Title shown in a page of the on boarding screens explaining that the chat is encrypted")
            descriptionLabel.text = "Fully encrypted chat with voice and video calls, group messaging and file sharing integration with your Cloud Drive.".localized(withComment: "Description shown in a page of the onboarding screens explaining the chat feature")
        case .contactsInfo:
            imageView.image = UIImage(named: "privacy_warning_ico")
            titleLabel.text = "Create your Network".localized(withComment: "Title shown in a page of the on boarding screens explaining that the user can add contacts to chat and colaborate")
            descriptionLabel.text = "Add contacts, create a network, colaborate, make voice and video calls without ever leaving MEGA".localized(withComment: "Description shown in a page of the onboarding screens explaining contacts")
        case .cameraUploadsInfo:
            imageView.image = UIImage(named: "privacy_warning_ico")
            titleLabel.text = "Your Photos in the Cloud".localized(withComment: "Title shown in a page of the on boarding screens explaining that the user can backup the photos automatically")
            descriptionLabel.text = "Camera Uploads is an essential feature for any mobile device and we have got you covered. Create your account now.".localized(withComment: "Description shown in a page of the onboarding screens explaining the camera uploads feature")
        case .photosPermission:
            imageView.image = UIImage(named: "photosPermission")
            titleLabel.text = "Allow Access to Photos".localized(withComment: "Title label that explains that the user is going to be asked for the photos permission")
            descriptionLabel.text = "To share photos and videos, allow MEGA to access your photos".localized(withComment: "Detailed explanation of why the user should give permission to access to the photos")
        case .microphoneAndCameraPermissions:
            imageView.image = UIImage(named: "groupChat")
            titleLabel.text = "Enable Microphone and Camera".localized(withComment: "Title label that explains that the user is going to be asked for the microphone and camera permission")
            descriptionLabel.text = "To make encrypted voice and video calls, allow MEGA access to your Camera and Microphone".localized(withComment: "Detailed explanation of why the user should give permission to access to the camera and the microphone")
        case .notificationsPermission:
            imageView.image = UIImage(named: "privacy_warning_ico")
            titleLabel.text = "Enable Notifications".localized(withComment: "Title label that explains that the user is going to be asked for the notifications permission")
            descriptionLabel.text = "We would like to send you notifications so you receive new messages on your device instantly.".localized(withComment: "Detailed explanation of why the user should give permission to deliver notifications")
        }
        
        self.addSubview(imageView)
        self.addSubview(titleLabel)
        self.addSubview(descriptionLabel)
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func updateConstraints() {
        if !didSetupConstraints {
            setupConstraints()
            didSetupConstraints = true
        }
        super.updateConstraints()
    }
    
    
    
    // MARK: Autolayout
    
    private func setupConstraints() {
        imageView.autoPinEdge(toSuperviewEdge: .top)
        imageView.autoAlignAxis(toSuperviewAxis: .vertical)
        
        titleLabel.autoPinEdge(.top, to: .bottom, of: imageView, withOffset: 28)
        titleLabel.autoAlignAxis(toSuperviewAxis: .vertical)
        
        descriptionLabel.autoPinEdge(.top, to: .bottom, of: titleLabel, withOffset: 28)
        descriptionLabel.autoAlignAxis(toSuperviewAxis: .vertical)
        descriptionLabel.autoPinEdge(.left, to: .left, of: self, withOffset: 35)
        descriptionLabel.autoPinEdge(toSuperviewEdge: .bottom)
    }

}
