import Foundation
import SwiftUI
import Combine

@available(iOS 14.0, *)
final class PhotoCellViewModel: ObservableObject {
    private let photo: NodeEntity
    private let thumbnailUseCase: ThumbnailUseCaseProtocol
    private let placeholderThumbnail: ImageContainer
    private let selection: PhotoSelection
    private var cancellable: AnyCancellable?
    private var loadingTask: Task<Void, Never>?
    private var subscriptions = Set<AnyCancellable>()
    
    var duration: String = ""
    var isVideo: Bool
    var currentZoomScaleFactor: Int {
        didSet {
            objectWillChange.send()
            
            // 1 -> 3 or 3 -> 1 needs reload
            if currentZoomScaleFactor == 1 || oldValue == 1 {
                loadingTask = Task {
                    await loadThumbnail()
                }
            }
        }
    }
    
    @Published var thumbnailContainer: ImageContainer
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
         thumbnailUseCase: ThumbnailUseCaseProtocol) {
        self.photo = photo
        self.selection = viewModel.libraryViewModel.selection
        self.thumbnailUseCase = thumbnailUseCase
        currentZoomScaleFactor = viewModel.zoomState.scaleFactor
        
        isVideo = photo.isVideo
        isFavorite = photo.isFavourite
        duration = NSString.mnz_string(fromTimeInterval: Double(photo.duration))
        
        let placeholderFileType = thumbnailUseCase.thumbnailPlaceholderFileType(forNodeName: photo.name)
        placeholderThumbnail = ImageContainer(image: Image(placeholderFileType), isPlaceholder: true)
        thumbnailContainer = placeholderThumbnail
        
        configZoomState(with: viewModel)
        configSelection()
        subscribeToPhotoFavouritesChange()
    }
    
    
    // MARK: Internal
    
    func loadThumbnailIfNeeded() {
        guard thumbnailContainer == placeholderThumbnail else {
            return
        }
        
        loadingTask = Task {
            await loadThumbnail()
        }
    }
    
    func cancelLoading() {
        loadingTask?.cancel()
    }
    
    // MARK: Private
    private func loadThumbnail() async {
        let type: ThumbnailTypeEntity = currentZoomScaleFactor == 1 ? .preview : .thumbnail
        
        switch type {
        case .thumbnail:
            guard let image = try? await thumbnailUseCase.loadThumbnailImage(for: photo, type: .thumbnail) else { return }
            await updateThumbail(image)
        case .preview:
            if let image = thumbnailUseCase.cachedThumbnailImage(for: photo, type: .thumbnail) {
                await updateThumbail(image)
            }
            
            requestPreview()
        }
    }
    
    @MainActor
    private func updateThumbail(_ image: Image) {
        thumbnailContainer = ImageContainer(image: image)
    }
    
    private func requestPreview() {
        thumbnailUseCase
            .requestPreview(for: photo)
            .delay(for: .seconds(0.3), scheduler: DispatchQueue.global(qos: .userInitiated))
            .map {
                MEGALogDebug("[Photos Debug] preview url comes back \(self.photo.id) and url \($0)")
                return ImageContainer(image: Image(contentsOfFile: $0.path))
            }
            .replaceError(with: nil)
            .compactMap { $0 }
            .filter { [weak self] in
                $0 != self?.thumbnailContainer
            }
            .receive(on: DispatchQueue.main)
            .assign(to: &$thumbnailContainer)
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
            .receive(on: DispatchQueue.main)
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
