import Combine
import ContentLibraries
@testable import MEGA
import MEGAAppPresentationMock
import MEGADomain
import MEGADomainMock
import MEGAL10n
import MEGASwift
import MEGASwiftUI
import MEGATest
import SwiftUI
import Testing
import Video

@MainActor
struct PlaylistTabViewModelTests {

    // MARK: - Initialization Tests

    @Test("PlaylistTabViewModel should initialize with correct dependencies")
    func initializationWithDependencies() {
        let (sut, videoPlaylistsViewModel, _, _) = makeSUT()

        #expect(sut.videoPlaylistsViewModel === videoPlaylistsViewModel)
        #expect(sut.router as? MockVideoRevampRouter != nil)
    }

    @Test("PlaylistTabViewModel should have nil sharedResourceProvider initially")
    func initialSharedResourceProviderIsNil() {
        let (sut, _, _, _) = makeSUT()

        #expect(sut.sharedResourceProvider == nil)
    }

    // MARK: - MediaTabSharedResourceConsumer Tests

    @Test("Setting sharedResourceProvider should update the property")
    func setSharedResourceProvider() {
        let (sut, _, _, _) = makeSUT()
        let mockProvider = MockMediaTabSharedResourceProvider()

        sut.sharedResourceProvider = mockProvider

        #expect(sut.sharedResourceProvider != nil)
    }

    // MARK: - MediaTabNavigationBarItemProvider Tests

    @Test("Navigation bar items should return camera upload and search buttons in inactive mode")
    func navigationBarItemsInInactiveMode() {
        let (sut, _, _, _) = makeSUT()
        let mockProvider = MockMediaTabSharedResourceProvider()
        sut.sharedResourceProvider = mockProvider

        let items = sut.navigationBarItems(for: EditMode.inactive)

        #expect(items.count == 2)

        // Check for camera upload status button (leading)
        let cameraUploadButton = items.first { $0.placement == .leading }
        #expect(cameraUploadButton != nil)

        // Check for search button (trailing)
        let searchButton = items.first { $0.placement == .trailing }
        #expect(searchButton != nil)
    }

    @Test("Camera upload button should have correct ID")
    func cameraUploadButtonId() {
        let (sut, _, _, _) = makeSUT()
        let mockProvider = MockMediaTabSharedResourceProvider()
        sut.sharedResourceProvider = mockProvider

        let items = sut.navigationBarItems(for: EditMode.inactive)
        let cameraButton = items.first { $0.placement == .leading }

        #expect(cameraButton?.id.contains("cameraUploadStatus") == true)
    }

    // MARK: - MediaTabNavigationTitleProvider Tests

    @Test("Title update publisher should always emit the same title")
    func titleUpdatePublisherConsistency() async throws {
        let (sut, _, _, _) = makeSUT()

        var titles: [String] = []
        var subscriptions = Set<AnyCancellable>()

        sut.titleUpdatePublisher
            .prefix(3)
            .sink { title in
                titles.append(title)
            }
            .store(in: &subscriptions)

        #expect(titles.count == 1)
        #expect(titles.allSatisfy { $0 == Strings.Localizable.Videos.Tab.Title.playlist })
    }

    // MARK: - Integration Tests

    @Test("Changing sharedResourceProvider should not affect navigation bar items structure")
    func sharedResourceProviderChangePreservesStructure() {
        let (sut, _, _, _) = makeSUT()
        let mockProvider1 = MockMediaTabSharedResourceProvider()
        let mockProvider2 = MockMediaTabSharedResourceProvider()

        sut.sharedResourceProvider = mockProvider1
        let items1 = sut.navigationBarItems(for: EditMode.inactive)

        sut.sharedResourceProvider = mockProvider2
        let items2 = sut.navigationBarItems(for: EditMode.inactive)

        #expect(items1.count == items2.count)
        #expect(items1.count == 2)
    }

    @Test("VideoPlaylistsViewModel reference should be maintained throughout lifecycle")
    func videoPlaylistsViewModelReferenceMaintained() {
        let (sut, originalViewModel, _, _) = makeSUT()
        let mockProvider = MockMediaTabSharedResourceProvider()

        // Perform various operations
        sut.sharedResourceProvider = mockProvider
        _ = sut.navigationBarItems(for: .inactive)

        // ViewModel reference should still be the same
        #expect(sut.videoPlaylistsViewModel === originalViewModel)
    }

    // MARK: - Test Helpers

    private func makeSUT() -> (
        sut: PlaylistTabViewModel,
        videoPlaylistsViewModel: VideoPlaylistsViewModel,
        videoConfig: VideoConfig,
        router: any VideoRevampRouting
    ) {
        let syncModel = VideoRevampSyncModel()
        let featureFlagProvider = MockFeatureFlagProvider(list: [:])

        let videoPlaylistsViewModel = VideoPlaylistsViewModel(
            videoPlaylistsUseCase: MockVideoPlaylistUseCase(),
            videoPlaylistContentUseCase: MockVideoPlaylistContentUseCase(),
            videoPlaylistModificationUseCase: MockVideoPlaylistModificationUseCase(),
            sortOrderPreferenceUseCase: MockSortOrderPreferenceUseCase(),
            accountStorageUseCase: MockAccountStorageUseCase(),
            syncModel: syncModel,
            alertViewModel: TextFieldAlertViewModel(
                title: "",
                placeholderText: "",
                affirmativeButtonTitle: "",
                destructiveButtonTitle: "",
                message: nil
            ),
            renameVideoPlaylistAlertViewModel: TextFieldAlertViewModel(
                title: "",
                placeholderText: "",
                affirmativeButtonTitle: "",
                destructiveButtonTitle: "",
                message: nil
            ),
            thumbnailLoader: MockThumbnailLoader(),
            featureFlagProvider: featureFlagProvider,
            contentProvider: VideoPlaylistsViewModelContentProvider(
                videoPlaylistsUseCase: MockVideoPlaylistUseCase()
            ),
            videoRevampRouter: MockVideoRevampRouter()
        )

        let videoConfig = VideoConfig.live()
        let router = MockVideoRevampRouter()

        let sut = PlaylistTabViewModel(
            videoPlaylistsViewModel: videoPlaylistsViewModel,
            videoConfig: videoConfig,
            router: router
        )

        return (sut, videoPlaylistsViewModel, videoConfig, router)
    }
}
