import UIKit
import FlexLayout
import KeyboardLayoutGuide

class MeetingCreatingView: UIView, UITextFieldDelegate {
    private struct AvatarProperties {
        static let initials = "G"
        static let font = UIFont.preferredFont(forTextStyle: .title1).withWeight(.semibold)
        static let textColor = UIColor.white
        static let size = CGSize(width: 80, height: 80)
        static let backgroundColor = UIColor.mnz_(fromHexString: "#FF6F00")
        static let backgroundGradientColor = UIColor.mnz_(fromHexString: "#FFA700")
    }
    
    private struct Constants {
        static let bottomBarText = UIFont.preferredFont(style: .title3, weight: .semibold)
        static let bottomBarButtonText = UIFont.preferredFont(forTextStyle: .headline)
        static let backgroundColor = #colorLiteral(red: 0.2, green: 0.1843137255, blue: 0.1843137255, alpha: 1)
        static let textColor = UIColor.white
        static let iconTintColorNormal = UIColor.white
        static let iconTintColorSelected = UIColor.black
        static let iconBackgroundColorNormal = #colorLiteral(red: 0.1333158016, green: 0.1333456039, blue: 0.1333118975, alpha: 1)
        static let iconBackgroundColorSelected = UIColor.white
        static let meetingNameTextColor = UIColor.white.withAlphaComponent(0.2)
        static let placeholderTextColor = #colorLiteral(red: 1, green: 1, blue: 1, alpha: 0.3)
    }
       
    private weak var vc: MeetingCreatingViewController!
    private let containerView = UIView()
    private lazy var localVideoImageView: MEGALocalImageView = {
        let localVideoImageView = MEGALocalImageView()
        localVideoImageView.isHidden = true
        localVideoImageView.transform = CGAffineTransform(scaleX: -1, y: 1)
        localVideoImageView.contentMode = .scaleAspectFill
        return localVideoImageView
    }()
    
    private lazy var avatarImageView: UIImageView  = {
        let avatar = UIImageView()
        avatar.layer.cornerRadius = 40
        avatar.layer.masksToBounds = true
        avatar.mnz_setImageUsingCurrentUserAvatarOrColor()
        return avatar
    }()
    
