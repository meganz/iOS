@preconcurrency import Combine
import MEGADomain
import MEGAPresentation
import MEGASwift
import SwiftUI

@MainActor
final class VideoCellViewModel: ObservableObject {
    
    /// Represents the different display modes for a cell view.
    enum Mode {
        /// Plain mode: Displays rows in the default style without any additional editing indicators.
        case plain
        
        /// Selection mode: Displays a checkmark indicator on the rows, allowing the user to select multiple items.
        case selection
        
        /// Reorder mode: Shows a grabber icon on the rows, allowing the user to drag and reorder items.
        case reorder
    }
    
    enum ViewContext: Equatable {
        case allVideos
        case playlistContent(type: VideoPlaylistEntityType)
    }
    
    private let thumbnailLoader: any ThumbnailLoaderProtocol
    private let sensitiveNodeUseCase: any SensitiveNodeUseCaseProtocol
    private let nodeUseCase: any NodeUseCaseProtocol
    private let remoteFeatureFlagUseCase: any RemoteFeatureFlagUseCaseProtocol
    private let featureFlagProvider: any FeatureFlagProviderProtocol
    private(set) var nodeEntity: NodeEntity
    private let onTapMoreOptions: (_ node: NodeEntity) -> Void
    private let onTapped: (_ node: NodeEntity) -> Void
    
    @Published var previewEntity: VideoCellPreviewEntity
    @Published var isSelected = false
    
    @Published var mode: VideoCellViewModel.Mode
    private(set) var viewContext: VideoCellViewModel.ViewContext
    
    var reorderVideosInVideoPlaylistContentEnabled: Bool {
        featureFlagProvider.isFeatureFlagEnabled(for: .reorderVideosInVideoPlaylistContent)
    }
    
    init(
        mode: VideoCellViewModel.Mode,
        viewContext: VideoCellViewModel.ViewContext,
        nodeEntity: NodeEntity,
        thumbnailLoader: some ThumbnailLoaderProtocol,
        sensitiveNodeUseCase: some SensitiveNodeUseCaseProtocol,
        nodeUseCase: some NodeUseCaseProtocol,
        remoteFeatureFlagUseCase: some RemoteFeatureFlagUseCaseProtocol = DIContainer.remoteFeatureFlagUseCase,
        featureFlagProvider: some FeatureFlagProviderProtocol,
        onTapMoreOptions: @escaping (_ node: NodeEntity) -> Void,
        onTapped: @escaping (_ node: NodeEntity) -> Void
    ) {
        self.mode = mode
        self.viewContext = viewContext
        self.nodeEntity = nodeEntity
        self.thumbnailLoader = thumbnailLoader
        self.sensitiveNodeUseCase = sensitiveNodeUseCase
        self.nodeUseCase = nodeUseCase
        self.remoteFeatureFlagUseCase = remoteFeatureFlagUseCase
        self.featureFlagProvider = featureFlagProvider
        self.onTapMoreOptions = onTapMoreOptions
        self.onTapped = onTapped
        
        let placeholder = Image(systemName: "square.fill")
        
        let cachedContainer = thumbnailLoader.initialImage(for: nodeEntity, type: .thumbnail, placeholder: { placeholder })
        
        previewEntity = nodeEntity.toVideoCellPreviewEntity(thumbnailContainer: cachedContainer, isDownloaded: false)
    }
    
    func attemptLoadThumbnail() async throws {
        
        guard let container: any ImageContaining = try await thumbnailLoader.loadImage(for: nodeEntity, type: .thumbnail) else {
            return
        }
        
        await updateThumbnailContainerIfNeeded(container)
    }
    
    func monitorInheritedSensitivityChanges() async {
        guard
            remoteFeatureFlagUseCase.isFeatureFlagEnabled(for: .hiddenNodes),
            !nodeEntity.isMarkedSensitive,
            await $previewEntity.values.contains(where: { @Sendable in $0.imageContainer.type != .placeholder }) else { return }
        
        do {
            for try await isInheritingSensitivity in monitorInheritedSensitivity(for: nodeEntity, sensitiveNodeUseCase: sensitiveNodeUseCase) {
                await updateThumbnailContainerIfNeeded(previewEntity.imageContainer.toSensitiveImageContaining(isSensitive: isInheritingSensitivity))
            }
        } catch {
            print("[\(type(of: self))] failed to retrieve inherited sensitivity for node: \(error.localizedDescription)")
        }
    }
    
    func onTappedMoreOptions() {
        onTapMoreOptions(nodeEntity)
    }
        
    private func updateThumbnailContainerIfNeeded(_ container: any ImageContaining) async {
        guard !previewEntity.imageContainer.isEqual(container) else { return }
        previewEntity = nodeEntity.toVideoCellPreviewEntity(thumbnailContainer: container, isDownloaded: nodeUseCase.isDownloaded(nodeHandle: nodeEntity.handle))
    }
    
    /// Async sequence will yield inherited sensitivity changes. It will immediately yield the current inherited sensitivity since it could have changed since thumbnail loaded
    /// - Parameters:
    ///   - video: Video NodeEntity to monitor
    private func monitorInheritedSensitivity(for video: NodeEntity, sensitiveNodeUseCase: some SensitiveNodeUseCaseProtocol) -> AnyAsyncThrowingSequence<Bool, any Error> {
        sensitiveNodeUseCase
            .monitorInheritedSensitivity(for: video)
            .prepend { try await sensitiveNodeUseCase.isInheritingSensitivity(node: video) }
            .eraseToAnyAsyncThrowingSequence()
    }
    
    func onCellTapped() {
        onTapped(nodeEntity)
    }
}
