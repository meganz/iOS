import AudioToolbox
import AVFAudio
import Foundation
import MEGAAppSDKRepo
import MEGADomain

public final class TonePlayer: NSObject {
    public enum ToneType: String {
        case callEnded
        case participantJoined
        case participantLeft
        case reconnecting
        case waitingRoomEvent
        case outgoingTone
        case audioClipSent
        
        fileprivate var fileURL: URL? {
            Bundle.main.url(forResource: rawValue, withExtension: "wav")
        }
    }
    
    private var audioPlayer: AVAudioPlayer?
    private var audioSessionUseCase: (any AudioSessionUseCaseProtocol)?
    
    public func play(tone: ToneType, numberOfLoops loops: Int = 0) {
        guard let toneURL = tone.fileURL else {
            MEGALogDebug("\(tone.rawValue) file not found")
            return
        }
        
        stopAudioPlayer()

        self.audioPlayer = try? AVAudioPlayer(contentsOf: toneURL)
        self.audioPlayer?.delegate = self
        self.audioPlayer?.volume = 1
        self.audioPlayer?.numberOfLoops = loops
        self.audioPlayer?.play()
    }
    
    public func stopAudioPlayer() {
        if let audioPlayer = audioPlayer {
            audioPlayer.stop()
            resetAudioPlayer()
        }
    }
    
    public func playSystemSound(_ tone: ToneType, vibrate: Bool = false) {
        guard let tonePath = tone.fileURL else {
            MEGALogDebug("\(tone.rawValue) file not found")
            return
        }
        
        if vibrate {
            AudioServicesPlaySystemSound(kSystemSoundID_Vibrate)
        }
        
        var soundID: SystemSoundID = 0
        AudioServicesCreateSystemSoundID(tonePath as CFURL, &soundID)

        AudioServicesPlaySystemSoundWithCompletion(soundID) {
            AudioServicesDisposeSystemSoundID(soundID)
        }
    }
    
    private func resetAudioPlayer() {
        self.audioPlayer?.delegate = nil
        self.audioPlayer = nil
    }
}

extension TonePlayer: AVAudioPlayerDelegate {
    public func audioPlayerDidFinishPlaying(_ player: AVAudioPlayer, successfully flag: Bool) {
        if player === self.audioPlayer {
            resetAudioPlayer()
        }
        
        audioSessionUseCase?.configureCallAudioSession()
    }
}
