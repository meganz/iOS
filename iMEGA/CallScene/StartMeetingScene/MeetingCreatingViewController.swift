import MEGAAssets
import MEGADesignToken
import MEGADomain
import MEGAL10n
import MEGAUIKit
import UIKit

class MeetingCreatingViewController: UIViewController, UITextFieldDelegate {
    
    private struct AvatarProperties {
        static let initials = "G"
        static let font = UIFont.preferredFont(forTextStyle: .title1).withWeight(.semibold)
        static let textColor = MEGAAssets.UIColor.whiteFFFFFF
        static let size = CGSize(width: 80, height: 80)
        static let backgroundColor = MEGAAssets.UIColor.callAvatarBackground
        static let backgroundGradientColor = MEGAAssets.UIColor.callAvatarBackgroundGradient
    }
    
    private struct Constants {
        static let bottomBarText = UIFont.preferredFont(style: .title3, weight: .semibold)
        static let bottomBarButtonText = UIFont.preferredFont(forTextStyle: .headline)
        static let backgroundColor = TokenColors.Background.page
        static let iconTintColorNormal = TokenColors.Icon.primary
        static let iconTintColorSelected = TokenColors.Icon.inverse
        static let iconBackgroundColorNormal = TokenColors.Button.secondary
        static let iconBackgroundColorSelected = TokenColors.Button.primary
        static let meetingNameTextColor = TokenColors.Text.placeholder
        static let placeholderTextColor = TokenColors.Text.placeholder
    }
    
    @IBOutlet weak var localUserView: LocalUserView!
    @IBOutlet weak var enableDisableVideoButton: UIButton!
    @IBOutlet weak var muteUnmuteMicrophoneButton: UIButton!
    @IBOutlet weak var speakerQuickActionView: MeetingSpeakerQuickActionView!
    @IBOutlet weak var bottomPanelView: UIView!
    @IBOutlet weak var firstNameTextfield: UITextField!
    @IBOutlet weak var lastNameTextfield: UITextField!
    @IBOutlet weak var meetingNameInputTextfield: UITextField!
    @IBOutlet weak var startMeetingButton: UIButton!
    @IBOutlet weak var loadingIndicator: UIActivityIndicatorView!
    @IBOutlet weak var bottomConstraint: NSLayoutConstraint!
    
    // MARK: - Internal properties
    let viewModel: MeetingCreatingViewModel
    var configurationType: MeetingConfigurationType?

