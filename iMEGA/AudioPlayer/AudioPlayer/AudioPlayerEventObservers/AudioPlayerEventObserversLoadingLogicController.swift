import AVFoundation

struct AudioPlayerEventObserversLoadingLogicController {
    
    func shouldNotifyLoadingViewWhenReasonForWaitingToPlay(
        reasonForWaitingToPlay: AVPlayer.WaitingReason?,
        playerStatus: AVPlayer.Status,
        playerTimeControlStatus: AVPlayer.TimeControlStatus,
        isUserPreviouslyJustPlayedSameItem: Bool
    ) -> Bool {
        if let waitingReason = reasonForWaitingToPlay {
            switch waitingReason {
            case .evaluatingBufferingRate, .toMinimizeStalls, .interstitialEvent, .waitingForCoordinatedPlayback:
                return true
            default:
                return false
            }
        } else {
            let controller = ReasonWaitingToPlayNilLogicController()
            return controller.shouldNotifyLoadingView(
                reasonForWaitingToPlay: reasonForWaitingToPlay,
                playerStatus: playerStatus,
                playerTimeControlStatus: playerTimeControlStatus,
                isUserPreviouslyJustPlayedSameItem: isUserPreviouslyJustPlayedSameItem
            )
        }
    }
    
    func shouldNotifyLoadingViewWhenDidChangeCurrentItemStatus(playerItemStatus: AVPlayerItem.Status) -> Bool? {
        switch playerItemStatus {
        case .unknown, .readyToPlay:
            return true
        case .failed:
            return false
        default:
            return nil
        }
    }
    
    struct ReasonWaitingToPlayNilLogicController {
        
        func shouldNotifyLoadingView(
            reasonForWaitingToPlay: AVPlayer.WaitingReason?,
            playerStatus: AVPlayer.Status,
            playerTimeControlStatus: AVPlayer.TimeControlStatus,
            isUserPreviouslyJustPlayedSameItem: Bool
        ) -> Bool {
            let isPaused = playerTimeControlStatus == .paused
            let isReady = playerStatus == .readyToPlay
            let isUnknown = playerStatus == .unknown
            let isPlaying = playerTimeControlStatus == .playing
            
            if isUnknown && isPaused {
                return true
            } else if isReady {
                guard isPlaying else {
                    let isUserPausedCurrentPlayingItemWithoutChangingItemBefore = isPaused && isUserPreviouslyJustPlayedSameItem
                    return !isUserPausedCurrentPlayingItemWithoutChangingItemBefore
                }
                return false
            } else {
                return !(isPaused && isReady)
            }
        }
    }
}
