import AVFoundation

struct AudioPlayerEventObserversLoadingLogicController {
    
    func shouldNotifyLoadingViewWhenReasonForWaitingToPlay(
        reasonForWaitingToPlay: AVPlayer.WaitingReason?,
        playerStatus: AVPlayer.Status,
        playerTimeControlStatus: AVPlayer.TimeControlStatus,
        isUserPreviouslyJustPlayedSameItem: Bool
    ) -> Bool {
        guard let waitingReason = reasonForWaitingToPlay else {
            return fallbackNotification(
                playerStatus: playerStatus,
                playerTimeControlStatus: playerTimeControlStatus
            )
        }
        
        return switch waitingReason {
        case .evaluatingBufferingRate, .toMinimizeStalls, .interstitialEvent, .waitingForCoordinatedPlayback: true
        default: false
        }
    }
    
    func shouldNotifyLoadingViewWhenDidChangeCurrentItemStatus(
        playerItemStatus: AVPlayerItem.Status
    ) -> Bool? {
        switch playerItemStatus {
        case .unknown, .readyToPlay: true
        case .failed: false
        default: nil
        }
    }
    
    private func fallbackNotification(
        playerStatus: AVPlayer.Status,
        playerTimeControlStatus: AVPlayer.TimeControlStatus
    ) -> Bool {
        switch (playerStatus, playerTimeControlStatus) {
        case (_, .playing), (.readyToPlay, _): false
        case (.unknown, .paused): true
        default: true // default to notifying for any other combination.
        }
    }
}
