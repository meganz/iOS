import UIKit

protocol ExploreViewStackDelegate: AnyObject {
    func tappedCard(_ card: MEGAExploreViewStyle)
}

final class ExploreViewStack: UIView, NibOwnerLoadable {
    
    @IBOutlet weak var fillEqualStackView: UIStackView!
    @IBOutlet var cards: [ExplorerView]!
    weak var delegate: ExploreViewStackDelegate?
    
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
    
    @IBAction func cardTapped(_ sender: UIButton) {
        if let index = cards.firstIndex(where: { $0.subviews.contains(sender) }),
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
           let exploreViewStyleFactory = ExploreViewStyleFactory(style: MEGAExploreViewStyle(rawValue: $0) ?? .images,
                                                                 traitCollection: trait)
            cards[$0].configuration = exploreViewStyleFactory.configuration
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
