import Foundation
import SwiftUI
import Combine

@available(iOS 14.0, *)
final class PhotoCellViewModel: ObservableObject {
    private let photo: NodeEntity
    private let thumbnailUseCase: ThumbnailUseCaseProtocol
    private let placeholderThumbnail: ImageContainer
    private let selection: PhotoSelection
    
    @Published var thumbnailContainer: ImageContainer
    
    @Published var isSelected: Bool = false {
        didSet {
            if isSelected != oldValue {
                selection.photos[photo.handle] = isSelected ? photo : nil
            }
        }
    }
    
    @Published var editMode: EditMode = .inactive
    
    init(photo: NodeEntity,
         selection: PhotoSelection,
         thumbnailUseCase: ThumbnailUseCaseProtocol) {
        self.photo = photo
        self.selection = selection
        self.thumbnailUseCase = thumbnailUseCase
        
        let placeholderFileType = thumbnailUseCase.thumbnailPlaceholderFileType(forNodeName: photo.name)
        placeholderThumbnail = ImageContainer(image: Image(placeholderFileType), isPlaceholder: true)
        thumbnailContainer = placeholderThumbnail
        
        configSelection()
    }
    
    // MARK: Internal
    
    func loadThumbnail() {
        guard thumbnailContainer == placeholderThumbnail else {
            return
        }
        
        let cachedThumbnailPath = thumbnailUseCase.cachedThumbnail(for: photo).path
        if let image = Image(contentsOfFile: cachedThumbnailPath) {
            thumbnailContainer = ImageContainer(image: image, overlay: photo.overlay)
        } else {
            DispatchQueue.global(qos: .utility).asyncAfter(deadline: .now() + 0.3) {
                self.loadThumbnailFromRemote()
            }
        }
    }
    
    // MARK: Private
    
    private func loadThumbnailFromRemote() {
        thumbnailUseCase
            .loadThumbnail(for: photo)
            .delay(for: .seconds(0.3), scheduler: DispatchQueue.global(qos: .userInitiated))
            .map { [weak self] in
                ImageContainer(image: Image(contentsOfFile: $0.path), overlay: self?.photo.overlay)
            }
            .replaceError(with: nil)
            .compactMap { $0 }
            .receive(on: DispatchQueue.main)
            .assign(to: &$thumbnailContainer)
    }
    
    private func configSelection() {
        selection
            .$editMode
            .filter { [weak self] in
                self?.editMode != $0
            }
            .assign(to: &$editMode)
        
        selection
            .$allSelected
            .filter { [weak self] _ in
                self?.editMode.isEditing == true
            }
            .assign(to: &$isSelected)
        
        if editMode.isEditing {
            isSelected = selection.isPhotoSelected(photo)
        }
    }
}
