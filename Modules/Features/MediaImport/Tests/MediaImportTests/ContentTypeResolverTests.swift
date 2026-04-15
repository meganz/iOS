import Foundation
import Testing
import UniformTypeIdentifiers
@testable import MediaImport

@Suite("ContentTypeResolver")
struct ContentTypeResolverTests {
    let sut = ContentTypeResolver()

    @Test("Prefers HEIC over JPEG when both registered")
    func prefersHEIC() {
        let provider = makeProvider(types: .jpeg, .heic)
        #expect(sut.preferredContentType(for: provider) == .heic)
    }

    @Test("Returns JPEG when HEIC not available")
    func fallsBackToJPEG() {
        let provider = makeProvider(types: .jpeg)
        #expect(sut.preferredContentType(for: provider) == .jpeg)
    }

    @Test("Returns movie type when no image types")
    func fallsBackToMovie() {
        let provider = makeProvider(types: .mpeg4Movie)
        #expect(sut.preferredContentType(for: provider) == .mpeg4Movie)
    }

    @Test("Returns .item when no types registered")
    func emptyProviderReturnsItem() {
        let provider = NSItemProvider()
        #expect(sut.preferredContentType(for: provider) == .item)
    }

    @Test("Returns PNG for PNG-only provider")
    func pngProvider() {
        let provider = makeProvider(types: .png)
        #expect(sut.preferredContentType(for: provider) == .png)
    }

    @Test("Skips livePhoto type")
    func skipsLivePhoto() {
        let provider = makeProvider(types: .livePhoto, .jpeg)
        #expect(sut.preferredContentType(for: provider) == .jpeg)
    }

    @Test("Falls back to first registered type when no image or movie")
    func fallsBackToFirstType() {
        let provider = makeProvider(types: .pdf)
        #expect(sut.preferredContentType(for: provider) == .pdf)
    }

    // MARK: - Helpers

    private func makeProvider(types: UTType...) -> NSItemProvider {
        let provider = NSItemProvider()
        for type in types {
            provider.registerDataRepresentation(for: type, visibility: .all) { completion in
                completion(nil, nil)
                return Progress()
            }
        }
        return provider
    }
}
