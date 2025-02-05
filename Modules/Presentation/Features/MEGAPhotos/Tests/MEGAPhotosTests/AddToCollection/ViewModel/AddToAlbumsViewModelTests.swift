import AsyncAlgorithms
import Combine
import ContentLibraries
import MEGADomain
import MEGADomainMock
import MEGAL10n
@testable import MEGAPhotos
import MEGAPresentation
import MEGAPresentationMock
import MEGASwift
import MEGASwiftUI
import SwiftUI
import Testing

@Suite("AddToAlbumsViewModel Tests")
struct AddToAlbumsViewModelTests {
    private enum TestError: Error {
        case timeout
    }

    @Suite("Ensure Columns Counts")
    @MainActor
    struct ColumnsCount {
        @Test("Column count is 3 for compact and 5 for regular",
              arguments: [
                (UserInterfaceSizeClass?.some(.compact), 3),
                (UserInterfaceSizeClass?.some(.regular), 5),
                (UserInterfaceSizeClass?.none, 3)]
        )
        func columnCount(
            horizontalSizeClass: UserInterfaceSizeClass?,
            expectedCount: Int
        ) {
            let sut = AddToAlbumsViewModelTests.makeSUT()
            
            #expect(sut.columns(horizontalSizeClass: horizontalSizeClass).count == expectedCount)
        }
    }
   
    @Suite("Monitor User Albums")
    @MainActor
    struct MonitorUseAlbums {
        @Test("Loading album cell view models")
        func userAlbumLoaded() async throws {
            let userAlbum1 = AlbumEntity(id: 4, type: .user, creationTime: try "2024-04-04T22:01:04Z".date)
            let userAlbum2 = AlbumEntity(id: 5, type: .user, creationTime: try "2024-04-05T10:02:04Z".date)
            let (stream, continuation) = AsyncStream.makeStream(of: [AlbumEntity].self)
            continuation.yield([userAlbum1, userAlbum2])
            continuation.yield([userAlbum2])
            continuation.finish()
            let monitorAlbumsUseCase = MockMonitorAlbumsUseCase(
                monitorUserAlbumsSequence: stream.eraseToAnyAsyncSequence()
            )
            let sut = AddToAlbumsViewModelTests.makeSUT(
                monitorAlbumsUseCase: monitorAlbumsUseCase)
            
            #expect(sut.isAlbumsLoaded == false)
            await confirmation("Album view models loaded in correct order", expectedCount: 2) { albumViewModelsLoaded in
                var expectations = [
                    [AlbumCellViewModel(album: userAlbum2),
                     AlbumCellViewModel(album: userAlbum1)],
                    [AlbumCellViewModel(album: userAlbum2)]
                ]
                let subscription = sut.$albums
                    .dropFirst()
                    .sink {
                        #expect($0 == expectations.removeFirst())
                        albumViewModelsLoaded()
                    }
                
                await sut.monitorUserAlbums()
                subscription.cancel()
            }
            #expect(sut.isAlbumsLoaded == true)
        }
    }
    
    @Suite("Create Albums")
    @MainActor
    struct CreateAlbums {
        @Test("On create album tap should show alert view")
        func onCreateAlbumTap() async throws {
            let sut = AddToAlbumsViewModelTests.makeSUT()
            
            var cancellable: AnyCancellable?
            try await withCheckedThrowingContinuation { (continuation: CheckedContinuation<Void, Error>) in
                cancellable = sut.$showCreateAlbumAlert
                    .setFailureType(to: TestError.self)
                    .dropFirst()
                    .timeout(.milliseconds(500), scheduler: DispatchQueue.main, customError: {
                        TestError.timeout
                    })
                    .sink(receiveCompletion: {
                        cancellable?.cancel()
                        switch $0 {
                        case .finished:
                            continuation.resume()
                        case .failure(let error):
                            continuation.resume(throwing: error)
                        }
                    }, receiveValue: {
                        #expect($0 == true)
                        cancellable?.cancel()
                        continuation.resume()
                    })
                
                sut.onCreateAlbumTapped()
            }
        }
        
