import Combine
import SwiftUI
import MEGADomain

final class AlbumListViewModel: NSObject, ObservableObject  {
    @Published var cameraUploadNode: NodeEntity?
    @Published var album: AlbumEntity?
    @Published var shouldLoad = true
    @Published var albums = [AlbumEntity]()
    @Published var showCreateAlbumAlert = false
    @Published var newlyAddedAlbum: AlbumEntity?
    var columns: [GridItem] = Array(
        repeating: .init(.flexible(), spacing: 10),
        count: 3
    )
    var albumLoadingTask: Task<Void, Never>?
    var isCreateAlbumFeatureFlagEnabled: Bool {
        FeatureFlagProvider().isFeatureFlagEnabled(for: .createAlbum)
    }
    
    private let usecase: AlbumListUseCaseProtocol
    private(set) var alertViewModel: TextFieldAlertViewModel
    
    init(usecase: AlbumListUseCaseProtocol, alertViewModel: TextFieldAlertViewModel) {
        self.usecase = usecase
        self.alertViewModel = alertViewModel
        super.init()
        self.alertViewModel.action = { newAlbumName in
            Task { await self.createUserAlbum(with: newAlbumName) }
        }
        self.alertViewModel.validator = validateAlbum
    }
    
    @MainActor
    func loadAlbums() {
        loadAllAlbums()
        usecase.startMonitoringNodesUpdate { [weak self] in
            self?.loadAllAlbums()
        }
    }
    
    func cancelLoading() {
        usecase.stopMonitoringNodesUpdate()
        albumLoadingTask?.cancel()
    }
    
    @MainActor
    func createUserAlbum(with name: String?) {
        guard let name = name else { return }
        guard name.isNotEmpty else {
            createUserAlbum(with: newAlbumName())
            return
        }
        
        shouldLoad = true
        Task {
            do {
                let newAlbum = try await usecase.createUserAlbum(with: name)
                albums.append(newAlbum)
                albums.sort(by: { $0.name < $1.name })
                newlyAddedAlbum = newAlbum
            } catch {
                MEGALogError("Error creating album: \(error.localizedDescription)")
            }
            shouldLoad = false
        }
    }
    
    // MARK: - Private
    @MainActor
    private func loadAllAlbums() {
        albumLoadingTask = Task {
            albums = await usecase.loadAlbums().map({ album in
                if let localizedAlbumName = localisedName(forAlbumType: album.type) {
                    return album.update(name: localizedAlbumName)
                }
                return album
            })
            shouldLoad = false
        }
    }
    
    private func localisedName(forAlbumType albumType: AlbumEntityType) -> String? {
        switch (albumType) {
        case .favourite:
            return Strings.Localizable.CameraUploads.Albums.Favourites.title
        case .gif:
            return Strings.Localizable.CameraUploads.Albums.Gif.title
        case .raw:
            return Strings.Localizable.CameraUploads.Albums.Raw.title
        default:
            return nil
        }
    }
    
    func newAlbumName() -> String {
        var newAlbumName = Strings.Localizable.CameraUploads.Albums.Create.Alert.placeholder
        let count = self.albums.filter({ $0.name.hasPrefix(newAlbumName) }).count
        if count > 0 {
            newAlbumName += " (\(count))"
        }
        return newAlbumName
    }
    
    func validateAlbum(name: String?) -> String? {
        guard let name = name, name.isNotEmpty else { return nil }
        if name.mnz_containsInvalidChars() {
            return Strings.Localizable.General.Error.charactersNotAllowed(String.Constants.invalidFileFolderNameCharacters)
        }
        if let existingAlbum = self.albums.first(where: { $0.name.lowercased() == name.lowercased() }) {
            return existingAlbum.type == .user ?  Strings.Localizable.CameraUploads.Albums.Create.Alert.userAlbumExists : Strings.Localizable.CameraUploads.Albums.Create.Alert.systemAlbumExists
        }
        return nil
    }
}
