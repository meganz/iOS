import Foundation
import SwiftUI
import Combine

@available(iOS 14.0, *)
final class PhotoCellViewModel: ObservableObject {
    private let photo: NodeEntity
    private let thumbnailUseCase: ThumbnailUseCaseProtocol
    private let placeholderThumbnail: ImageContainer
    private let selection: PhotoSelection
    private var subscriptions = Set<AnyCancellable>()
    
    var duration: String = ""
    var isVideo: Bool
    var currentZoomScaleFactor: Int {
        didSet {
            objectWillChange.send()
            
            // 1 -> 3 or 3 -> 1 needs reload
            if currentZoomScaleFactor == 1 || oldValue == 1 {
                loadThumbnail()
            }
        }
    }
    
    @Published var thumbnailContainer: ImageContainer
    @Published var isSelected: Bool = false {
        didSet {
            if isSelected != oldValue {
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
        subscribeLibraryChange(viewModel: viewModel)
    }
    
    // MARK: Internal
    
    func loadThumbnailIfNeeded() {
        guard thumbnailContainer == placeholderThumbnail else {
            return
        }
        
        loadThumbnail()
    }
    
    // MARK: Private
    
    private func loadThumbnail() {
        let type: ThumbnailTypeEntity = currentZoomScaleFactor == 1 ? .preview : .thumbnail
        
        if let image = thumbnailUseCase.cachedThumbnailImage(for: photo, type: type) {
            thumbnailContainer = ImageContainer(image: image)
        } else {
            if type != .thumbnail, let image = thumbnailUseCase.cachedThumbnailImage(for: photo, type: .thumbnail) {
                thumbnailContainer = ImageContainer(image: image)
            }
            
            DispatchQueue.global(qos: .utility).asyncAfter(deadline: .now() + 0.3) { [weak self] in
                self?.loadThumbnailFromRemote(type: type)
            }
        }
    }
    
    private func loadThumbnailFromRemote(type: ThumbnailTypeEntity) {
        let publisher: AnyPublisher<URL, ThumbnailErrorEntity>
        switch type {
        case .thumbnail:
            publisher = thumbnailUseCase.loadThumbnail(for: photo, type: type).eraseToAnyPublisher()
        case .preview:
            publisher = thumbnailUseCase.loadPreview(for: photo)
        }
        
        publisher
            .delay(for: .seconds(0.3), scheduler: DispatchQueue.global(qos: .userInitiated))
            .map {
                ImageContainer(image: Image(contentsOfFile: $0.path))
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
        viewModel.$zoomState.sink { [weak self] in
            self?.currentZoomScaleFactor = $0.scaleFactor
        }
        .store(in: &subscriptions)
    }
    
    private func subscribeLibraryChange(viewModel: PhotoLibraryAllViewModel) {
        viewModel.libraryViewModel.$library
            .sink { [weak self] in
                if let self = self, let photo = $0.allPhotos.first(where: { $0 == self.photo }), self.isFavorite != photo.isFavourite {
                    self.isFavorite = photo.isFavourite
                }
            }
            .store(in: &subscriptions)
    }
}
