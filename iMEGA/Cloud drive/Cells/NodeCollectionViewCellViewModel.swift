import Combine
import Foundation
import MEGAAppPresentation
import MEGADomain
import MEGASwift

@MainActor
@objc class NodeCollectionViewCellViewModel: NSObject {
    
    @Published private(set) var isSensitive: Bool = false
    @Published private(set) var thumbnail: UIImage?
    @Published private(set) var videoDuration: String?
    
    var hasThumbnail: Bool { node?.hasThumbnail ?? false }
    
    private let node: NodeEntity?
    private let isFromSharedItem: Bool
    private let sensitiveNodeUseCase: any SensitiveNodeUseCaseProtocol
    private let thumbnailUseCase: any ThumbnailUseCaseProtocol
    private let nodeIconUseCase: any NodeIconUsecaseProtocol
    private let remoteFeatureFlagUseCase: any RemoteFeatureFlagUseCaseProtocol
    private var task: Task<Void, Never>?
    private var loadVideoDurationTask: Task<Void, Never>? {
        didSet {
            oldValue?.cancel()
        }
    }
    
    init(node: NodeEntity?,
         isFromSharedItem: Bool,
         sensitiveNodeUseCase: some SensitiveNodeUseCaseProtocol,
         thumbnailUseCase: some ThumbnailUseCaseProtocol,
         nodeIconUseCase: some NodeIconUsecaseProtocol,
         remoteFeatureFlagUseCase: some RemoteFeatureFlagUseCaseProtocol = DIContainer.remoteFeatureFlagUseCase) {
        
        self.node = node
        self.isFromSharedItem = isFromSharedItem
        self.sensitiveNodeUseCase = sensitiveNodeUseCase
        self.thumbnailUseCase = thumbnailUseCase
        self.nodeIconUseCase = nodeIconUseCase
        self.remoteFeatureFlagUseCase = remoteFeatureFlagUseCase
    }
    
    deinit {
        task?.cancel()
        task = nil
        loadVideoDurationTask = nil
    }
    
    @discardableResult
    func configureCell() -> Task<Void, Never> {
        let task = Task { @MainActor [weak self] in
            guard let self, let node else { return }
            await applySensitiveConfiguration(for: node)
            await loadThumbnail(for: node)
        }
        self.task = task
        return task
    }
    
    @objc func isNodeVideo() -> Bool {
        node?.name.fileExtensionGroup.isVideo ?? false
    }
    
    @objc func isNodeVideo(name: String) -> Bool {
        name.fileExtensionGroup.isVideo
    }
    
    @objc func isNodeVideoWithValidDuration() -> Bool {
        guard let node else { return false }
        return isNodeVideo(name: node.name) && node.duration >= 0
    }
    
    func setDurationForVideo(path: String) {
        loadVideoDurationTask = Task { [weak self] in
            let asset = AVURLAsset(url: URL(fileURLWithPath: path, isDirectory: false))
            do {
                let duration = try await asset.load(.duration)
                guard !Task.isCancelled else { return }
                let seconds = CMTimeGetSeconds(duration)
                if seconds > 0, !CMTIME_IS_POSITIVEINFINITY(duration) {
                    self?.videoDuration = seconds.timeString
                } else {
                    self?.videoDuration = nil
                }
            } catch {
                self?.videoDuration = nil
            }
        }
    }
    
    private func loadThumbnail(for node: NodeEntity) async {
                
        guard hasThumbnail else {
            thumbnail = UIImage(data: nodeIconUseCase.iconData(for: node))
            return
        }
        
        do {
            let thumbnailEntity: ThumbnailEntity
            if let cached = thumbnailUseCase.cachedThumbnail(for: node, type: .thumbnail) {
                thumbnailEntity = cached
            } else {
                thumbnail = UIImage(data: nodeIconUseCase.iconData(for: node))
                thumbnailEntity = try await thumbnailUseCase.loadThumbnail(for: node, type: .thumbnail)
            }
            
            let imagePath = thumbnailEntity.url.path()
            
            thumbnail = UIImage(contentsOfFile: imagePath)
        } catch {
            MEGALogError("[\(type(of: self))] Error loading thumbnail: \(error)")
        }
    }
    
    private func applySensitiveConfiguration(for node: NodeEntity) async {
        guard !isFromSharedItem,
              remoteFeatureFlagUseCase.isFeatureFlagEnabled(for: .hiddenNodes),
              sensitiveNodeUseCase.isAccessible() else {
            isSensitive = false
            return
        }
                
        guard !node.isMarkedSensitive else {
            isSensitive = true
            return
        }
        
        do {
            isSensitive = try await sensitiveNodeUseCase.isInheritingSensitivity(node: node)
        } catch {
            MEGALogError("[\(type(of: self))] Error checking if node is inheriting sensitivity: \(error)")
        }
    }
}
