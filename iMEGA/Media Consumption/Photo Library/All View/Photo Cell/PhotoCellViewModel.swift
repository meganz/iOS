import Foundation
import SwiftUI
import Combine
import MEGASwiftUI
import MEGADomain
import MEGASwift

@available(iOS 14.0, *)
final class PhotoCellViewModel: ObservableObject {
    private let photo: NodeEntity
    private let thumbnailUseCase: ThumbnailUseCaseProtocol
    private let mediaUseCase: MediaUseCaseProtocol
    private let placeholderThumbnail: ImageContainer
    private let selection: PhotoSelection
    private var subscriptions = Set<AnyCancellable>()
    
    var thumbnailLoadingTask: Task<Void, Never>?
    var duration: String
    var isVideo: Bool
    
    @Published var currentZoomScaleFactor: Int {
        didSet {
            // 1 -> 3 or 3 -> 1 needs reload
            if currentZoomScaleFactor == 1 || oldValue == 1 {
                thumbnailLoadingTask = Task {
                    await loadThumbnail()
                }
            }
        }
    }
    
    @Published var thumbnailContainer: any ImageContaining
    @Published var isSelected: Bool = false {
        didSet {
            if isSelected != oldValue && selection.isPhotoSelected(photo) != isSelected {
                selection.photos[photo.handle] = isSelected ? photo : nil
            }
        }
    }
    
    @Published var isFavorite: Bool = false
    
    init(photo: NodeEntity,
         viewModel: PhotoLibraryAllViewModel,
         thumbnailUseCase: ThumbnailUseCaseProtocol,
         mediaUseCase: MediaUseCaseProtocol = MediaUseCase()) {
        self.photo = photo
        self.selection = viewModel.libraryViewModel.selection
        self.thumbnailUseCase = thumbnailUseCase
        self.mediaUseCase = mediaUseCase
        currentZoomScaleFactor = viewModel.zoomState.scaleFactor
        
        isVideo = mediaUseCase.isVideo(for: URL(fileURLWithPath: photo.name))
        isFavorite = photo.isFavourite
        duration = NSString.mnz_string(fromTimeInterval: Double(photo.duration))
        
        let placeholderFileType = FileTypes().fileType(forFileName: photo.name)
        placeholderThumbnail = ImageContainer(image: Image(placeholderFileType), isPlaceholder: true)
        thumbnailContainer = placeholderThumbnail
        
        configZoomState(with: viewModel)
        configSelection()
        subscribeToPhotoFavouritesChange()
    }
    
    
    // MARK: Internal
    
    func loadThumbnailIfNeeded() {
        guard isShowingThumbnail(placeholderThumbnail) else {
            return
        }
        
        thumbnailLoadingTask = Task {
            await loadThumbnail()
        }
    }
    
    func cancelLoading() {
        thumbnailLoadingTask?.cancel()
    }
    
    // MARK: Private
    private func loadThumbnail() async {
        let type: ThumbnailTypeEntity = currentZoomScaleFactor == 1 ? .preview : .thumbnail
        
        switch type {
        case .thumbnail:
            guard let container = try? await thumbnailUseCase.loadThumbnailImageContainer(for: photo, type: .thumbnail) else { return }
            await updateThumbailContainer(container)
        case .preview, .original:
            if let container = thumbnailUseCase.cachedThumbnailImageContainer(for: photo, type: .thumbnail) {
                await updateThumbailContainer(container)
            }
            
            requestPreview()
        }
    }
    
    @MainActor
    private func updateThumbailContainer(_ container: any ImageContaining) {
        thumbnailContainer = container
    }
    
    private func requestPreview() {
        thumbnailUseCase
            .requestPreview(for: photo)
            .map {
                URLImageContainer(imageURL: $0)
            }
            .replaceError(with: nil)
            .compactMap { $0 }
            .filter { [weak self] in
                self?.isShowingThumbnail($0) == false
            }
            .receive(on: DispatchQueue.main)
            .assign(to: &$thumbnailContainer)
    }
    
    private func isShowingThumbnail(_ container: some ImageContaining) -> Bool {
        thumbnailContainer.isEqual(container)
    }
    
    private func configSelection() {
        selection
            .$allSelected
            .dropFirst()
            .filter { [weak self] in
                self?.isSelected != $0
            }
            .assign(to: &$isSelected)
        
        if selection.editMode.isEditing {
            isSelected = selection.isPhotoSelected(photo)
        }
    }
    
    private func configZoomState(with viewModel: PhotoLibraryAllViewModel) {
        viewModel
            .$zoomState
            .dropFirst()
            .sink { [weak self] in
                self?.currentZoomScaleFactor = $0.scaleFactor
            }
            .store(in: &subscriptions)
    }
    
    private func subscribeToPhotoFavouritesChange() {
        NotificationCenter.default
            .publisher(for: .didPhotoFavouritesChange)
            .compactMap{$0.object as? [NodeEntity]}
            .receive(on: DispatchQueue.main)
            .sink { [weak self] updatedNodes in
                guard let self = self,
                      let updateNode = updatedNodes.first(where: { $0 == self.photo }) else {
                    return
                }
                self.isFavorite = updateNode.isFavourite
            }
            .store(in: &subscriptions)
    }
}
