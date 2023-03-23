import Combine
import SwiftUI
import MEGASwiftUI
import MEGADomain

final class AlbumCellViewModel: ObservableObject {
    @Published var numberOfNodes: Int = 0
    @Published var thumbnailContainer: any ImageContaining
    @Published var isLoading: Bool = false
    @Published var title: String = ""
    @Published var isSelected: Bool = false {
        didSet {
            if isSelected != oldValue && selection.isAlbumSelected(album) != isSelected {
                selection.albums[album.id] = isSelected ? album : nil
            }
        }
    }

    @Published var editMode: EditMode = .inactive {
        willSet {
            opacity = newValue.isEditing && album.systemAlbum ? 0.5 : 1.0
            shouldShowEditStateOpacity = newValue.isEditing && !album.systemAlbum ? 1.0 : 0.0
        }
    }
    
    @Published var shouldShowEditStateOpacity: Double = 0.0
    @Published var opacity: Double = 1.0
    
    let album: AlbumEntity
    private let thumbnailUseCase: ThumbnailUseCaseProtocol
    
    private var loadingTask: Task<Void, Never>?
    
    let selection: AlbumSelection
    
    private var subscriptions = Set<AnyCancellable>()
    
    private var isEditing: Bool {
        selection.editMode.isEditing
    }
    
    init(
        thumbnailUseCase: ThumbnailUseCaseProtocol,
        album: AlbumEntity,
        selection: AlbumSelection
    ) {
        self.thumbnailUseCase = thumbnailUseCase
        self.album = album
        self.selection = selection
        
        title = album.name
        numberOfNodes = album.count
        
        if let coverNode = album.coverNode,
           let container = thumbnailUseCase.cachedThumbnailContainer(for: coverNode, type: .thumbnail) {
            thumbnailContainer = container
        } else {
            thumbnailContainer = ImageContainer(image: Image(Asset.Images.Album.placeholder.name), type: .placeholder)
        }
        
        configSelection()
        subscribeToEditMode()
    }
    
    func loadAlbumThumbnail() {
        guard let coverNode = album.coverNode,
              thumbnailContainer.type == .placeholder else {
            return
        }
        if !isLoading {
            isLoading.toggle()
        }
        loadingTask = Task {
            await loadThumbnail(for: coverNode)
        }
    }
    
    func cancelLoading() {
        isLoading = false
        loadingTask?.cancel()
    }
    
    func onAlbumTap() {
        guard !album.systemAlbum else { return }
        isSelected.toggle()
    }
    
    // MARK: Private
    
    @MainActor
    private func loadThumbnail(for node: NodeEntity) async {
        guard let imageContainer = try? await thumbnailUseCase.loadThumbnailContainer(for: node, type: .thumbnail) else {
            isLoading = false
            return
        }
        
        thumbnailContainer = imageContainer
        isLoading = false
    }
    
    private func configSelection() {
        selection
            .$allSelected
            .dropFirst()
            .filter { [weak self] in
                self?.isSelected != $0
            }
            .assign(to: &$isSelected)
    }
    
    private func subscribeToEditMode() {
        selection.$editMode
            .receive(on: DispatchQueue.main)
            .sink { [weak self] in
                self?.editMode = $0
            }
            .store(in: &subscriptions)
    }
}
