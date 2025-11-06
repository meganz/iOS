@testable import CloudDrive
import MEGASwift
import Testing

@Suite("NodeTagViewModel Tests")
struct NodeTagViewModelTests {

    @MainActor
    @Test("Test initial values")
    func testInitialValues() {
        let sut1 = NodeTagViewModel(tag: "tag1", isSelected: false)
        #expect(sut1.tag == "tag1")
        #expect(sut1.isSelected == false)
        let sut2 = NodeTagViewModel(tag: "tag2", isSelected: true)
        #expect(sut2.tag == "tag2")
        #expect(sut2.isSelected == true)
    }

    @MainActor
    @Test("Test the formatted tag method")
    func verifyFormattedTag() {
        let input = "tag1"
        let sut = NodeTagViewModel(tag: input, isSelected: false)
        #expect(sut.formattedTag == "\u{200e}#\(input)")
    }

    @MainActor
    @Test("Test the toggle method")
    func verifyToggle() {
        let sut = NodeTagViewModel(tag: "tag1", isSelected: false)
        var tagName: String?
        let cancellable = sut.observeToggles().sink {
            tagName = $0
        }
        sut.toggle()
        #expect(tagName == "tag1")
        cancellable.cancel()
    }
}
