import UIKit

class AudioWaveView: UIView {

    @IBOutlet weak var proportionalHeightConstraint: NSLayoutConstraint!
    var proportionalDefaultMultiplier: CGFloat!
    
    @IBOutlet weak var representationView: UIView!

    override func awakeFromNib() {
        super.awakeFromNib()
        proportionalDefaultMultiplier = proportionalHeightConstraint.multiplier
    }

    /// The value of level can be between 1 and 100
    var level: Int = 1 {
        didSet {
            guard level >= 1 && level <= 100 else {
                fatalError("AudioWaveView: level range should be from 1 to 100 including both")
            }
            let newLevel: CGFloat = CGFloat(level)
            let defaultMultiplier: CGFloat = proportionalDefaultMultiplier
            let range = 1.0 - defaultMultiplier
            let block = range / 99.0
            let blockLevel = block * newLevel
            let multiplier = defaultMultiplier + blockLevel
            
            removeConstraint(proportionalHeightConstraint)
            proportionalHeightConstraint = representationView.heightAnchor.constraint(equalTo: heightAnchor,
                                                                                      multiplier: multiplier)
            proportionalHeightConstraint.isActive = true
        }
    }
    
    func reset() {
        level = 1
    }
}
