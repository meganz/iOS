import Foundation
import MEGADomain
import Combine

final class AlbumContentPickerViewModel: ObservableObject {
   
    private let album: AlbumEntity
    private let photoLibraryUseCase: PhotoLibraryUseCaseProtocol
    private let mediaUseCase: MediaUseCaseProtocol
    private let albumContentModificationUseCase: AlbumContentModificationUseCaseProtocol
    private let completion: (String, AlbumEntity) -> Void
    private var subscriptions = Set<AnyCancellable>()
    var photosLoadingTask: Task<Void, Never>?
    
    @Published var photoSourceLocation: PhotosFilterLocation = .allLocations
    @Published var navigationTitle: String = ""
    @Published var isDismiss = false
    @Published var photoLibraryContentViewModel: PhotoLibraryContentViewModel
    
    private var normalNavigationTitle: String {
        Strings.Localizable.CameraUploads.Albums.Create.addItemsTo("\"\(album.name)\"")
    }
    
    @MainActor
    init(album: AlbumEntity,
         photoLibraryUseCase: PhotoLibraryUseCaseProtocol,
         mediaUseCase: MediaUseCaseProtocol,
         albumContentModificationUseCase: AlbumContentModificationUseCaseProtocol,
         completion: @escaping (String, AlbumEntity) -> Void) {
        self.album = album
        self.photoLibraryUseCase = photoLibraryUseCase
        self.mediaUseCase = mediaUseCase
        self.albumContentModificationUseCase = albumContentModificationUseCase
        self.completion = completion
        photoLibraryContentViewModel = PhotoLibraryContentViewModel(library: PhotoLibrary(),
                                                                    contentMode: .album)
        navigationTitle = normalNavigationTitle
        setupSubscriptions()
    }
    
    deinit {
        photosLoadingTask?.cancel()
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
                    completion(successMsg, album)
                }
            } catch {
                MEGALogError("Error occurred when adding photos to an album. \(error.localizedDescription)")
            }
        }
        
        isDismiss.toggle()
    }
    
    func onFilter() {
        photoLibraryContentViewModel.showFilter.toggle()
    }
    
    func onCancel() {
        isDismiss.toggle()
    }
    
    // MARK: - Private
    private func setupSubscriptions() {
        photoLibraryContentViewModel.selection.$photos
            .compactMap { [weak self] photos in
                guard let self = self else { return nil }
                return photos.isEmpty ? self.normalNavigationTitle : self.navigationTitle(forNumberOfItems: photos.count)
            }
            .receive(on: DispatchQueue.main)
            .assign(to: &$navigationTitle)
        
        photoLibraryContentViewModel.filterViewModel.$appliedFilterLocation
            .dropFirst()
            .receive(on: DispatchQueue.main)
            .assign(to: &$photoSourceLocation)
        
        $photoSourceLocation
            .removeDuplicates()
            .sink { [weak self] _ in
                self?.loadPhotos()
            }
            .store(in: &subscriptions)
    }
    
    private func loadPhotos() {
        photosLoadingTask = Task(priority: .userInitiated) {
            do {
                let nodes = try await nodes(forPhotoLocation: photoSourceLocation)
                    .filter { $0.hasThumbnail }
                await updatePhotoLibraryContent(nodes: nodes)
            } catch {
                MEGALogError("Error occurred when loading photos. \(error.localizedDescription)")
            }
        }
    }
    
    @MainActor
    private func updatePhotoLibraryContent(nodes: [NodeEntity]) {
        photoLibraryContentViewModel.library = nodes.toPhotoLibrary(withSortType: .newest)
        photoLibraryContentViewModel.selection.editMode = .active
    }
    
    private func nodes(forPhotoLocation location: PhotosFilterLocation) async throws -> [NodeEntity] {
            switch location {
            case .allLocations:
                return try await photoLibraryUseCase.allPhotos()
            case .cloudDrive:
                return try await photoLibraryUseCase.allPhotosFromCloudDriveOnly()
            case .cameraUploads:
                return try await photoLibraryUseCase.allPhotosFromCameraUpload()
            }
        }
    
    private func navigationTitle(forNumberOfItems num: Int) -> String {
        num == 1 ? Strings.Localizable.oneItemSelected(1): Strings.Localizable.itemsSelected(num)
    }
    
    private func successMessage(forAlbumName name: String, withNumberOfItmes num: UInt) -> String {
        Strings.Localizable.CameraUploads.Albums.addedItemTo(Int(num)).replacingOccurrences(of: "[A]", with: "\(name)")
    }
}
