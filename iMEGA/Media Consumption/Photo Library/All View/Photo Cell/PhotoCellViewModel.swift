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
    @MainActor
    private func loadThumbnail() async {
        let type: ThumbnailTypeEntity = currentZoomScaleFactor == 1 ? .preview : .thumbnail
        
        if let image = thumbnailUseCase.cachedThumbnailImage(for: photo, type: type) {
            thumbnailContainer = ImageContainer(image: image)
        } else {
            if type != .thumbnail, let image = thumbnailUseCase.cachedThumbnailImage(for: photo, type: .thumbnail) {
                thumbnailContainer = ImageContainer(image: image)
            }
            
            do {
                try await loadThumbnailFromRemote(type: type)
            } catch {
                MEGALogDebug("[Photo Cell:] \(error) happened when loadThumbnail.")
            }
        }
    }
    
    @MainActor
    private func loadThumbnailFromRemote(type: ThumbnailTypeEntity) async throws {
        if type == .preview {
            do {
                for try await url in thumbnailUseCase.loadPreview(for: photo) {
                    if let image = Image(contentsOfFile: url.path)  {
                        thumbnailContainer = ImageContainer(image: image)
                    }
                }
            } catch {
                MEGALogDebug("[Photo Cell:] \(error) happened when loading preview in loadThumbnailFromRemote.")
            }
        } else {
            do {
                let url = try await thumbnailUseCase.loadThumbnail(for: photo)
                
                if let image = Image(contentsOfFile: url.path) {
                    thumbnailContainer = ImageContainer(image: image)
                }
            } catch {
                MEGALogDebug("[Photo Cell:] \(error) happened when loading thumbnail in loadThumbnailFromRemote.")
            }
        }
    }
    
    private func configSelection() {
        selection
            .$allSelected
            .dropFirst()
            .filter { [weak self] in
                self?.isSelected != $0
            }
            .receive(on: DispatchQueue.main)
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
    
    private func subscribeLibraryChange(viewModel: PhotoLibraryAllViewModel) {
        viewModel
            .libraryViewModel
            .$library
            .receive(on: DispatchQueue.main)
            .sink { [weak self] in
                if let self = self, let photo = $0.allPhotos.first(where: { $0 == self.photo }), self.isFavorite != photo.isFavourite {
                    self.isFavorite = photo.isFavourite
                }
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
                      let updateNode = updatedNodes.filter({ $0.id == self.photo.id }).first else {
                    return
                }
                self.isFavorite = updateNode.isFavourite
            }
            .store(in: &subscriptions)
    }
}
