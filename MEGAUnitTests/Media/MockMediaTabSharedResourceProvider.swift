@testable import MEGA
import MEGAAppPresentationMock
import MEGADomain
import MEGADomainMock
import MEGAPermissionsMock
import MEGAPreferenceMocks
import SwiftUI

@MainActor
final class MockMediaTabSharedResourceProvider: @MainActor MediaTabSharedResourceProvider {
    lazy var cameraUploadStatusButtonViewModel: CameraUploadStatusButtonViewModel = {
        CameraUploadStatusButtonViewModel(
            monitorCameraUploadUseCase: MockMonitorCameraUploadUseCase(),
            devicePermissionHandler: MockDevicePermissionHandler(),
            preferenceUseCase: MockPreferenceUseCase(),
            cameraUploadsSettingsViewRouter: MockRouter(),
            cameraUploadProgressRouter: MockCameraUploadProgressRouter(),
            featureFlagProvider: MockFeatureFlagProvider(list: [:])
        )
    }()

    var contextMenuConfig: CMConfigEntity?
    var contextMenuManager: ContextMenuManager?
    @Published var editMode: SwiftUI.EditMode = .inactive
    var editModePublisher: Published<SwiftUI.EditMode>.Publisher { $editMode }
    
    func toggleSearch() {
        
    }
}
