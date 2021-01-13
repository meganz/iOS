import UIKit

protocol PSAViewDelegate: AnyObject {
    func openPSAURLString(_ urlString: String);
    func dismiss(psaView: PSAView)
}

class PSAView: UIView {
    
    var viewModel: PSAViewModel! {
        didSet {
            viewModel.invokeCommand = { [weak self] command in
                guard let self = self else { return }
                
                switch command {
                case .configView(let psaEntity):
                    self.psaEntity = psaEntity
                }
            }
            
            viewModel.dispatch(.onViewReady)
        }
    }
    
    weak var delegate: PSAViewDelegate?
    
    private var psaEntity: PSAEntity? {
        didSet {
            guard let psaEntity = psaEntity else {
                return
            }
            
            titleLabel.text = psaEntity.title
            descriptionLabel.text = psaEntity.description
            if let imageURLString = psaEntity.imageURL,
               let imageURL = URL(string: imageURLString) {
                imageView.yy_imageURL = imageURL
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
            
            closeButton.setTitle(NSLocalizedString("close", comment: ""), for: .normal)
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
    }
    
    @IBAction func leftButtonTapped(_ sender: UIButton) {
        defer {
            if let positiveButtonLink = psaEntity?.positiveLink, psaEntity?.positiveText != nil {
                delegate?.openPSAURLString(positiveButtonLink)
            }
        }
        delegate?.dismiss(psaView: self)
    }
    
    
    @IBAction func rightButtonTapped(_ sender: UIButton) {
        delegate?.dismiss(psaView: self)
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
