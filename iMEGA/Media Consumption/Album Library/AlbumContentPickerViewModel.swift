import Foundation
import MEGADomain
import Combine

final class AlbumContentPickerViewModel: ObservableObject {
    let locationName: String
   
    private let album: AlbumEntity
    private var photoLibraryUseCase: PhotoLibraryUseCaseProtocol
    private var mediaUseCase: MediaUseCaseProtocol
    private var albumContentModificationUseCase: AlbumContentModificationUseCaseProtocol
    private var completionHandler: (String, AlbumEntity) -> Void
    private var cancellableSink: Cancellable?
    var photosLoadingTask: Task<Void, Never>?
    
    
    @Published var navigationTitle: String = ""
    @Published var isDismiss = false
    @Published var photoLibraryContentViewModel: PhotoLibraryContentViewModel
    
    private var normalNavigationTitle: String {
        "\(Strings.Localizable.CameraUploads.Albums.Create.addItemsTo) \"\(album.name)\""
    }
    
    @MainActor
    init(album: AlbumEntity, locationName: String, photoLibraryUseCase: PhotoLibraryUseCaseProtocol, mediaUseCase: MediaUseCaseProtocol, albumContentModificationUseCase: AlbumContentModificationUseCaseProtocol, completionHandler: @escaping (String, AlbumEntity) -> Void) {
        self.album = album
        self.locationName = locationName
        self.photoLibraryUseCase = photoLibraryUseCase
        self.mediaUseCase = mediaUseCase
        self.albumContentModificationUseCase = albumContentModificationUseCase
        self.completionHandler = completionHandler
        
        photoLibraryContentViewModel = PhotoLibraryContentViewModel(library: PhotoLibrary(), contentMode: PhotoLibraryContentMode.album)
        
        navigationTitle = normalNavigationTitle
        loadPhotos()
        initSubscription()
    }
    
    deinit {
        photosLoadingTask?.cancel()
        cancellableSink = nil
    }
    
    @MainActor
    public func onDone() {
        let nodes: [NodeEntity] = photoLibraryContentViewModel.selection.photos.values.map { $0 }
        guard nodes.isNotEmpty else {
            isDismiss.toggle()
            return
        }
        
        photosLoadingTask = Task(priority: .userInitiated) {
            do {
                let result = try await albumContentModificationUseCase.addPhotosToAlbum(by: album.id, nodes: nodes)
                if result.success > 0 {
                    let successMsg = self.successMessage(forAlbumName: album.name, withNumberOfItmes: result.success)
                    completionHandler(successMsg, album)
                }
            } catch {
                MEGALogError("Error occurred when adding photos to an album. \(error.localizedDescription)")
            }
        }
        
        isDismiss.toggle()
    }
    
    func onFilter() {
    }
    
    func onCancel() {
        isDismiss.toggle()
    }
    
    // MARK: - Private
    private func initSubscription() {
        cancellableSink = photoLibraryContentViewModel.selection.$photos.sink { [weak self] photos in
            guard let self = self else { return }
            self.navigationTitle = photos.isEmpty ? self.normalNavigationTitle : self.navigationTitle(forNumberOfItems: photos.count)
        }
    }
    
    @MainActor
    private func loadPhotos() {
        photosLoadingTask = Task(priority: .userInitiated) {
            do {
                let nodes = try await photoLibraryUseCase.allPhotos()
                    .filter { $0.hasThumbnail() }
                
                photoLibraryContentViewModel.library = nodes.toPhotoLibrary(withSortType: .newest)
                photoLibraryContentViewModel.selection.editMode = .active
            } catch {
                MEGALogError("Error occurred when loading photos. \(error.localizedDescription)")
            }
        }
    }
    
    private func navigationTitle(forNumberOfItems num: Int) -> String {
        num == 1 ? Strings.Localizable.oneItemSelected(1): Strings.Localizable.itemsSelected(num)
    }
    
    private func successMessage(forAlbumName name: String, withNumberOfItmes num: UInt) -> String {
        num == 1 ?
        Strings.Localizable.CameraUploads.Albums.Create.addedOneItemTo.replacingOccurrences(of: "[A]", with: name) :
        Strings.Localizable.CameraUploads.Albums.Create.addedItemsTo.replacingOccurrences(of: "[A]", with: album.name).replacingOccurrences(of: "[X]", with: String(num))
    }
}
