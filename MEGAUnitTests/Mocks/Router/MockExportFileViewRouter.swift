@testable import MEGA

final class MockExportFileViewRouter: ExportFileViewRouting {
    var exportedFiles_calledTimes = 0
    var showProgressView_calledTimes = 0
    var hideProgressView_calledTimes = 0
    var exportedUrls: [URL] = []
    
    func exportedFiles(urls: [URL]) {
        exportedFiles_calledTimes += 1
        exportedUrls = urls
    }
    
    func showProgressView() {
        showProgressView_calledTimes += 1
    }
    
    func hideProgressView() {
        hideProgressView_calledTimes += 1
    }
}
