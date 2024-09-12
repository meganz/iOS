@testable import MEGA

class MockCameraSwitcher: CameraSwitching, @unchecked Sendable {
    var switchCamera_CallCount = 0
    func switchCamera() async {
        switchCamera_CallCount += 1
    }
}
