import UIKit

protocol ExploreViewStackDelegate: AnyObject {
    func tappedCard(_ card: MEGAExploreViewStyle)
}

final class ExploreViewStack: UIView, NibOwnerLoadable {
    
    @IBOutlet weak var fillEqualStackView: UIStackView!
    @IBOutlet var cards: [ExploreView]!
    weak var delegate: ExploreViewStackDelegate?
    
    // MARK: - Handlers
    
    var imageCardTappedHandler: (() -> Void)?

    
    // MARK: - Initialization
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        addStackView()
        setupView(with: traitCollection)
    }
    
    required init?(coder: NSCoder) {
        super.init(coder: coder)
        addStackView()
        setupView(with: traitCollection)
    }
    
    // MARK: Actions
    
    @IBAction func cardTapped(_ sender: ExploreView) {
        if let index = cards.firstIndex(of: sender),
            let card = MEGAExploreViewStyle(rawValue: index) {
            delegate?.tappedCard(card)
        }
    }
    
    // MARK: - Privates
    
    private func addStackView() {
        guard let contentview = loadedViewFromNibContent() else { return }
        contentview.translatesAutoresizingMaskIntoConstraints = false
        addSubview(contentview)
        contentview.autoPinEdgesToSuperviewEdges(
            with: .init(top: 0, left: 20, bottom: 0, right: 20)
        )
    }

    private func setupView(with trait: UITraitCollection) {
        setupBackgroundColor(with: trait)

        fillEqualStackView.axis = .horizontal
        fillEqualStackView.distribution = .fillEqually
        fillEqualStackView.spacing = 8
        
        (0..<cards.count).forEach {
            setupCard(cards[$0], style: MEGAExploreViewStyle(rawValue: $0) ?? .images, trait: trait)
        }
    }
    
    private func setupBackgroundColor(with trait: UITraitCollection) {
        switch trait.theme {
        case .dark:
            backgroundColor = .black
            subviews.first?.backgroundColor = .black
        default:
            backgroundColor = .mnz_grayF7F7F7()
            subviews.first?.backgroundColor = .mnz_grayF7F7F7()
        }
    }

    private func setupCard(_ explorerView: ExploreView, style: MEGAExploreViewStyle, trait: UITraitCollection) {
        let styler = trait.theme.exploreViewStyleFactory.styler(of: style)
        styler(explorerView)
    }
    
    // MARK: - Actions
    @IBAction func imagesCardTapped(_ sender: ExploreView) {
        if let handler = imageCardTappedHandler {
            handler()
        }
    }    
}

// MARK: - TraitEnviromentAware

extension ExploreViewStack: TraitEnviromentAware {


    override func traitCollectionDidChange(_ previousTraitCollection: UITraitCollection?) {
        super.traitCollectionDidChange(previousTraitCollection)
        traitCollectionChanged(to: traitCollection, from: previousTraitCollection)
    }

    func colorAppearanceDidChange(to currentTrait: UITraitCollection, from previousTrait: UITraitCollection?) {
        setupView(with: currentTrait)
    }
}
