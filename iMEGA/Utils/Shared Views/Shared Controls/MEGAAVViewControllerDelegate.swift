import AVFoundation

@objc protocol MEGAAVViewControllerDelegate {
    @objc optional func didChangePlayerItemStatus(_ status: AVPlayerItem.Status)
    @objc optional func willStartPlayer()
    @objc optional func didStartPlayer()
    @objc optional func playerDidStall()
    @objc optional func playerDidChangeTimeControlStatus(_ status: AVPlayer.TimeControlStatus)
}
