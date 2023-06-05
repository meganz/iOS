import UIKit
import MEGAUIKit
import MEGADomain
import MEGAPresentation

final class PSAView: UIView, ViewType {
    
    var viewModel: PSAViewModel! {
        didSet {
            viewModel.invokeCommand = {[weak self] command in
                self?.executeCommand(command)
            }
            viewModel.dispatch(.onViewReady)
        }
    }
        
    private var psaEntity: PSAEntity? {
        didSet {
            guard let psaEntity = psaEntity else {
                return
            }
            
            titleLabel.text = psaEntity.title
            descriptionLabel.text = psaEntity.description
            if let imageURLString = psaEntity.imageURL,
               let imageURL = URL(string: imageURLString) {
                imageView.sd_setImage(with: imageURL)
                imageViewWidthConstraint.constant = imageDefaultWidth
                titleLabelLeadingConstraint.constant = titleLabelDefaultLeadingSpace
            } else {
                imageViewWidthConstraint.constant = 0.0
                titleLabelLeadingConstraint.constant = 0.0
            }
            
            let closeButton: UIButton
            
            if let positiveButtonText = psaEntity.positiveText,
               psaEntity.positiveLink != nil {
                leftButton.setTitle(positiveButtonText, for: .normal)
                closeButton = rightButton
                rightButton.isHidden = false
            } else {
                closeButton = leftButton
                rightButton.isHidden = true
            }
            
            closeButton.setTitle(Strings.Localizable.dismiss, for: .normal)
            setupView(with: traitCollection)
            sizeToFit()
        }
    }
    
    private var imageDefaultWidth: CGFloat = 0.0
    private var titleLabelDefaultLeadingSpace: CGFloat = 0.0

    @IBOutlet weak var imageView: UIImageView!
    @IBOutlet weak var imageViewWidthConstraint: NSLayoutConstraint!
    @IBOutlet weak var titleLabel: UILabel!
    @IBOutlet weak var titleLabelLeadingConstraint: NSLayoutConstraint!
    @IBOutlet weak var descriptionLabel: UILabel!
    @IBOutlet weak var leftButton: UIButton!
    @IBOutlet weak var rightButton: UIButton!
    @IBOutlet weak var topBorderView: UIView!
    @IBOutlet weak var bottomBorderView: UIView!

    override func awakeFromNib() {
        super.awakeFromNib()
        
        imageView.layer.cornerRadius = imageView.bounds.width / 2.0
        leftButton.layer.cornerRadius = 8.0
        rightButton.layer.cornerRadius = 8.0
        
        imageDefaultWidth = imageViewWidthConstraint.constant
        titleLabelDefaultLeadingSpace = titleLabelLeadingConstraint.constant
    }
    
    func executeCommand(_ command: PSAViewModel.Command) {
        switch command {
        case .configView(let psaEntity):
            self.psaEntity = psaEntity
        }
    }
    
    private func setupView(with trait: UITraitCollection) {
        if psaEntity?.positiveText != nil,
           psaEntity?.positiveLink != nil {
            leftButton.backgroundColor = .mnz_turquoise(for: trait)
            rightButton.backgroundColor = .mnz_secondaryGray(for: trait)
        } else {
            leftButton.backgroundColor = .mnz_secondaryGray(for: trait)
        }
        
        backgroundColor = .mnz_notificationSeenBackground(for: trait)
        topBorderView.backgroundColor = .mnz_separator(for: trait)
        bottomBorderView.backgroundColor = .mnz_separator(for: trait)
        imageView.backgroundColor = Colors.Psa.imageBackground.color
    }
    
    @IBAction func leftButtonTapped(_ sender: UIButton) {
        defer {
            if let positiveButtonLink = psaEntity?.positiveLink, psaEntity?.positiveText != nil {
                viewModel.dispatch(.openPSAURLString(positiveButtonLink))
            }
        }
        
        guard let psaEntity = psaEntity else {
            MEGALogDebug("PSA Entity was nil")
            return
        }
        
        viewModel.dispatch(.dimiss(psaView: self, psaEntity: psaEntity))
    }
    
    @IBAction func rightButtonTapped(_ sender: UIButton) {
        guard let psaEntity = psaEntity else {
            MEGALogDebug("PSA Entity was nil")
            return
        }
        
        viewModel.dispatch(.dimiss(psaView: self, psaEntity: psaEntity))
    }
}

// MARK: - TraitEnviromentAware

extension PSAView: TraitEnviromentAware {

    override func traitCollectionDidChange(_ previousTraitCollection: UITraitCollection?) {
        super.traitCollectionDidChange(previousTraitCollection)
        traitCollectionChanged(to: traitCollection, from: previousTraitCollection)
    }

    func colorAppearanceDidChange(to currentTrait: UITraitCollection, from previousTrait: UITraitCollection?) {
        setupView(with: currentTrait)
    }
}
