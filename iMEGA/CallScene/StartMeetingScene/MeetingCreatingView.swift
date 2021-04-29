import UIKit
import FlexLayout
import KeyboardLayoutGuide

class MeetingCreatingView: UIView {
   
    private weak var vc: MeetingCreatingViewController!
    private let containerView = UIView()
    private lazy var localVideoImageView: MEGALocalImageView = {
        let localVideoImageView = MEGALocalImageView()
        localVideoImageView.isHidden = true
        localVideoImageView.transform = CGAffineTransform(scaleX: -1, y: 1)
        viewModel.dispatch(.addChatLocalVideo(delegate: localVideoImageView))
        return localVideoImageView
    } ()
    
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
        button.setImage(UIImage(named: "speakerOff"), for: .normal)
        button.setImage(UIImage(named: "speakerOn"), for: .selected)

        return button
    }()
    private lazy var enableDisableSpeakerButton: UIButton  = {
        let button = UIButton()
        button.setImage(UIImage(named: "micOn"), for: .normal)
        button.setImage(UIImage(named: "micOff"), for: .selected)
        return button
    }()
    private lazy var switchCameraButton: UIButton  = {
        let button = UIButton()
        button.setImage(UIImage(named: "rotateOFF"), for: .normal)
        button.setImage(UIImage(named: "rotateON"), for: .selected)
        return button
    }()
    
    private lazy var meetingNameInputTextfield: UITextField = {
        let input = UITextField()
        input.textAlignment = .center
        input.keyboardAppearance = .dark
        input.font = .systemFont(ofSize: 20, weight: .semibold)
        input.textColor = .white
        input.setBlockFor(.editingChanged) { [weak self] textField in
            if let textField = textField as? UITextField, let text = textField.text {
                self?.viewModel.dispatch(.updateMeetingName(text))
            }
        }
        return input
    }()
    private lazy var startMeetingButton: UIButton  = {
        let button = UIButton()
        button.setTitle(NSLocalizedString("Start Meeting", comment: ""), for: .normal)
        button.mnz_setupPrimary(traitCollection)
        return button
    }()
    
    private lazy var loadingIndicator: UIActivityIndicatorView = {
        let indicator = UIActivityIndicatorView(style: .whiteLarge)
        indicator.hidesWhenStopped = true
        return indicator
    }()

    // MARK: - Internal properties
    var viewModel: MeetingCreatingViewModel!
    
    init(viewModel: MeetingCreatingViewModel, vc: MeetingCreatingViewController) {
        super.init(frame: .zero)
        self.vc = vc
        self.viewModel = viewModel
        containerView.flex.backgroundColor(.systemGray).alignItems(.center).justifyContent(.end).define { flex in
            // video view
            flex.addItem(localVideoImageView).position(.absolute).all(0)
            flex.addItem().grow(1).shrink(1).justifyContent(.end).alignItems(.center).define { flex in
                // avatar View
                flex.addItem(avatarImageView).position(.absolute).width(80).height(80).top(50%).marginTop(-40)
                
                // 4 buttons
                flex.addItem().direction(.row).justifyContent(.center).paddingBottom(16).define { flex in
                    flex.addItem(enableDisableVideoButton).paddingHorizontal(18)
                    flex.addItem(enableDisableSpeakerButton).paddingHorizontal(18)
                    flex.addItem(muteUnmuteMicrophoneButton).paddingHorizontal(18)
                    flex.addItem(switchCameraButton).paddingHorizontal(18).display(.none)
                }
                
            }
            // control area
            flex.addItem().width(100%).paddingHorizontal(43).backgroundColor(.black).justifyContent(.center).define({ flex in
                // control panel
                flex.addItem(meetingNameInputTextfield).width(100%).marginTop(12).marginBottom(28)
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
        enableDisableSpeakerButton.addTarget(self, action: #selector(MeetingCreatingView.didTapSpeakerButton), for: .touchUpInside)
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
        case .configView(let title, let subtitle):
            vc.title = title
            meetingNameInputTextfield.attributedPlaceholder = NSAttributedString(string: title, attributes: [NSAttributedString.Key.foregroundColor: UIColor.white.withAlphaComponent(0.2)])

        case .updateMeetingName(let name):
            vc.title = name.isEmpty ? meetingNameInputTextfield.placeholder : name
        case .updateVideoButton(enabled: let isSelected):
            enableDisableVideoButton.isSelected = isSelected
            localVideoImageView.isHidden = !isSelected
            containerView.flex.layout()
        case .updateSpeakerButton(enabled: let isSelected):
            enableDisableSpeakerButton.isSelected = isSelected
        case .updateCameraSwitchType(type: let type):
            switch type {
            case .front:
                switchCameraButton.isSelected = true
            case .back:
                switchCameraButton.isSelected = false

            }
            
        case .updateMicroPhoneButton(enabled: let isSelected):
            muteUnmuteMicrophoneButton.isSelected = isSelected

        case .loadingMeeting:
            startMeetingButton.flex.display(.none)
            loadingIndicator.flex.display(.flex)
            loadingIndicator.startAnimating()

            containerView.flex.layout()
        }
    }
}
