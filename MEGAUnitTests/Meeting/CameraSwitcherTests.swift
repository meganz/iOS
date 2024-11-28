import CombineSchedulers
@testable import MEGA
import MEGADomain
import MEGADomainMock
import MEGAL10n
import MEGAPermissions
import MEGAPermissionsMock
import MEGAPresentationMock
import XCTest

final class CameraSwitcherTests: XCTestCase {
    class Harness {
        let sut: CameraSwitcher
        var captureDeviceUseCase = MockCaptureDeviceUseCase()
        let localVideoUseCase = MockCallLocalVideoUseCase()
        
        init(
            cameraPositionName: String?,
            videoDeviceSelectedString: String
        ) {
            captureDeviceUseCase.cameraPositionName = cameraPositionName
            localVideoUseCase.videoDeviceSelectedString = videoDeviceSelectedString
            
            sut = .init(
                captureDeviceUseCase: captureDeviceUseCase,
                localVideoUseCase: localVideoUseCase
            )
        }
    }
    
    func testSwitching_FrontToBack() async {
        let harness = Harness(
            cameraPositionName: "back",
            videoDeviceSelectedString: "front"
        )
        await harness.sut.switchCamera()
        XCTAssertEqual(harness.localVideoUseCase.selectedCameras, ["back"])
    }
    
    func testSwitching_BackToFront() async {
        let harness = Harness(
            cameraPositionName: "front",
            videoDeviceSelectedString: "back"
        )
        await harness.sut.switchCamera()
        XCTAssertEqual(harness.localVideoUseCase.selectedCameras, ["front"])
    }
}
