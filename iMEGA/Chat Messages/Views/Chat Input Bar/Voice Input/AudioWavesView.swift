
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
        let eachBlockWidth = eachViewAndSpacingWidth * CGFloat(2.0)
        let numberOfViews = Int(round(totalWidthAvailable / eachBlockWidth))
        
        guard stackView.arrangedSubviews.count != numberOfViews else {
            return
        }
        
        if stackView.arrangedSubviews.count < numberOfViews {
            let balance = numberOfViews - stackView.arrangedSubviews.count
            var level = 1
            
            if stackView.arrangedSubviews.count > 0,
                let audioWaveView = stackView.arrangedSubviews[stackView.arrangedSubviews.count - 1] as? AudioWaveView {
                level = audioWaveView.level
            }
            
            (0..<balance).forEach { _ in
                addAudioView(withLevel: level)
            }
        } else {
            let balance = stackView.arrangedSubviews.count - numberOfViews
            (0..<balance).forEach { _ in
                stackView.arrangedSubviews.first?.removeFromSuperview()
            }
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
    
    func reset() {
        stackView.arrangedSubviews.forEach { view in
            guard let audioWaveView = view as? AudioWaveView else {
                return
            }
            
            audioWaveView.reset()
        }
    }
}