     init(viewModel: MeetingCreatingViewModel) {
        self.viewModel = viewModel
        super.init(nibName: nil, bundle: nil)
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) is not supported")
    }

    override var hidesBottomBarWhenPushed: Bool {
        get {
            return true
        }
        set {
            super.hidesBottomBarWhenPushed = newValue
        }
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        configureImages()
        registerForNotifications()
        
        navigationItem.leftBarButtonItem = UIBarButtonItem(
            title: Strings.Localizable.close,
            style: .plain,
            target: self,
            action: #selector(dismissVC(_:))
        )

        configureUI()
                
        viewModel.invokeCommand = { [weak self] command in
            self?.executeCommand(command)
        }

        viewModel.dispatch(.onViewReady)
    }
    
    // MARK: - Private methods.
    
    private func configureImages() {
        localUserView.mutedImage = MEGAAssets.UIImage.image(named: "micMuted")

        enableDisableVideoButton.setImage(MEGAAssets.UIImage.image(named: "callControlCameraDisabled"), for: .normal)
        enableDisableVideoButton.setImage(MEGAAssets.UIImage.image(named: "callControlCameraEnabled"), for: .selected)

        muteUnmuteMicrophoneButton.setImage(MEGAAssets.UIImage.image(named: "callControlMicDisabled"), for: .normal)
        muteUnmuteMicrophoneButton.setImage(MEGAAssets.UIImage.image(named: "callControlMicEnabled"), for: .selected)

        speakerQuickActionView.icon = MEGAAssets.UIImage.image(named: "callControlSpeakerEnabled")
    }

    private func registerForNotifications() {
        NotificationCenter.default.addObserver(self, selector: #selector(keyboardWillShow(_:)), name: UIResponder.keyboardWillShowNotification, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(keyboardWillHide(_:)), name: UIResponder.keyboardWillHideNotification, object: nil)
    }
    
    @objc private func textFieldTextChanged(textField: UITextField) {
        guard let text = textField.text else { return }
        
        switch textField {
        case firstNameTextfield:
            viewModel.dispatch(.updateFirstName(text))
            updateJoinMeetingButton()
            
        case lastNameTextfield:
            viewModel.dispatch(.updateLastName(text))
            updateJoinMeetingButton()

        case meetingNameInputTextfield:
            viewModel.dispatch(.updateMeetingName(text))
            
        default:
            break
        }
    }
    
    private func configureUI() {
        view.backgroundColor = Constants.backgroundColor
        
        firstNameTextfield.font = Constants.bottomBarText
        firstNameTextfield.delegate = self
        firstNameTextfield.addTarget(self, action: #selector(textFieldTextChanged(textField:)), for: .editingChanged)
        
        lastNameTextfield.font = Constants.bottomBarText
        lastNameTextfield.delegate = self
        lastNameTextfield.addTarget(self, action: #selector(textFieldTextChanged(textField:)), for: .editingChanged)
        
        meetingNameInputTextfield.font = Constants.bottomBarText
        meetingNameInputTextfield.delegate = self
        meetingNameInputTextfield.addTarget(self, action: #selector(textFieldTextChanged(textField:)), for: .editingChanged)
        
        startMeetingButton.setTitle(Strings.Localizable.Meetings.CreateMeeting.startMeeting, for: .normal)
        setupColorForStartMeetingButton()
        startMeetingButton.layer.cornerRadius = 8
        startMeetingButton.titleLabel?.font = Constants.bottomBarButtonText
        
        speakerQuickActionView.properties = MeetingQuickActionView.Properties(
            iconTintColor: MeetingQuickActionView.Properties.StateColor(normal: Constants.iconTintColorNormal, selected: Constants.iconTintColorSelected),
            backgroundColor: MeetingQuickActionView.Properties.StateColor(normal: TokenColors.Button.primary, selected: TokenColors.Button.secondary)
        )
        
        bottomPanelView.backgroundColor = TokenColors.Background.surface1
        localUserView.backgroundColor = TokenColors.Background.page
        enableDisableVideoButton.backgroundColor = TokenColors.Button.primary
        enableDisableVideoButton.layer.cornerRadius = enableDisableVideoButton.frame.size.width / 2
        muteUnmuteMicrophoneButton.backgroundColor = TokenColors.Button.secondary
        muteUnmuteMicrophoneButton.layer.cornerRadius = enableDisableVideoButton.frame.size.width / 2
    }

    @objc private func dismissVC(_ barButtonItem: UIBarButtonItem) {
        viewModel.dispatch(.didTapCloseButton)
    }
    
    private func executeCommand(_ command: MeetingCreatingViewModel.Command) {
        switch command {
        case .configView(let title, let type, let isMicrophoneEnabled):
            self.title = title
            configurationType = type
            localUserView.configureForFullSize()
            meetingNameInputTextfield.isEnabled = type == .start
            muteUnmuteMicrophoneButton.isSelected = !isMicrophoneEnabled
            configureMeetingFor(type: type, title: title)
        case .updateMeetingName(let name):
            title = name.isEmpty ? meetingNameInputTextfield.placeholder : name
            if meetingNameInputTextfield.text != name {
                meetingNameInputTextfield.text = name
            }
        case .updateAvatarImage(let image):
            localUserView.updateAvatar(image: image)
        case .updateVideoButton(enabled: let isSelected):
            enableDisableVideoButton.isSelected = isSelected
            enableDisableVideoButton.backgroundColor = isSelected ? TokenColors.Button.secondary : TokenColors.Button.primary
            localUserView.switchVideo(to: isSelected)
        case .updateMicrophoneButton(enabled: let isSelected):
            muteUnmuteMicrophoneButton.isSelected = !isSelected
            muteUnmuteMicrophoneButton.backgroundColor = isSelected ? TokenColors.Button.primary : TokenColors.Button.secondary
        case .loadingStartMeeting:
            showLoadingStartMeeting()
        case .loadingEndMeeting:
            showLoadingEndMeeting()
        case .localVideoFrame(width: let width, height: let height, buffer: let buffer):
            guestVideoFrame(width: width, height: height, buffer: buffer)
        case .updatedAudioPortSelection(let audioPort, let bluetoothAudioRouteAvailable):
            selectedAudioPortUpdated(audioPort, isBluetoothRouteAvailable: bluetoothAudioRouteAvailable)
        case .updateCameraPosition:
            break
        }
    }
    
    private func selectedAudioPortUpdated(_ selectedAudioPort: AudioPort, isBluetoothRouteAvailable: Bool) {
        if isBluetoothRouteAvailable {
            speakerQuickActionView.addRoutingView()
        } else {
            speakerQuickActionView.removeRoutingView()
        }
        speakerQuickActionView.selectedAudioPortUpdated(selectedAudioPort, isBluetoothRouteAvailable: isBluetoothRouteAvailable)
    }
    
    private func guestVideoFrame(width: Int, height: Int, buffer: Data!) {
        localUserView.frameData(width: width, height: height, buffer: buffer)
    }
    
    private func updateJoinMeetingButton() {
        guard let configType = configurationType,
              configType == .guestJoin,
              let firstName = firstNameTextfield.text,
              let lastname = lastNameTextfield.text else {
            return
        }
        
        let trimmedFirstName = firstName.trimmingCharacters(in: .whitespaces)
        let trimmedLastName = lastname.trimmingCharacters(in: .whitespaces)
        startMeetingButton.isEnabled = !trimmedFirstName.isEmpty && !trimmedLastName.isEmpty
        setupColorForStartMeetingButton()
    }
    
    private func showLoadingEndMeeting() {
        startMeetingButton.isHidden = false
        loadingIndicator.stopAnimating()
        
        firstNameTextfield.isEnabled = true
        lastNameTextfield.isEnabled = true
        meetingNameInputTextfield.isEnabled = true
        
        enableDisableVideoButton.isUserInteractionEnabled = true
        speakerQuickActionView.isUserInteractionEnabled = true
        muteUnmuteMicrophoneButton.isUserInteractionEnabled = true
    }
    
    fileprivate func showLoadingStartMeeting() {
        startMeetingButton.isHidden = true
        loadingIndicator.startAnimating()
        
        firstNameTextfield.isEnabled = false
        lastNameTextfield.isEnabled = false
        meetingNameInputTextfield.isEnabled = false
        
        enableDisableVideoButton.isUserInteractionEnabled = false
        speakerQuickActionView.isUserInteractionEnabled = false
        muteUnmuteMicrophoneButton.isUserInteractionEnabled = false
        
        resignFirstResponder()
    }
    
    private func configureMeetingFor(type: MeetingConfigurationType, title: String) {
        switch type {
        case .guestJoin:
            meetingNameInputTextfield.isHidden = true
            startMeetingButton.setTitle(Strings.Localizable.Meetings.Link.Guest.joinButtonText, for: .normal)
            startMeetingButton.isEnabled = false
            setupColorForStartMeetingButton()
            
            firstNameTextfield.attributedPlaceholder = NSAttributedString(
                string: Strings.Localizable.firstName,
                attributes: [NSAttributedString.Key.foregroundColor: Constants.placeholderTextColor,
                             NSAttributedString.Key.font: Constants.bottomBarText]
            )
            lastNameTextfield.attributedPlaceholder = NSAttributedString(
                string: Strings.Localizable.lastName,
                attributes: [NSAttributedString.Key.foregroundColor: Constants.placeholderTextColor,
                             NSAttributedString.Key.font: Constants.bottomBarText]
            )
            firstNameTextfield.isHidden = false
            lastNameTextfield.isHidden = false
            
            guard let avatarImage = UIImage(forName: AvatarProperties.initials, size: AvatarProperties.size, backgroundColor: AvatarProperties.backgroundColor, backgroundGradientColor: AvatarProperties.backgroundGradientColor, textColor: AvatarProperties.textColor, font: AvatarProperties.font) else { return }
            localUserView.updateAvatar(image: avatarImage)
        case .join:
            meetingNameInputTextfield.isHidden = true
            startMeetingButton.setTitle(Strings.Localizable.Meetings.Link.LoggedInUser.joinButtonText, for: .normal)
            
            firstNameTextfield.isHidden = true
            lastNameTextfield.isHidden = true
            
            viewModel.dispatch(.loadAvatarImage)
            
        case .start:
            meetingNameInputTextfield.attributedPlaceholder = NSAttributedString(
                string: title,
                attributes: [NSAttributedString.Key.foregroundColor: Constants.meetingNameTextColor]
            )
            firstNameTextfield.isHidden = true
            lastNameTextfield.isHidden = true
            meetingNameInputTextfield.isHidden = false
            viewModel.dispatch(.loadAvatarImage)
        }
    }
    
    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        if textField == firstNameTextfield {
            lastNameTextfield.becomeFirstResponder()
        } else {
            textField.resignFirstResponder()
        }
        
        return true
    }
    
    @IBAction func videoButtonTapped(_ sender: Any) {
        viewModel.dispatch(.didTapVideoButton)
    }
    
    @IBAction func micButtonTapped(_ sender: Any) {
        viewModel.dispatch(.didTapMicroPhoneButton)
    }
    
    @IBAction func speakerButtonTapped(_ sender: Any) {
        viewModel.dispatch(.didTapSpeakerButton)
    }
    
    @IBAction func startMeetingButtonTapped(_ sender: Any) {
        viewModel.dispatch(.didTapStartMeetingButton)
    }
    
    @objc func keyboardWillShow(_ notification: Notification) {
        guard let duration = notification.userInfo?[UIResponder.keyboardAnimationDurationUserInfoKey] as? TimeInterval, let keyboardValue = notification.userInfo?[UIResponder.keyboardFrameEndUserInfoKey] as? NSValue else { return }
        
        bottomConstraint.constant = keyboardValue.cgRectValue.height - view.safeAreaInsets.bottom
        UIView.animate(withDuration: duration) {
            self.view.layoutIfNeeded()
        }
    }
    
    @objc func keyboardWillHide(_ notification: Notification) {
        guard let duration = notification.userInfo?[UIResponder.keyboardAnimationDurationUserInfoKey] as? TimeInterval else { return }

        bottomConstraint.constant = 0
        UIView.animate(withDuration: duration) {
            self.view.layoutIfNeeded()
        }
    }
    
    private func setupColorForStartMeetingButton() {
        if startMeetingButton.isEnabled {
            startMeetingButton.backgroundColor = TokenColors.Button.primary
            startMeetingButton.setTitleColor(TokenColors.Text.inverse, for: UIControl.State.normal)
        } else {
            startMeetingButton.backgroundColor = TokenColors.Button.disabled
            startMeetingButton.setTitleColor(TokenColors.Text.disabled, for: UIControl.State.normal)
        }
    }
}
