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
    
    var currentZoomScaleFactor: Int {
        didSet {
            // 1 -> 3 or 3 -> 1 needs reload
            if currentZoomScaleFactor == 1 || oldValue == 1 {
                objectWillChange.send()
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
    
    init(photo: NodeEntity,
         viewModel: PhotoLibraryAllViewModel,
         thumbnailUseCase: ThumbnailUseCaseProtocol) {
        self.photo = photo
        self.selection = viewModel.libraryViewModel.selection
        self.thumbnailUseCase = thumbnailUseCase
        currentZoomScaleFactor = viewModel.zoomState.scaleFactor
        
        let placeholderFileType = thumbnailUseCase.thumbnailPlaceholderFileType(forNodeName: photo.name)
        placeholderThumbnail = ImageContainer(image: Image(placeholderFileType), isPlaceholder: true)
        thumbnailContainer = placeholderThumbnail
        
        configZoomState(with: viewModel)
        configSelection()
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
            thumbnailContainer = ImageContainer(image: image, overlay: photo.overlay)
        } else {
            if type != .thumbnail, let image = thumbnailUseCase.cachedThumbnailImage(for: photo, type: .thumbnail) {
                thumbnailContainer = ImageContainer(image: image, overlay: photo.overlay)
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
            .map { [weak self] in
                ImageContainer(image: Image(contentsOfFile: $0.path), overlay: self?.photo.overlay)
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
        cancellable = viewModel.$zoomState.sink { [weak self] in
            self?.currentZoomScaleFactor = $0.scaleFactor
        }
    }
}