    private lazy var enableDisableVideoButton: UIButton  = {
        let button = UIButton()
        button.setImage(UIImage(named: "cameraOff"), for: .normal)
        button.setImage(UIImage(named: "cameraOn"), for: .selected)
        return button
    }()
    private lazy var muteUnmuteMicrophoneButton: UIButton  = {
        let button = UIButton()
        button.setImage(UIImage(named: "micOn"), for: .normal)
        button.setImage(UIImage(named: "micOff"), for: .selected)
        button.isSelected = true
        return button
    }()
    private lazy var speakerQuickActionView: MeetingSpeakerQuickActionView  = {
        let circularView = CircularView()
        let iconImageView = UIImageView()
        
        let button = UIButton()
        button.setTitle(nil, for: .normal)
        button.addTarget(self, action: #selector(MeetingCreatingView.didTapSpeakerButton), for: .touchUpInside)

        
        let speakerView = MeetingSpeakerQuickActionView(circularView: circularView,
                                                        iconImageView: iconImageView,
                                                        nameLabel: nil,
                                                        button: button)
        speakerView.addSubviewSquared(circularView)
        speakerView.addSubviewCentered(iconImageView)
        speakerView.addSubviewSquared(button)
        
        speakerView.properties = MeetingQuickActionView.Properties(
            iconTintColor: MeetingQuickActionView.Properties.StateColor(normal: Constants.iconTintColorNormal,
                                                                        selected: Constants.iconTintColorSelected),
            backgroundColor: MeetingQuickActionView.Properties.StateColor(normal: Constants.iconBackgroundColorNormal,
                                                                          selected: Constants.iconBackgroundColorSelected)
        )
        
        return speakerView
    }()
    private lazy var switchCameraButton: UIButton  = {
        let button = UIButton()
        button.setImage(UIImage(named: "rotateOFF"), for: .normal)
        button.setImage(UIImage(named: "rotateON"), for: .selected)
        return button
    }()
    
    private lazy var firstNameTextfield: UITextField = {
        let input = UITextField()
        input.textAlignment = .center
        input.keyboardAppearance = .dark
        input.font = Constants.bottomBarText
        input.textColor = Constants.textColor
        input.delegate = self
        let placeholderText = NSAttributedString(
            string: Strings.Localizable.firstName,
            attributes: [NSAttributedString.Key.foregroundColor: Constants.placeholderTextColor,
                         NSAttributedString.Key.font: Constants.bottomBarText]
        )
        input.attributedPlaceholder = placeholderText
        input.setBlockFor(.editingChanged) { [weak self] textField in
            if let textField = textField as? UITextField, let text = textField.text {
                self?.viewModel.dispatch(.updateFirstName(text))
            }
            self?.updateJoinMeetingButton()
        }
        return input
    }()
    
    private lazy var lastNameTextfield: UITextField = {
        let input = UITextField()
        input.textAlignment = .center
        input.keyboardAppearance = .dark
        input.font = Constants.bottomBarText
        input.textColor = Constants.textColor
        input.delegate = self
        let placeholderText = NSAttributedString(
            string: Strings.Localizable.lastName,
            attributes: [NSAttributedString.Key.foregroundColor: Constants.placeholderTextColor,
                         NSAttributedString.Key.font: Constants.bottomBarText]
        )
        input.attributedPlaceholder = placeholderText
        input.setBlockFor(.editingChanged) { [weak self] textField in
            if let textField = textField as? UITextField, let text = textField.text {
                self?.viewModel.dispatch(.updateLastName(text))
            }
            self?.updateJoinMeetingButton()
        }
        return input
    }()
    
    private lazy var meetingNameInputTextfield: UITextField = {
        let input = UITextField()
        input.textAlignment = .center
        input.keyboardAppearance = .dark
        input.font = Constants.bottomBarText
        input.textColor = Constants.textColor
        input.delegate = self
        input.setBlockFor(.editingChanged) { [weak self] textField in
            if let textField = textField as? UITextField, let text = textField.text {
                self?.viewModel.dispatch(.updateMeetingName(text))
            }
        }
        return input
    }()
    private lazy var startMeetingButton: UIButton  = {
        let button = UIButton()
        button.setTitle(Strings.Localizable.Meetings.CreateMeeting.startMeeting.localizedCapitalized, for: .normal)
        button.mnz_setupPrimary(traitCollection)
        button.titleLabel?.font = Constants.bottomBarButtonText
        return button
    }()
    
    private lazy var loadingIndicator: UIActivityIndicatorView = {
        let indicator = UIActivityIndicatorView(style: .large)
        indicator.hidesWhenStopped = true
        return indicator
    }()

    // MARK: - Internal properties
    var viewModel: MeetingCreatingViewModel!
    var configurationType: MeetingConfigurationType?
    
    init(viewModel: MeetingCreatingViewModel, vc: MeetingCreatingViewController) {
        super.init(frame: .zero)
        self.vc = vc
        self.viewModel = viewModel
        containerView.flex.backgroundColor(Constants.backgroundColor).alignItems(.center).justifyContent(.end).define { flex in
            // video view
            flex.addItem(localVideoImageView).position(.absolute).all(0)
            flex.addItem().grow(1).shrink(1).justifyContent(.center).alignItems(.center).define { flex in
                // avatar View
                flex.addItem(avatarImageView).size(AvatarProperties.size)
            }
            
            // 4 buttons
            flex.addItem().direction(.row).justifyContent(.center).paddingBottom(16).define { flex in
                flex.addItem(enableDisableVideoButton).height(60).width(60)
                flex.addItem(muteUnmuteMicrophoneButton).height(60).width(60).marginLeft(36)
                flex.addItem(speakerQuickActionView).height(60).width(60).marginLeft(36)
                flex.addItem(switchCameraButton).paddingHorizontal(18).display(.none)
            }
            
            // control area
            flex.addItem().width(100%).paddingHorizontal(43).backgroundColor(.black).justifyContent(.center).define({ flex in
                // control panel
                flex.addItem().width(100%).marginTop(12).marginBottom(28).direction(.row).define { flex in
                    flex.addItem(firstNameTextfield).grow(1).shrink(1).paddingHorizontal(8).display(.none)
                    flex.addItem(lastNameTextfield).grow(1).shrink(1).paddingHorizontal(8).display(.none)
                    
                    flex.addItem(meetingNameInputTextfield).grow(1).shrink(1)

                }
                flex.addItem(startMeetingButton).height(50).marginBottom(16).grow(1).shrink(1)
                flex.addItem(loadingIndicator).height(50).marginBottom(16).display(.none)
            })
            
        }

        addSubview(containerView)
        
        containerView.autoPinEdge(toSuperviewSafeArea: .top)
        containerView.autoPinEdge(toSuperviewSafeArea: .left)
        containerView.autoPinEdge(toSuperviewSafeArea: .right)
        containerView.bottomAnchor.constraint(equalTo: keyboardLayoutGuide.topAnchor).isActive = true

        enableDisableVideoButton.addTarget(self, action: #selector(MeetingCreatingView.didTapVideoButton), for: .touchUpInside)
        muteUnmuteMicrophoneButton.addTarget(self, action: #selector(MeetingCreatingView.didTapMicroPhoneButton), for: .touchUpInside)
        switchCameraButton.addTarget(self, action: #selector(MeetingCreatingView.didTapSwitchCameraButton), for: .touchUpInside)
        startMeetingButton.addTarget(self, action: #selector(MeetingCreatingView.didTapStartMeetingButton), for: .touchUpInside)

        viewModel.invokeCommand = { [weak self] command in
            self?.excuteCommand(command)
        }

        viewModel.dispatch(.onViewReady)

    }
    
    required init?(coder _: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func layoutSubviews() {
        super.layoutSubviews()

        containerView.flex.layout()
    }
    
    // MARK: - Private methods.
    
    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        if textField == firstNameTextfield {
            lastNameTextfield.becomeFirstResponder()
        } else {
            textField.resignFirstResponder()
        }
        
        return true
    }
    
    @objc func didTapVideoButton() {
        viewModel.dispatch(.didTapVideoButton)
    }
    
    @objc func didTapMicroPhoneButton() {
        viewModel.dispatch(.didTapMicroPhoneButton)
    }
    
    @objc func didTapSpeakerButton() {
        viewModel.dispatch(.didTapSpeakerButton)
    }

    @objc func didTapSwitchCameraButton() {
        viewModel.dispatch(.didTapSwitchCameraButton)
    }
    
    @objc func didTapStartMeetingButton() {
        viewModel.dispatch(.didTapStartMeetingButton)
    }
    
    private func excuteCommand(_ command: MeetingCreatingViewModel.Command) {
        switch command {
        case .configView(let title, let type, let isMicrophoneEnabled):
            vc.title = title
            configurationType = type
            meetingNameInputTextfield.attributedPlaceholder = NSAttributedString(
                string: title,
                attributes: [NSAttributedString.Key.foregroundColor: Constants.meetingNameTextColor]
            )
            meetingNameInputTextfield.isEnabled = type == .start
            muteUnmuteMicrophoneButton.isSelected = !isMicrophoneEnabled

            switch type {
            case .guestJoin:
                meetingNameInputTextfield.isHidden = true
                startMeetingButton.setTitle(Strings.Localizable.Meetings.Link.Guest.joinButtonText, for: .normal)
                startMeetingButton.isEnabled = false
                startMeetingButton.alpha = 0.5
                
                firstNameTextfield.flex.display(.flex)
                lastNameTextfield.flex.display(.flex)

                meetingNameInputTextfield.flex.display(.none)
                avatarImageView.image = UIImage(forName: AvatarProperties.initials,
                                                size: AvatarProperties.size,
                                                backgroundColor: AvatarProperties.backgroundColor,
                                                backgroundGradientColor: AvatarProperties.backgroundGradientColor,
                                                textColor: AvatarProperties.textColor,
                                                font: AvatarProperties.font)
            case .join:
                meetingNameInputTextfield.isHidden = true
                startMeetingButton.setTitle(Strings.Localizable.Meetings.Link.LoggedInUser.joinButtonText, for: .normal)
                
                firstNameTextfield.flex.display(.none)
                lastNameTextfield.flex.display(.none)

                meetingNameInputTextfield.flex.display(.flex)
                viewModel.dispatch(.loadAvatarImage)
                
            case .start:
                firstNameTextfield.flex.display(.none)
                lastNameTextfield.flex.display(.none)
                meetingNameInputTextfield.flex.display(.flex)
                viewModel.dispatch(.loadAvatarImage)
            }
            
            containerView.flex.layout()

        case .updateMeetingName(let name):
            vc.title = name.isEmpty ? meetingNameInputTextfield.placeholder : name
            if meetingNameInputTextfield.text != name {
                meetingNameInputTextfield.text = name
            }
        case .updateAvatarImage(let image):
            avatarImageView.image = image
        case .updateVideoButton(enabled: let isSelected):
            enableDisableVideoButton.isSelected = isSelected
            avatarImageView.isHidden = isSelected
            localVideoImageView.isHidden = !isSelected
        case .updateCameraPosition(let position):
            switchCameraButton.isSelected = position == .front ? false : true
        case .updateMicrophoneButton(enabled: let isSelected):
            muteUnmuteMicrophoneButton.isSelected = !isSelected
        case .loadingStartMeeting:
            startMeetingButton.flex.display(.none)
            loadingIndicator.flex.display(.flex)
            loadingIndicator.startAnimating()

            containerView.flex.layout()
            
            firstNameTextfield.isEnabled = false
            lastNameTextfield.isEnabled = false
            meetingNameInputTextfield.isEnabled = false
            
            enableDisableVideoButton.isUserInteractionEnabled = false
            speakerQuickActionView.isUserInteractionEnabled = false
            muteUnmuteMicrophoneButton.isUserInteractionEnabled = false
            
            resignFirstResponder()
        case .loadingEndMeeting:
            startMeetingButton.flex.display(.flex)
            loadingIndicator.flex.display(.none)
            loadingIndicator.stopAnimating()

            containerView.flex.layout()
            
            firstNameTextfield.isEnabled = true
            lastNameTextfield.isEnabled = true
            meetingNameInputTextfield.isEnabled = true
            
            enableDisableVideoButton.isUserInteractionEnabled = true
            speakerQuickActionView.isUserInteractionEnabled = true
            muteUnmuteMicrophoneButton.isUserInteractionEnabled = true
        case .localVideoFrame(width: let width, height: let height, buffer: let buffer):
            guestVideoFrame(width: width, height: height, buffer: buffer)
        case .updatedAudioPortSelection(let audioPort, let bluetoothAudioRouteAvailable):
            selectedAudioPortUpdated(audioPort, isBluetoothRouteAvailable: bluetoothAudioRouteAvailable)
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
    
    private func setNavigationTitle(_ title: String, subtitle: String) {
        let titleViewLabel = Helper.customNavigationBarLabel(withTitle: title, subtitle: subtitle)
        titleViewLabel.lineBreakMode = .byTruncatingTail
        titleViewLabel.textColor = Constants.textColor
        vc.navigationItem.titleView = titleViewLabel
    }
    
    private func guestVideoFrame(width: Int, height: Int, buffer: Data!) {
        localVideoImageView.image = UIImage.mnz_convert(toUIImage: buffer, withWidth: width, withHeight: height)
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
        startMeetingButton.alpha = startMeetingButton.isEnabled ? 1.0 : 0.5
    }
}

fileprivate extension UIView {
    func addSubviewSquared(_ view: UIView) {
        view.translatesAutoresizingMaskIntoConstraints = false
        addSubview(view)
        
        let widthEqualAnchor = widthAnchor.constraint(equalTo: view.widthAnchor)
        widthEqualAnchor.priority = .defaultHigh
        
        let heightEqualAnchor = heightAnchor.constraint(equalTo: view.heightAnchor)
        heightEqualAnchor.priority = .defaultHigh
        
        [
            centerXAnchor.constraint(equalTo: view.centerXAnchor),
            centerYAnchor.constraint(equalTo: view.centerYAnchor),
            view.widthAnchor.constraint(equalTo: view.heightAnchor),
            widthAnchor.constraint(greaterThanOrEqualTo: view.widthAnchor, multiplier: 1.0),
            heightAnchor.constraint(greaterThanOrEqualTo: view.heightAnchor, multiplier: 1.0),
            widthEqualAnchor,
            heightEqualAnchor
        ].activate()
    }
    
    func addSubviewCentered(_ view: UIView) {
        view.translatesAutoresizingMaskIntoConstraints = false
        addSubview(view)
        [centerXAnchor.constraint(equalTo: view.centerXAnchor),
         centerYAnchor.constraint(equalTo: view.centerYAnchor)].activate()
    }
}