        @Test("when create alert is shown and action is triggered then it should create album", arguments: [
            ("My Album", "My Album"),
            ("", Strings.Localizable.CameraUploads.Albums.Create.Alert.placeholder)])
        func createAlertView(albumName: String, expectedName: String) async {
            let albumListUseCase = MockAlbumListUseCase()
            let sut = AddToAlbumsViewModelTests
                .makeSUT(albumListUseCase: albumListUseCase)
            let alertViewModel = sut.alertViewModel()
            
            #expect(alertViewModel == TextFieldAlertViewModel(
                title: Strings.Localizable.CameraUploads.Albums.Create.Alert.title,
                placeholderText: Strings.Localizable.CameraUploads.Albums.Create.Alert.placeholder,
                affirmativeButtonTitle: Strings.Localizable.createFolderButton,
                destructiveButtonTitle: Strings.Localizable.cancel))
            
            await confirmation("Ensure create user album created") { createdConfirmation in
                let invocationTask = Task {
                    for await invocation in albumListUseCase.invocationSequence {
                        #expect(invocation == .createUserAlbum(name: expectedName))
                        createdConfirmation()
                        break
                    }
                }
                alertViewModel.action?(albumName)
                
                Task {
                    try? await Task.sleep(nanoseconds: 500_000_000)
                    invocationTask.cancel()
                }
                await invocationTask.value
            }
        }
        
        @Test("When nil action passed then it should not create an album")
        func nilAction() async {
            let albumListUseCase = MockAlbumListUseCase()
            let sut = AddToAlbumsViewModelTests
                .makeSUT(albumListUseCase: albumListUseCase)
            let alertViewModel = sut.alertViewModel()
            
            await confirmation("Ensure album is not created", expectedCount: 0) { createdConfirmation in
                let invocationTask = Task {
                    for await _ in albumListUseCase.invocationSequence {
                        createdConfirmation()
                    }
                }
                alertViewModel.action?(nil)
                
                Task {
                    try? await Task.sleep(nanoseconds: 500_000_000)
                    invocationTask.cancel()
                }
                await invocationTask.value
            }
        }
    }
    
    @Suite("Add items to album protocol conformance")
    @MainActor
    struct AddPhotosToAlbum {
        
        @Test(arguments: [false, true])
        func addButtonDisabled(isSelected: Bool) async throws {
            let albumSelection = AlbumSelection(mode: .single)
            albumSelection.setSelectedAlbums(isSelected ? [.init(id: 1, type: .user)] : [])
            
            let sut = AddToAlbumsViewModelTests
                .makeSUT(albumSelection: albumSelection)
            
            var cancellable: AnyCancellable?
            try await withCheckedThrowingContinuation { (continuation: CheckedContinuation<Void, Error>) in
                cancellable = sut.isAddButtonDisabled
                    .setFailureType(to: TestError.self)
                    .timeout(.milliseconds(500), scheduler: DispatchQueue.main, customError: {
                        TestError.timeout
                    })
                    .sink(receiveCompletion: {
                        cancellable?.cancel()
                        switch $0 {
                        case .finished:
                            continuation.resume()
                        case .failure(let error):
                            continuation.resume(throwing: error)
                        }
                    }, receiveValue: {
                        #expect($0 == !isSelected)
                        continuation.resume()
                        cancellable?.cancel()
                    })
            }
        }
        
        @Test
        func isItemsNotEmptyPublisher() async throws {
            let sut = AddToAlbumsViewModelTests
                .makeSUT()
            
            try await confirmation("isItemsNotEmpty match publisher") { confirmation in
                let invocationTask = Task {
                    var expectations = [false, true, false]
                    for await isNotEmpty in sut.isItemsNotEmptyPublisher.values {
                        #expect(isNotEmpty == expectations.removeFirst())
                        if expectations.isEmpty {
                            confirmation()
                            break
                        }
                        
                    }
                }
                // Ensure task started
                try await Task.sleep(nanoseconds: 50_000_000)
                
                sut.albums = [AlbumCellViewModel(album: .init(id: 5, type: .user))]
                sut.albums = []
                
                Task {
                    try? await Task.sleep(nanoseconds: 500_000_000)
                    invocationTask.cancel()
                }
                await invocationTask.value
            }
        }
        
        @Test
        func addItems() async {
            let album = AlbumEntity(id: 3, type: .user)
            let albumSelection = AlbumSelection(mode: .single)
            albumSelection.setSelectedAlbums([album])
            
            let photos = [NodeEntity(handle: 1), NodeEntity(handle: 2)]
            let addedPhotoCount = 1
            let albumModificationUseCase = MockAlbumModificationUseCase(
                addPhotosResult: .success(.init(success: UInt(addedPhotoCount), failure: 0))
            )
            let router = MockAddToCollectionRouter()
            let sut = AddToAlbumsViewModelTests
                .makeSUT(
                    albumModificationUseCase: albumModificationUseCase,
                    addToCollectionRouter: router,
                    albumSelection: albumSelection)
            
            let message = Strings.Localizable.Set.AddTo.Snackbar.message(addedPhotoCount)
                .replacingOccurrences(of: "[A]", with: album.name)
            await confirmation("Ensure create user album created") { addAlbumItems in
                let invocationTask = Task {
                    for await (useCaseInvocation, routerInvocation) in combineLatest(albumModificationUseCase.invocationSequence,
                                                                                     router.invocationSequence) {
                        #expect(useCaseInvocation == .addPhotosToAlbum(id: album.id, nodes: photos))
                        #expect(routerInvocation == .showSnackBarOnDismiss(message: message))
                        addAlbumItems()
                        break
                    }
                }
                sut.addItems(photos)
                
                Task {
                    try? await Task.sleep(nanoseconds: 500_000_000)
                    invocationTask.cancel()
                }
                await invocationTask.value
            }
            
        }
    }

    @MainActor
    private static func makeSUT(
        monitorAlbumsUseCase: some MonitorAlbumsUseCaseProtocol = MockMonitorAlbumsUseCase(),
        thumbnailLoader: some ThumbnailLoaderProtocol = MockThumbnailLoader(),
        monitorUserAlbumPhotosUseCase: some MonitorUserAlbumPhotosUseCaseProtocol = MockMonitorUserAlbumPhotosUseCase(),
        nodeUseCase: some NodeUseCaseProtocol = MockNodeUseCase(),
        sensitiveNodeUseCase: some SensitiveNodeUseCaseProtocol = MockSensitiveNodeUseCase(),
        sensitiveDisplayPreferenceUseCase: some SensitiveDisplayPreferenceUseCaseProtocol = MockSensitiveDisplayPreferenceUseCase(),
        albumCoverUseCase: some AlbumCoverUseCaseProtocol = MockAlbumCoverUseCase(),
        albumListUseCase: some AlbumListUseCaseProtocol = MockAlbumListUseCase(),
        albumModificationUseCase: some AlbumModificationUseCaseProtocol = MockAlbumModificationUseCase(),
        addToCollectionRouter: some AddToCollectionRouting = MockAddToCollectionRouter(),
        contentLibrariesConfiguration: ContentLibraries.Configuration = .init(
            sensitiveNodeUseCase: MockSensitiveNodeUseCase(),
            nodeUseCase: MockNodeUseCase(),
            isAlbumPerformanceImprovementsEnabled: { true }),
        albumSelection: AlbumSelection = AlbumSelection(mode: .single)
    ) -> AddToAlbumsViewModel {
        .init(
            monitorAlbumsUseCase: monitorAlbumsUseCase,
            thumbnailLoader: thumbnailLoader,
            monitorUserAlbumPhotosUseCase: monitorUserAlbumPhotosUseCase,
            nodeUseCase: nodeUseCase,
            sensitiveNodeUseCase: sensitiveNodeUseCase,
            sensitiveDisplayPreferenceUseCase: sensitiveDisplayPreferenceUseCase,
            albumCoverUseCase: albumCoverUseCase,
            albumListUseCase: albumListUseCase,
            albumModificationUseCase: albumModificationUseCase,
            addToCollectionRouter: addToCollectionRouter,
            contentLibrariesConfiguration: contentLibrariesConfiguration,
            albumSelection: albumSelection)
    }
}
