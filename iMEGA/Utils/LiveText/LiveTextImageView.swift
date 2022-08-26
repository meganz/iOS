import VisionKit

@available(iOS 16.0, *)
final class LiveTextImageView: UIImageView {
    private lazy var interaction: ImageAnalysisInteraction = {
        let interaction = ImageAnalysisInteraction()
        interaction.preferredInteractionTypes = .automatic
        return interaction
    }()
    
    private lazy var imageAnalyzer = ImageAnalyzer()
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        
        guard ImageAnalyzer.isSupported else { return }
        self.addInteraction(interaction)
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    @MainActor
    func startAnalysis() {
        guard let image = image, ImageAnalyzer.isSupported else {
            return
        }
        
        Task {
            let configuration = ImageAnalyzer.Configuration([.text, .machineReadableCode])
            
            do {
                let analysis = try await imageAnalyzer.analyze(image, configuration: configuration)
                interaction.analysis = analysis
                interaction.preferredInteractionTypes = .automatic
            } catch {
                MEGALogError("Error in live text analysis: \(error.localizedDescription)")
            }
        }
    }
    
    @MainActor
    func setLiveTextInterfaceHidden(isHidden: Bool, animated: Bool) {
        interaction.setSupplementaryInterfaceHidden(isHidden, animated: animated)
    }
    
    func isInterfaceHidden() -> Bool {
        interaction.isSupplementaryInterfaceHidden
    }
    
    func isInteractionAnalysisEmpty() -> Bool {
        interaction.analysis == nil
    }
    
    @MainActor
    func setSupplementaryInterfaceContentInsets(_ insets: UIEdgeInsets) {
        interaction.supplementaryInterfaceContentInsets = insets
    }
}

//MARK: - UIImageView Live Text
extension UIImageView {
    @objc func startImageLiveTextAnalysisIfNeeded() {
        guard #available(iOS 16, *),
              let liveTextImageView = self as? LiveTextImageView,
              liveTextImageView.isInteractionAnalysisEmpty() else {
            return
        }
        liveTextImageView.startAnalysis()
    }
    
    @objc func setImageLiveTextInterfaceHidden(_ isHidden: Bool, animated: Bool = true) {
        guard #available(iOS 16, *),
              let liveTextImageView = self as? LiveTextImageView,
              liveTextImageView.isInterfaceHidden() != isHidden else {
            return
        }
        liveTextImageView.setLiveTextInterfaceHidden(isHidden: isHidden, animated: animated)
    }
    
    @objc func setImageLiveTextSupplementaryInterfaceContentInsets(_ insets: UIEdgeInsets) {
        guard #available(iOS 16, *),
              let liveTextImageView = self as? LiveTextImageView else {
            return
        }
        liveTextImageView.setSupplementaryInterfaceContentInsets(insets)
    }
}
