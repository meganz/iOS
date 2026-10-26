import MEGADomain
import MEGADomainMock
import MEGAPreference
import MEGAPreferenceMocks
import Testing

struct ResumeTextPositionUseCaseTests {
    private let node = NodeEntity(name: "note.md", fingerprint: "fingerprint", handle: 1, isFile: true)

    @Test func lineAndOffsetAreStoredApart() {
        let sut = makeSUT()
        sut.saveReadingOffset(500, for: node)
        sut.saveReadingLine(12, for: node)

        #expect(sut.readingOffset(for: node) == 500)
        #expect(sut.readingLine(for: node) == 12)

        sut.deleteReadingLine(for: node)

        #expect(sut.readingOffset(for: node) == 500)
        #expect(sut.readingLine(for: node) == nil)
    }

    @Test func nodeWithoutFingerprintSavesNoLine() {
        let sut = makeSUT()
        let node = NodeEntity(name: "note.md", fingerprint: nil, handle: 2, isFile: true)

        sut.saveReadingLine(12, for: node)

        #expect(sut.readingLine(for: node) == nil)
    }

    // MARK: - Helper

    private func makeSUT() -> ResumeTextPositionUseCase {
        ResumeTextPositionUseCase(preferenceUseCase: MockPreferenceUseCase())
    }
}
