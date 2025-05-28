@testable import MEGA
import MEGADesignToken
import QuickLook
import Testing

@Suite("MEGAQLPreviewControllerTests")
struct MEGAQLPreviewControllerTests {

    @MainActor @Test func testInitWithFiles_setsFilesAndDelegates() {
        let files = ["/tmp/file1.txt", "/tmp/file2.txt"]
        let sut = MEGAQLPreviewController(arrayOfFiles: files)
        
        #expect(sut.numberOfPreviewItems(in: sut) == files.count)
        #expect(sut.delegate === sut)
        #expect(sut.dataSource === sut)
    }
    
    @Test func testInitWithoutFiles_setsEmptyFiles() {
        let sut = MEGAQLPreviewController()
        #expect(sut.numberOfPreviewItems(in: sut) == 0)
    }
    
    @MainActor @Test func testPreviewController_previewItemAtIndex_returnsCorrectURL() {
        let files = ["/tmp/file1.txt", "/tmp/file2.txt"]
        let sut = MEGAQLPreviewController(arrayOfFiles: files)
        
        let item = sut.previewController(sut, previewItemAt: 1)
        #expect((item as? URL)?.path == files[1])
    }
    
    @MainActor @Test func testPreviewController_previewItemAtIndex_outOfBounds_returnsEmptyURL() {
        let files = ["/tmp/file1.txt"]
        let sut = MEGAQLPreviewController(arrayOfFiles: files)
        
        let item = sut.previewController(sut, previewItemAt: 5)
        #expect((item as? URL)?.path == "/")
    }
    
    @MainActor @Test func testViewWillAppear_setsBackgroundColor() {
        let sut = MEGAQLPreviewController()
        sut.viewWillAppear(false)
        #expect(sut.view.backgroundColor == TokenColors.Background.page)
    }
    
    @Test func testShouldOpenURL_returnsFalse_andDispatchesToMain() {
        class MockMEGALinkManager {
            static var linkURL: URL?
            static var processLinkURLCalled = false
            static func processLinkURL(_ url: URL) {
                processLinkURLCalled = true
            }
        }
        
        let url = URL(fileURLWithPath: "/tmp/file1.txt")
        let sut = MEGAQLPreviewController()
        
        let result = sut.previewController(sut, shouldOpen: url, for: url as (any QLPreviewItem))
        #expect(result == false)
    }
}
