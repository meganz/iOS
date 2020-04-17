
import UIKit

class AudioWavesView: UIView {
    @IBOutlet weak var stackView: UIStackView!
        
    override func layoutSubviews() {
        super.layoutSubviews()
        updateView()
    }
    
    func updateView() {
        //Width of each view and spacing is 4.0
        let eachViewAndSpacingWidth: CGFloat = 4.0
        let totalWidthAvailable = bounds.width + eachViewAndSpacingWidth
        let eachBlockWidth = eachViewAndSpacingWidth * 2.0
        let numberOfViews = Int(round(totalWidthAvailable / eachBlockWidth))
        
        guard stackView.arrangedSubviews.count != numberOfViews else {
            return
        }
        
        stackView.arrangedSubviews.forEach { $0.removeFromSuperview() }
        (0..<numberOfViews).forEach { _ in
            addAudioView(withLevel: 1)
        }
    }
    
    func addAudioView(withLevel level: Int) {
        let audioWaveView = AudioWaveView.instanceFromNib
        audioWaveView.level = level
        stackView.addArrangedSubview(audioWaveView)
    }
    
    func updateAudioView(withLevel level: Int) {
        addAudioView(withLevel: level)
        stackView.arrangedSubviews.first?.removeFromSuperview()
    }
}
