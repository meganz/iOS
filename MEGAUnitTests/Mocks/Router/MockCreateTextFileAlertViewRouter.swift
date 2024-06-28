@testable import MEGA

final class MockCreateTextFileAlertViewRouter: CreateTextFileAlertViewRouting {
    var createTextFile_calledTimes = 0
    var fileName: String?

    func createTextFile(_ fileName: String) {
        createTextFile_calledTimes += 1
        self.fileName = fileName
    }
}
