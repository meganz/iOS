import Foundation
import SwiftUI
import Combine
import MEGASwiftUI
import MEGADomain
import MEGASwift

class PhotoCellViewModel: ObservableObject {
    private let photo: NodeEntity
    private let thumbnailUseCase: ThumbnailUseCaseProtocol
    private let mediaUseCase: MediaUseCaseProtocol
    private let selection: PhotoSelection
    private var subscriptions = Set<AnyCancellable>()
    
    var thumbnailLoadingTask: Task<Void, Never>?
    var duration: String
    var isVideo: Bool
    
    @Published var currentZoomScaleFactor: PhotoLibraryZoomState.ScaleFactor {
        didSet {
            if currentZoomScaleFactor == .one || oldValue == .one {
                startLoadingThumbnail()
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
    @Published var editMode: EditMode = .inactive
    @Published private(set) var isSelectionLimitReached: Bool = false
    
    var shouldShowEditState: Bool {
        editMode.isEditing && currentZoomScaleFactor != .thirteen
    }
    
    var shouldShowFavorite: Bool {
        isFavorite && currentZoomScaleFactor != .thirteen
    }
    
    var shouldApplyContentOpacity: Bool {
        editMode.isEditing && isSelectionLimitReached && !isSelected
    }
    
    init(photo: NodeEntity,
         viewModel: PhotoLibraryModeAllViewModel,
         thumbnailUseCase: ThumbnailUseCaseProtocol,
         mediaUseCase: MediaUseCaseProtocol) {
        self.photo = photo
        self.selection = viewModel.libraryViewModel.selection
        self.thumbnailUseCase = thumbnailUseCase
        self.mediaUseCase = mediaUseCase
        currentZoomScaleFactor = viewModel.zoomState.scaleFactor
        
        isVideo = mediaUseCase.isVideo(for: URL(fileURLWithPath: photo.name))
        isFavorite = photo.isFavourite
        duration = TimeInterval(photo.duration).timeString
        
        let type: ThumbnailTypeEntity = viewModel.zoomState.scaleFactor == .one ? .preview : .thumbnail
        if let container = thumbnailUseCase.cachedThumbnailContainer(for: photo, type: type) {
            thumbnailContainer = container
        } else {
            let placeholderFileType = FileTypes().fileType(forFileName: photo.name)
            let placeholder = ImageContainer(image: Image(placeholderFileType), type: .placeholder)
            thumbnailContainer = placeholder
        }
        
        configZoomState(with: viewModel)
        configSelection()
        subscribeToPhotoFavouritesChange()
        self.selection.$editMode.assign(to: &$editMode)
    }
    
    // MARK: Internal
    func startLoadingThumbnail() {
        if currentZoomScaleFactor == .one && thumbnailContainer.type == .preview {
            return
        } else if currentZoomScaleFactor != .one && thumbnailContainer.type == .thumbnail {
            return
        } else {
            thumbnailLoadingTask = Task {
                await loadThumbnail()
            }
        }
    }
    
    func cancelLoadingThumbnail() {
        thumbnailLoadingTask?.cancel()
    }
    
    func select() {
        if editMode.isEditing && (isSelected || !isSelectionLimitReached) {
            isSelected.toggle()
        } else {
            selection.isItemSelectedAfterLimitReached = true
        }
    }
    
    // MARK: Private
    private func loadThumbnail() async {
        let type: ThumbnailTypeEntity = currentZoomScaleFactor == .one ? .preview : .thumbnail
        switch type {
        case .thumbnail:
            if let container = thumbnailUseCase.cachedThumbnailContainer(for: photo, type: .thumbnail) {
                await updateThumbailContainerIfNeeded(container)
            } else if let container = try? await thumbnailUseCase.loadThumbnailContainer(for: photo, type: .thumbnail) {
                await updateThumbailContainerIfNeeded(container)
            }
        case .preview, .original:
            if let container = thumbnailUseCase.cachedThumbnailContainer(for: photo, type: .preview) {
                await updateThumbailContainerIfNeeded(container)
            } else {
                if let container = thumbnailUseCase.cachedThumbnailContainer(for: photo, type: .thumbnail) {
                    await updateThumbailContainerIfNeeded(container)
                }
                
                requestPreview()
            }
        }
    }
    
    private func updateThumbailContainerIfNeeded(_ container: any ImageContaining) async {
        guard !isShowingThumbnail(container) else { return }
        await updateThumbailContainer(container)
    }
    
    @MainActor
    private func updateThumbailContainer(_ container: any ImageContaining) {
        thumbnailContainer = container
    }
    
    private func requestPreview() {
        thumbnailUseCase
            .requestPreview(for: photo)
            .map {
                $0.toURLImageContainer()
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
        
        if let isSelectionLimitReachedPublisher = selection.isSelectionLimitReachedPublisher {
            isSelectionLimitReachedPublisher
                .assign(to: &$isSelectionLimitReached)
        }
    }
    
    private func configZoomState(with viewModel: PhotoLibraryModeAllViewModel) {
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
