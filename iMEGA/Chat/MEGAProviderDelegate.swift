
import Foundation

extension MEGAProviderDelegate {
    @objc func playCallEndedTone() {
        self.tonePlayer = TonePlayer()
        self.tonePlayer.play(tone: .callEnded)
    }
}
