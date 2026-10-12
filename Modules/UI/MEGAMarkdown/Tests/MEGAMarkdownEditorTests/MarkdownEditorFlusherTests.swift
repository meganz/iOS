@testable import MEGAMarkdownEditor
import Testing

@MainActor
struct MarkdownEditorFlusherTests {
    @Test func flusherWithoutEditorDoesNothing() {
        let flusher = MarkdownEditorFlusher()
        #expect(flusher.action == nil)

        flusher.flush()

        #expect(flusher.action == nil)
    }

    @Test func flusherRunsTheEditorActionOncePerFlush() {
        let flusher = MarkdownEditorFlusher()
        var runs = 0
        flusher.action = { runs += 1 }

        flusher.flush()
        #expect(runs == 1)

        flusher.flush()
        #expect(runs == 2)
    }
}
