import AsyncAlgorithms
@preconcurrency import Combine
import Foundation
import MEGAAppPresentation
import MEGAAssets
import MEGADomain
import MEGASwift
import MEGASwiftUI
import SwiftUI

@MainActor
public class PhotoCardViewModel: ObservableObject {
    private let coverPhoto: NodeEntity?
    private let thumbnailLoader: any ThumbnailLoaderProtocol
    private let sensitiveNodeUseCase: any SensitiveNodeUseCaseProtocol
    private let remoteFeatureFlagUseCase: any RemoteFeatureFlagUseCaseProtocol
    
    @Published var thumbnailContainer: any ImageContaining
    
    init(coverPhoto: NodeEntity?,
         thumbnailLoader: some ThumbnailLoaderProtocol,
         sensitiveNodeUseCase: some SensitiveNodeUseCaseProtocol,
         remoteFeatureFlagUseCase: some RemoteFeatureFlagUseCaseProtocol = DIContainer.remoteFeatureFlagUseCase) {
        self.coverPhoto = coverPhoto
        self.thumbnailLoader = thumbnailLoader
        self.sensitiveNodeUseCase = sensitiveNodeUseCase
        self.remoteFeatureFlagUseCase = remoteFeatureFlagUseCase
        
        thumbnailContainer = if let photo = coverPhoto {
            thumbnailLoader.initialImage(
                for: photo,
                type: .preview,
                placeholder: { MEGAAssets.Image.photoCardPlaceholder })
        } else {
            ImageContainer(
                image: MEGAAssets.Image.photoCardPlaceholder,
                type: .placeholder)
        }
    }
    
    func loadThumbnail() async {
        guard let photo = coverPhoto,
              thumbnailContainer.type == .placeholder else {
            return
        }
        do {
            for await imageContainer in try await thumbnailLoader.loadImage(for: photo, type: .preview) {
                await updateThumbnailContainerIfNeeded(imageContainer)
            }
        } catch is CancellationError {
            MEGALogDebug("[PhotoCardViewModel] Cancelled loading thumbnail for \(photo.handle)")
        } catch {
            MEGALogError("[PhotoCardViewModel] failed to load preview: \(error)")
        }
    }
        
    func monitorInheritedSensitivityChanges() async {
        guard let coverPhoto,
              !coverPhoto.isMarkedSensitive,
              await $thumbnailContainer.values.contains(where: { @Sendable in $0.type != .placeholder }) else {
            return
        }
        
        do {
            for try await isInheritingSensitivity in monitorInheritedSensitivity(for: coverPhoto) {
                await updateThumbnailContainerIfNeeded(thumbnailContainer.toSensitiveImageContaining(isSensitive: isInheritingSensitivity))
            }
        } catch {
            MEGALogError("[\(type(of: self))] failed to retrieve inherited sensitivity for photo: \(error.localizedDescription)")
        }
    }
    
    // MARK: - Private
    private func updateThumbnailContainerIfNeeded(_ container: any ImageContaining) async {
        guard !isShowingThumbnail(container) else { return }
        updateThumbnailContainer(container)
    }
    
    private func updateThumbnailContainer(_ container: any ImageContaining) {
        thumbnailContainer = container
    }
    
    private func isShowingThumbnail(_ container: some ImageContaining) -> Bool {
        thumbnailContainer.isEqual(container)
    }
    
    /// Async sequence will yield inherited sensitivity changes. It will immediately yield the current inherited sensitivity since it could have changed since thumbnail loaded
    /// - Parameters:
    ///   - photo: Photo NodeEntity to monitor
    private func monitorInheritedSensitivity(for photo: NodeEntity) -> AnyAsyncThrowingSequence<Bool, any Error> {
        sensitiveNodeUseCase
            .monitorInheritedSensitivity(for: photo)
            .prepend { [weak self] in
                try await self?.sensitiveNodeUseCase.isInheritingSensitivity(node: photo) ?? false
            }
            .eraseToAnyAsyncThrowingSequence()
    }
}
