import Combine
import SwiftUI
import MEGADomain

final class AlbumListViewModel: NSObject, ObservableObject  {
    @Published var cameraUploadNode: NodeEntity?
    @Published var album: AlbumEntity?
    @Published var shouldLoad = true
    @Published var albums = [AlbumEntity]()
    @Published var newlyAddedAlbum: AlbumEntity?

    @Published var showCreateAlbumAlert = false {
        willSet {
            self.alertViewModel.placeholderText = newAlbumName()
        }
    }
   
    var albumCreationAlertMsg: String?
    var albumLoadingTask: Task<Void, Never>?
    var isCreateAlbumFeatureFlagEnabled: Bool {
        featureFlagProvider.isFeatureFlagEnabled(for: .createAlbum)
    }
    
    private let usecase: AlbumListUseCaseProtocol
    private(set) var alertViewModel: TextFieldAlertViewModel
    private let featureFlagProvider: FeatureFlagProviderProtocol
    
    init(usecase: AlbumListUseCaseProtocol,
         alertViewModel: TextFieldAlertViewModel,
         featureFlagProvider: FeatureFlagProviderProtocol = FeatureFlagProvider()) {
        self.usecase = usecase
        self.alertViewModel = alertViewModel
        self.featureFlagProvider = featureFlagProvider
        super.init()
        self.alertViewModel.action = { [weak self] newAlbumName in
            guard let self = self else { return }
            Task { await self.createUserAlbum(with: newAlbumName) }
        }
        self.alertViewModel.validator = validateAlbum
    }
    
    func columns(horizontalSizeClass: UserInterfaceSizeClass?) -> [GridItem] {
        guard isCreateAlbumFeatureFlagEnabled,
              let horizontalSizeClass else {
            return Array(
                repeating: .init(.flexible(), spacing: 10),
                count: 3
            )
        }
        return Array(
            repeating: .init(.flexible(), spacing: 10),
            count: horizontalSizeClass == .compact ? 3 : 5
        )
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
  
                if let insertIndex = albums.firstIndex(where: { $0.type == .user && (newAlbum.modificationTime ?? .distantPast) > ($0.modificationTime ?? .distantPast) }) {
                    albums.insert(newAlbum, at: insertIndex)
                }  else {
                    albums.append(newAlbum)
                }
                newlyAddedAlbum = await usecase.hasNoPhotosAndVideos() ? nil : newAlbum
            } catch {
                MEGALogError("Error creating user album: \(error.localizedDescription)")
            }
            shouldLoad = false
        }
    }
    
    // MARK: - Private
    @MainActor
    private func loadAllAlbums() {
        albumLoadingTask = Task {
            async let systemAlbums = systemAlbums()
            async let userAlbums = userAlbums()
            albums = await systemAlbums + userAlbums
            shouldLoad = false
        }
    }
    
    private func systemAlbums() async -> [AlbumEntity] {
        do {
            return try await usecase.systemAlbums().map({ album in
                if let localizedAlbumName = localisedName(forAlbumType: album.type) {
                    return album.update(name: localizedAlbumName)
                }
                return album
            })
        } catch {
            MEGALogError("Error loading system albums: \(error.localizedDescription)")
            return []
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
    
    private func userAlbums() async -> [AlbumEntity] {
        var userAlbums = await usecase.userAlbums()
        userAlbums.sort { ($0.modificationTime ?? .distantPast) > ($1.modificationTime ?? .distantPast) }
        return userAlbums
    }
    

    func newAlbumName() -> String {
        var newAlbumName = Strings.Localizable.CameraUploads.Albums.Create.Alert.placeholder
        let count = self.albums.filter({ $0.name.hasPrefix(newAlbumName) }).count
        if count > 0 {
            newAlbumName += " (\(count))"
        }
        return newAlbumName
    }
    
    func validateAlbum(name: String?) -> TextFieldAlertError? {
        guard let name = name, name.isNotEmpty else { return nil }
        guard let name = name.trim, name.isNotEmpty else {
            return TextFieldAlertError(title: alertViewModel.title, description: "")
        }
        
        if name.mnz_containsInvalidChars() {
            return TextFieldAlertError(title: Strings.Localizable.General.Error.charactersNotAllowed(String.Constants.invalidFileFolderNameCharacters), description: Strings.Localizable.CameraUploads.Albums.Create.Alert.enterNewName)
        }
        if isReservedAlbumName(name: name) {
           return TextFieldAlertError(title: Strings.Localizable.CameraUploads.Albums.Create.Alert.albumNameNotAllowed, description: Strings.Localizable.CameraUploads.Albums.Create.Alert.enterDifferentName)
        }
        if self.albums.first(where: { $0.name == name }) != nil {
            return TextFieldAlertError(title: Strings.Localizable.CameraUploads.Albums.Create.Alert.userAlbumExists, description: Strings.Localizable.CameraUploads.Albums.Create.Alert.enterDifferentName)
        }
        return nil
    }
    
    @MainActor
    func onAlbumContentAdded(_ msg: String, _ album: AlbumEntity) {
        self.album = album
        albumCreationAlertMsg = msg
        loadAlbums()
    }
    
    private func isReservedAlbumName(name: String) -> Bool {
        let reservedNames = [Strings.Localizable.CameraUploads.Albums.Favourites.title,
                             Strings.Localizable.CameraUploads.Albums.Gif.title,
                             Strings.Localizable.CameraUploads.Albums.Raw.title,
                             Strings.Localizable.CameraUploads.Albums.MyAlbum.title,
                             Strings.Localizable.CameraUploads.Albums.SharedAlbum.title]
        return reservedNames.reduce(false) { $0 || name.caseInsensitiveCompare($1) == .orderedSame }
    }
}
