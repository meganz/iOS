@preconcurrency import VisionKit

final class LiveTextImageView: SDAnimatedImageView {
    private lazy var interaction = {
        let interaction = ImageAnalysisInteraction()
        return interaction
    }()
    
    private let imageAnalyzer = ImageAnalyzer()
    
    override init(frame: CGRect) {
        super.init(frame: frame)
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    @MainActor
    func startAnalysis() {
        guard let image else { return }
        
        addInteraction(interaction)
        
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

// MARK: - UIImageView Live Text
extension UIImageView {
    @objc func startImageLiveTextAnalysisIfNeeded() {
        guard let liveTextImageView = self as? LiveTextImageView,
              liveTextImageView.isInteractionAnalysisEmpty() else {
            return
        }
        liveTextImageView.startAnalysis()
    }
    
    @objc func setImageLiveTextInterfaceHidden(_ isHidden: Bool, animated: Bool = true) {
        guard let liveTextImageView = self as? LiveTextImageView,
              liveTextImageView.isInterfaceHidden() != isHidden else {
            return
        }
        liveTextImageView.setLiveTextInterfaceHidden(isHidden: isHidden, animated: animated)
    }
    
    @objc func setImageLiveTextSupplementaryInterfaceContentInsets(_ insets: UIEdgeInsets) {
        guard let liveTextImageView = self as? LiveTextImageView else {
            return
        }
        liveTextImageView.setSupplementaryInterfaceContentInsets(insets)
    }
}
