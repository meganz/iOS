import Combine
@testable import MEGA
import MEGAAppPresentation
import MEGAAppPresentationMock
import MEGAAppSDKRepoMock
import MEGADomain
import MEGADomainMock
import MEGAPermissions
import MEGAPermissionsMock
import MEGAPreference
import MEGAPreferenceMocks
import SwiftUI
import Testing

struct MediaTabViewModelTests {
    
    @MainActor
    @Test
    func editModeRequested() async throws {
        let contentViewModel = MockMediaTabContentViewModel()
        let sut = Self.makeSUT(
            tabViewModels: [.timeline: contentViewModel]
        )
        #expect(sut.editMode == .inactive)
        
        contentViewModel.editModeToggleRequested.send()
        
        try await Task.sleep(nanoseconds: 100_000_000)
        
        #expect(sut.editMode == .active)
    }
    
    @MainActor
    @Test
    func navigationBarUpdatePublisher() async throws {
        let contentViewModel = MockMediaTabContentViewModel()
        let sut = Self.makeSUT(
            tabViewModels: [.timeline: contentViewModel]
        )
        
        #expect(sut.navigationBarItemViewModels.isEmpty)
        
        let expectedItems = [
            NavigationBarItemViewModel(id: "test", placement: .trailing, type: .textButton(text: "Button", action: {}))
        ]
        contentViewModel.itemViewModels = expectedItems
        contentViewModel.navigationBarUpdateSubject.send()
        
        try await Task.sleep(nanoseconds: 100_000_000)
        
        #expect(sut.navigationBarItemViewModels == expectedItems)
    }
    
    @MainActor
    @Test
    func navigationTitleUpdates() async throws {
        let expectedTitle = "Updated title"
        let contentViewModel = MockMediaTabContentViewModel()
        let sut = Self.makeSUT(
            tabViewModels: [.timeline: contentViewModel]
        )
        
        contentViewModel.titleUpdateSubject.send(expectedTitle)
        
        try await Task.sleep(nanoseconds: 100_000_000)
        
        #expect(sut.navigationTitle == expectedTitle)
    }
    
    @MainActor
    @Test
    func handleToolbarItemAction() async throws {
        let expectedAction = MediaBottomToolbarAction.delete
        let contentViewModel = MockMediaTabContentViewModel()
        let sut = Self.makeSUT(
            tabViewModels: [.timeline: contentViewModel]
        )

        sut.handleToolbarItemAction(expectedAction)

        #expect(contentViewModel.handledAction == expectedAction)
    }
    
    @MainActor
    @Test
    func toolbarUpdatePublisherUpdatesToolbarConfig() async throws {
        let contentViewModel = MockMediaTabContentViewModel(
            toolBarActions: [.shareLink, .delete]
        )
        let sut = Self.makeSUT(
            tabViewModels: [.timeline: contentViewModel]
        )

        // Enable edit mode to show toolbar
        sut.editMode = .active

        // Toolbar should show even with no selection (count = 0)
        #expect(sut.toolbarConfig?.selectedItemsCount == 0)

        let mockNodes = [
            NodeEntity(),
            NodeEntity(),
            NodeEntity()
        ]
        contentViewModel.selectedNodesForToolbarValue = mockNodes
        contentViewModel.toolbarUpdateSubject.send()

        try await Task.sleep(nanoseconds: 100_000_000)

        #expect(sut.toolbarConfig?.selectedItemsCount == 3)
        #expect(sut.toolbarConfig?.actions == [.shareLink, .delete])
    }

    @MainActor
    private static func makeSUT(
        tabViewModels: [MediaTab: any MediaTabContentViewModel] = [:],
        monitorCameraUploadUseCase: some MonitorCameraUploadUseCaseProtocol = MockMonitorCameraUploadUseCase(),
        devicePermissionHandler: some DevicePermissionsHandling = MockDevicePermissionHandler(),
        preferenceUseCase: some PreferenceUseCaseProtocol = MockPreferenceUseCase(),
        cameraUploadsSettingsViewRouter: some Routing = MockRouter(),
        cameraUploadProgressRouter: some CameraUploadProgressRouting = MockCameraUploadProgressRouter()
    ) -> MediaTabViewModel {
        .init(
            tabViewModels: tabViewModels,
            monitorCameraUploadUseCase: monitorCameraUploadUseCase,
            devicePermissionHandler: devicePermissionHandler,
            cameraUploadsSettingsViewRouter: cameraUploadsSettingsViewRouter,
            cameraUploadProgressRouter: cameraUploadProgressRouter)
    }
}

private final class MockMediaTabContentViewModel: MediaTabContentViewModel {
    let editModeToggleRequested = PassthroughSubject<Void, Never>()
    let navigationBarUpdateSubject = PassthroughSubject<Void, Never>()
    let titleUpdateSubject = PassthroughSubject<String, Never>()
    let toolbarUpdateSubject = PassthroughSubject<Void, Never>()

    var toolBarActions: [MediaBottomToolbarAction]?
    var itemViewModels: [NavigationBarItemViewModel]

    weak var toolbarCoordinator: (any MediaTabToolbarCoordinatorProtocol)?

    var selectedNodesForToolbarValue: [NodeEntity] = []

    private let _contextMenuConfiguration: CMConfigEntity?
    private(set) var handledAction: MediaBottomToolbarAction?

    init(
        itemViewModels: [NavigationBarItemViewModel] = [],
        contextMenuConfiguration: CMConfigEntity? = nil,
        toolBarActions: [MediaBottomToolbarAction]? = nil
    ) {
        self.itemViewModels = itemViewModels
        _contextMenuConfiguration = contextMenuConfiguration
        self.toolBarActions = toolBarActions
    }
}

extension MockMediaTabContentViewModel: MediaTabContextMenuActionHandler { }

extension MockMediaTabContentViewModel: MediaTabNavigationBarItemProvider {
    
    var navigationBarUpdatePublisher: AnyPublisher<Void, Never>? {
        navigationBarUpdateSubject.eraseToAnyPublisher()
    }
    
    func navigationBarItems(for editMode: EditMode) -> [NavigationBarItemViewModel] {
        itemViewModels
    }
}

extension MockMediaTabContentViewModel: MediaTabContextMenuProvider {
    func contextMenuConfiguration() -> CMConfigEntity? {
        _contextMenuConfiguration
    }
}

extension MockMediaTabContentViewModel: MediaTabToolbarActionsProvider {
    var toolbarUpdatePublisher: AnyPublisher<Void, Never>? {
        toolbarUpdateSubject.eraseToAnyPublisher()
    }

    func toolbarConfig() -> MediaBottomToolbarConfig? {
        let count = selectedNodesForToolbarValue.count
        guard let actions = toolBarActions else { return nil }

        return MediaBottomToolbarConfig(
            actions: actions,
            selectedItemsCount: count,
            hasExportedItems: false,
            isAllExported: false
        )
    }
}

extension MockMediaTabContentViewModel: MediaTabToolbarActionHandler {
    func handleToolbarAction(_ action: MediaBottomToolbarAction) {
        handledAction = action
    }
}

extension MockMediaTabContentViewModel: MediaTabNavigationTitleProvider {
    var titleUpdatePublisher: AnyPublisher<String, Never> {
        titleUpdateSubject.eraseToAnyPublisher()
    }
}
