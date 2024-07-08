import AsyncAlgorithms
import Combine
import Foundation
import MEGADomain
import MEGAPresentation
import MEGASwift
import MEGASwiftUI
import SwiftUI

class PhotoCardViewModel: ObservableObject {
    private let coverPhoto: NodeEntity?
    private let thumbnailLoader: any ThumbnailLoaderProtocol
    private let nodeUseCase: any NodeUseCaseProtocol
    private let featureFlagProvider: any FeatureFlagProviderProtocol
    
    @Published var thumbnailContainer: any ImageContaining
    
    init(coverPhoto: NodeEntity?,
         thumbnailLoader: some ThumbnailLoaderProtocol,
         nodeUseCase: some NodeUseCaseProtocol,
         featureFlagProvider: some FeatureFlagProviderProtocol = DIContainer.featureFlagProvider) {
        self.coverPhoto = coverPhoto
        self.thumbnailLoader = thumbnailLoader
        self.nodeUseCase = nodeUseCase
        self.featureFlagProvider = featureFlagProvider
        
        thumbnailContainer = if let photo = coverPhoto {
            thumbnailLoader.initialImage(
                for: photo,
                type: .preview,
                placeholder: { Image(.photoCardPlaceholder) })
        } else {
            ImageContainer(
                image: Image(.photoCardPlaceholder),
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
        
    @MainActor
    func monitorInheritedSensitivityChanges() async {
        guard featureFlagProvider.isFeatureFlagEnabled(for: .hiddenNodes),
              let coverPhoto,
              !coverPhoto.isMarkedSensitive,
              await $thumbnailContainer.values.contains(where: { $0.type != .placeholder }) else {
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
    
    /// Monitor photo node and inherited sensitivity changes
    /// - Important: This is only required for iOS 15 since the photo library is using the `PhotoScrollPosition` as an `id` see `PhotoLibraryModeAllGridView`
    @MainActor
    func monitorPhotoSensitivityChanges() async {
        guard
            featureFlagProvider.isFeatureFlagEnabled(for: .hiddenNodes),
            let coverPhoto else {
            return
        }
        // Don't monitor node sensitivity changes if the thumbnail is placeholder. This will wait infinitely if the thumbnail is placeholder
        _ = await $thumbnailContainer.values.contains(where: { $0.type != .placeholder })
        
        do {
            for try await isSensitive in photoSensitivityChanges(for: coverPhoto) {
                await updateThumbnailContainerIfNeeded(thumbnailContainer.toSensitiveImageContaining(isSensitive: isSensitive))
            }
        } catch {
            MEGALogError("[\(type(of: self))] failed to retrieve inherited sensitivity for photo: \(error.localizedDescription)")
        }
    }
    
    // MARK: - Private
    private func updateThumbnailContainerIfNeeded(_ container: any ImageContaining) async {
        guard !isShowingThumbnail(container) else { return }
        await updateThumbnailContainer(container)
    }
    
    @MainActor
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
        nodeUseCase
            .monitorInheritedSensitivity(for: photo)
            .prepend { [weak self] in
                try await self?.nodeUseCase.isInheritingSensitivity(node: photo) ?? false
            }
            .eraseToAnyAsyncThrowingSequence()
    }
    
    /// Async sequence will yield photo sensitivity and inherited sensitivity changes. It will immediately yield the current photo sensitivity if true otherwise the  inherited sensitivity since it could have changed since thumbnail loaded
    /// - Parameters:
    ///   - photo: Photo NodeEntity to monitor
    private func photoSensitivityChanges(for photo: NodeEntity) -> AnyAsyncThrowingSequence<Bool, any Error> {

        // Need to fetch the latest version of the node.
        // This is a architecture bug with the SwiftUI version iOS 15 and below
        // The NodeEntity does not update in this model, due to the way the SwiftUI view has been built
        // If used in iOS16 +, this is not an issue as this VM gets recreated on reloads and scrolling away
        let node = nodeUseCase.nodeForHandle(photo.handle) ?? photo
            
        return combineLatest(
            nodeUseCase.sensitivityChanges(for: node).prepend(node.isMarkedSensitive),
            monitorInheritedSensitivity(for: node)
        )
        .map { isPhotoSensitive, isInheritingSensitive in
            if isPhotoSensitive {
                true
            } else {
                isInheritingSensitive
            }
        }
        .removeDuplicates()
        .eraseToAnyAsyncThrowingSequence()
    }
}
