@preconcurrency import VisionKit

final class LiveTextImageView: SDAnimatedImageView {
    private lazy var interaction = {
        let interaction = ImageAnalysisInteraction()
        return interaction
    }()
    
    private let imageAnalyzer = ImageAnalyzer()
    
    private var hasCompletedAnalysis = false
    
    private var analysisTask: Task<Void, Never>?

    override init(frame: CGRect) {
        super.init(frame: frame)
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    deinit {
        analysisTask?.cancel()
    }
    
    @MainActor
    func startAnalysis() {
        guard let image, !hasCompletedAnalysis else { return }

        addInteraction(interaction)
        
        // Keep at most one analysis in flight
        analysisTask?.cancel()
        
        let analyzer = imageAnalyzer
        analysisTask = Task { [weak self] in
            let configuration = ImageAnalyzer.Configuration([.text, .machineReadableCode])
            
            do {
                let analysis = try await analyzer.analyze(image, configuration: configuration)
                guard !Task.isCancelled, let self else { return }
                analysisTask = nil
                hasCompletedAnalysis = true
                guard analysis.hasResults(for: [.text, .machineReadableCode]) else { return }
                interaction.analysis = analysis
                interaction.preferredInteractionTypes = .automatic
            } catch {
                guard !Task.isCancelled, let self else { return }
                analysisTask = nil
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
    
    func shouldStartAnalysis() -> Bool {
        !hasCompletedAnalysis
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
              liveTextImageView.shouldStartAnalysis() else {
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
