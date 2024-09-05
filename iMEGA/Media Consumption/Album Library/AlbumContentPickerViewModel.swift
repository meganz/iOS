import Combine
import Foundation
import MEGADomain
import MEGAL10n

@MainActor
final class AlbumContentPickerViewModel: ObservableObject {
   
    private let album: AlbumEntity
    private let photoLibraryUseCase: any PhotoLibraryUseCaseProtocol
    private let completion: (AlbumEntity, [NodeEntity]) -> Void
    private var subscriptions = Set<AnyCancellable>()
    var photosLoadingTask: Task<Void, Never>?
    
    let selectLimit: Int
    @Published private(set) var photoSourceLocation: PhotosFilterLocation = .allLocations
    @Published var navigationTitle: String = ""
    @Published var photoSourceLocationNavigationTitle: String = ""
    @Published var shouldDismiss = false
    @Published var photoLibraryContentViewModel: PhotoLibraryContentViewModel
    @Published var shouldRemoveFilter = true
    @Published var isDoneButtonDisabled = true
    @Published var showSelectionLimitReachedAlert = true
    
    private var normalNavigationTitle: String {
        Strings.Localizable.CameraUploads.Albums.Create.addItemsTo(album.name)
    }
    
    init(album: AlbumEntity,
         photoLibraryUseCase: any PhotoLibraryUseCaseProtocol,
         completion: @escaping (AlbumEntity, [NodeEntity]) -> Void,
         isNewAlbum: Bool = false,
         configuration: PhotoLibraryContentConfiguration? = nil) {
        self.album = album
        self.photoLibraryUseCase = photoLibraryUseCase
        self.completion = completion
        self.selectLimit = configuration?.selectLimit ?? 150
        
        photoLibraryContentViewModel = PhotoLibraryContentViewModel(library: PhotoLibrary(),
                                                                    contentMode: .album,
                                                                    configuration: configuration)
        navigationTitle = normalNavigationTitle
        isDoneButtonDisabled = !isNewAlbum
        setupSubscriptions(isNewAlbum: isNewAlbum)
    }
    
    deinit {
        photosLoadingTask?.cancel()
    }
    
    public func onDone() {
        let nodes: [NodeEntity] = photoLibraryContentViewModel.selection.photos.values.map { $0 }
        guard nodes.isNotEmpty else {
            shouldDismiss.toggle()
            return
        }
        completion(album, nodes)   
        shouldDismiss.toggle()
    }
    
    func onFilter() {
        photoLibraryContentViewModel.showFilter.toggle()
    }
    
    func onCancel() {
        shouldDismiss.toggle()
    }
    
    // MARK: - Private
    private func setupSubscriptions(isNewAlbum: Bool) {
        photoLibraryContentViewModel.selection.$photos
            .compactMap { [weak self] photos in
                guard let self else { return nil }
                return photos.isEmpty ? self.normalNavigationTitle : Strings.Localizable.General.Format.itemsSelected(photos.count)
            }
            .receive(on: DispatchQueue.main)
            .assign(to: &$navigationTitle)
        
        if !isNewAlbum {
            photoLibraryContentViewModel.selection.$photos
                .map { $0.isEmpty }
                .removeDuplicates()
                .receive(on: DispatchQueue.main)
                .assign(to: &$isDoneButtonDisabled)
        }
        
        photoLibraryContentViewModel.filterViewModel.$appliedFilterLocation
            .removeDuplicates()
            .sink { [weak self] appliedPhotoFilterLocation in
                self?.loadPhotos(forPhotoLocation: appliedPhotoFilterLocation)
            }
            .store(in: &subscriptions)
        
        photoLibraryContentViewModel.selection.$isItemSelectedAfterLimitReached
            .assign(to: &$showSelectionLimitReachedAlert)
    }
    
    private func loadPhotos(forPhotoLocation filterLocation: PhotosFilterLocation) {
        photosLoadingTask = Task(priority: .userInitiated) { [photoLibraryUseCase] in
            do {
                let cloudDrivePhotos = try await photoLibraryUseCase.media(for: [.cloudDrive, .allMedia], excludeSensitive: nil)
                let cameraUploadPhotos = try await photoLibraryUseCase.media(for: [.cameraUploads, .allMedia], excludeSensitive: nil)
                hideFilter(cloudDrivePhotos.isEmpty || cameraUploadPhotos.isEmpty)
                updatePhotoSourceLocationIfRequired(filterLocation: filterLocation,
                                                          isCloudDriveEmpty: cloudDrivePhotos.isEmpty,
                                                          isCameraUploadsEmpty: cameraUploadPhotos.isEmpty)
                updatePhotoSourceLocationNavigationTitleIfRequired()
                updatePhotoLibraryContent(cloudDrivePhotos: cloudDrivePhotos, cameraUploadPhotos: cameraUploadPhotos)
            } catch {
                MEGALogError("Error occurred when loading photos. \(error.localizedDescription)")
            }
        }
    }
    
    private func updatePhotoLibraryContent(cloudDrivePhotos: [NodeEntity], cameraUploadPhotos: [NodeEntity]) {
        let filteredPhotos = photoNodes(for: photoSourceLocation, from: cloudDrivePhotos, and: cameraUploadPhotos)
            .filter { $0.hasThumbnail }
        photoLibraryContentViewModel.library = filteredPhotos.toPhotoLibrary(withSortType: .newest)
        photoLibraryContentViewModel.selection.editMode = .active
    }
    
    private func hideFilter(_ shouldHideFilter: Bool) {
        guard self.shouldRemoveFilter != shouldHideFilter else {
            return
        }
        self.shouldRemoveFilter = shouldHideFilter
    }
    
    private func updatePhotoSourceLocationIfRequired(filterLocation: PhotosFilterLocation, isCloudDriveEmpty: Bool,
                                                     isCameraUploadsEmpty: Bool) {
        var selectedFilterLocation = filterLocation
        if isCloudDriveEmpty {
            selectedFilterLocation = .cameraUploads
        } else if isCameraUploadsEmpty {
            selectedFilterLocation = .cloudDrive
        }
        guard self.photoSourceLocation != selectedFilterLocation else {
            return
        }
        self.photoSourceLocation = selectedFilterLocation
    }
    
    private func photoNodes(
        for location: PhotosFilterLocation,
        from cloudDrivePhotos: [NodeEntity],
        and cameraUploadPhotos: [NodeEntity]
    ) -> [NodeEntity] {
        switch location {
        case .allLocations:
            return cloudDrivePhotos + cameraUploadPhotos
        case .cloudDrive:
            return cloudDrivePhotos
        case .cameraUploads:
            return cameraUploadPhotos
        }
    }
    
    private func updatePhotoSourceLocationNavigationTitleIfRequired() {
        guard photoSourceLocationNavigationTitle != photoSourceLocation.localization else {
            return
        }
        photoSourceLocationNavigationTitle = photoSourceLocation.localization
    }
}
