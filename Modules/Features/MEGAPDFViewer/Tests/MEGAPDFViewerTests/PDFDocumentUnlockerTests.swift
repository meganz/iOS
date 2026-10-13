import Foundation
@testable import MEGAPDFViewer
import PDFKit
import Testing

@MainActor
struct PDFDocumentUnlockerTests {
    @Test func unlock_withWrongPassword_returnsFalseAndKeepsDocumentLocked() throws {
        let document = try makeLockedDocument()

        let result = PDFDocumentUnlocker().unlock(document: document, password: "wrong")

        #expect(!result)
        #expect(document.isLocked)
    }

    @Test func unlock_withCorrectPassword_returnsTrueAndUnlocksDocument() throws {
        let document = try makeLockedDocument()

        let result = PDFDocumentUnlocker().unlock(document: document, password: "secret")

        #expect(result)
        #expect(!document.isLocked)
        #expect(document.string?.contains("Locked document, page one.") == true)
    }

    @Test func unlock_doesNotUnlockIndependentDocument() throws {
        let displayDocument = try makeLockedDocument()
        let thumbnailDocument = try makeLockedDocument()

        #expect(PDFDocumentUnlocker().unlock(document: displayDocument, password: "secret"))
        #expect(!displayDocument.isLocked)
        #expect(thumbnailDocument.isLocked)
    }

    @Test func unlock_preservesLeadingAndTrailingSpaces() throws {
        let document = try makeDocument(named: "locked-rc4-spaces")
        try #require(document.isLocked)

        #expect(!PDFDocumentUnlocker().unlock(document: document, password: "secret"))
        #expect(document.isLocked)
        #expect(PDFDocumentUnlocker().unlock(document: document, password: " secret "))
        #expect(!document.isLocked)
    }

    @Test func unlock_acceptsExplicitEmptyPassword() throws {
        let document = try makeDocument(named: "encrypted-rc4-empty")

        #expect(PDFDocumentUnlocker().unlock(document: document, password: ""))
        #expect(!document.isLocked)
        #expect(document.string?.contains("Locked document, page one.") == true)
    }

    private func makeLockedDocument() throws -> PDFDocument {
        let document = try makeDocument(named: "locked-rc4")
        try #require(document.isLocked)
        return document
    }

    private func makeDocument(named name: String) throws -> PDFDocument {
        let url = try #require(Bundle.module.url(forResource: name, withExtension: "pdf", subdirectory: "Fixtures"))
        let document = try #require(PDFDocument(url: url))
        try #require(document.isEncrypted)
        return document
    }
}
