import UIKit
import Video

final class VideoPlaylistContentViewController: UIViewController {
    
    private let videoConfig: VideoConfig
    private let previewEntity: VideoPlaylistCellPreviewEntity
    
    init(
        videoConfig: VideoConfig,
        previewEntity: VideoPlaylistCellPreviewEntity
    ) {
        self.videoConfig = videoConfig
        self.previewEntity = previewEntity
        super.init(nibName: nil, bundle: nil)
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        setupContentView()
    }
    
    private func setupContentView() {
        let contentView = VideoRevampFactory.makeVideoContentContainerView(
            videoConfig: videoConfig,
            previewEntity: previewEntity
        )
        
        add(contentView, container: view, animate: false)
        
        view.backgroundColor = UIColor(videoConfig.colorAssets.pageBackgroundColor)
    }
}
