import MEGADesignToken
import UIKit

class AudioWaveView: UIView {

    @IBOutlet weak var proportionalHeightConstraint: NSLayoutConstraint!
    var proportionalDefaultMultiplier: CGFloat = .zero
    
    @IBOutlet weak var representationView: UIView!

    override func awakeFromNib() {
        super.awakeFromNib()
        proportionalDefaultMultiplier = proportionalHeightConstraint?.multiplier ?? .zero
        representationView.backgroundColor = TokenColors.Icon.accent
    }

    /// The value of level can be between 1 and 100
    var level: Int = 1 {
        didSet {
            guard level >= 1 && level <= 100 else {
                fatalError("AudioWaveView: level range should be from 1 to 100 including both")
            }

            removeConstraint(proportionalHeightConstraint)
            proportionalHeightConstraint = representationView.heightAnchor.constraint(equalTo: heightAnchor,
                                                                                      multiplier: multiplier)
            proportionalHeightConstraint.isActive = true
        }
    }
    
    func reset() {
        level = 1
    }
    
    private var multiplier: CGFloat {
        proportionalDefaultMultiplier + blockLevel
    }
    
    private var blockLevel: CGFloat {
        let range: CGFloat = CGFloat(1.0) - proportionalDefaultMultiplier
        let block: CGFloat = range / CGFloat(99.0)
        return block * CGFloat(level)
    }
}
