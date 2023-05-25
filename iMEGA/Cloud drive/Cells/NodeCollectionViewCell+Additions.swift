import MEGADomain
import MEGAData

extension NodeCollectionViewCell {
    
    @objc func createNodeCollectionCellViewModel() -> NodeCollectionViewCellViewModel {
        let mediaUseCase = MediaUseCase(fileSearchRepo: FilesSearchRepository.newRepo,
                                        videoMediaUseCase: VideoMediaUseCase(videoMediaRepository: VideoMediaRepository.newRepo))
        return NodeCollectionViewCellViewModel(mediaUseCase: mediaUseCase)
    }
    
    @objc func setDurationForVideo(path: String) {
        let asset = AVURLAsset(url: URL(fileURLWithPath: path, isDirectory: false))
        asset.loadValuesAsynchronously(forKeys: ["duration"]) {
            DispatchQueue.main.async {
                var error: NSError?
                switch asset.statusOfValue(forKey: "duration", error: &error) {
                case .loaded:
                    let time = asset.duration
                    let seconds = CMTimeGetSeconds(time)
                    if seconds > 0, !CMTIME_IS_POSITIVEINFINITY(time) {
                        self.durationLabel?.isHidden = false
                        self.durationLabel?.layer.cornerRadius = 4
                        self.durationLabel?.layer.masksToBounds = true
                        self.durationLabel?.text = seconds.timeString
                    } else {
                        self.durationLabel?.isHidden = true
                    }
                default:
                    self.durationLabel?.isHidden = true
                }
            }
        }
    }
}
