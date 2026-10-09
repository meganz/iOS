import Foundation
@testable import MEGA
import Testing

private let limit = FileExtensionGroupOCWrapper.maxExtensionlessTextFileSize

private let sniffCases: [(name: String, contents: [UInt8], isEditable: Bool)] = [
    ("notes", Array("hello\nworld".utf8), true),
    ("notes", [0x09, 0x0A, 0x0C, 0x0D, 0x20, 0x7E], true),
    ("notes", [], true),
    ("notes", [0x68, 0x69, 0x00], false),
    ("notes", Array("\u{1B}[31mfailed\u{1B}[0m".utf8), true),
    ("notes", [0x08, 0x0B, 0x1A], true),
    ("notes", [0x89, 0x50, 0x4E, 0x47, 0x0D, 0x0A, 0x1A, 0x0A, 0x00, 0x00, 0x00, 0x0D], false),
    ("notes.txt", [0x68, 0x69, 0x00], true)
]

@Suite("FileExtensionGroupOCWrapper editable text")
struct FileExtensionGroupOCWrapperTests {

    // MARK: - File name

    @Test("Names are classified by their real path extension, with extensionless ones capped by size", arguments: [
        ("notes", UInt64(1024), true),
        ("/tmp/handle/notes", UInt64(1024), true),
        ("notes", limit, true),
        ("notes", limit + 1, false),
        ("notes.txt", limit + 1, true),
        ("README.MD", UInt64(1024), true),
        ("main.swift", UInt64(1024), true),
        ("photo.png", UInt64(1024), false),
        ("archive.zip", UInt64(1024), false)
    ])
    func editableTextByName(name: String, fileSize: UInt64, isEditable: Bool) {
        #expect(FileExtensionGroupOCWrapper.verify(isEditableText: name, fileSize: fileSize) == isEditable)
    }

    @Test("A nil name is not editable text")
    func nilNameIsNotEditableText() {
        #expect(FileExtensionGroupOCWrapper.verify(isEditableText: nil, fileSize: 0) == false)
    }

    // MARK: - File at path

    @Test("A local file's size is read from disk", arguments: [
        ("notes", limit, true),
        ("notes", limit + 1, false),
        ("notes.txt", limit + 1, true)
    ])
    func editableTextFileAtPath(name: String, fileSize: UInt64, isEditable: Bool) throws {
        // Only the header is sniffed, so a text header followed by a sparse tail reaches any size cheaply.
        let header = Data(repeating: UInt8(ascii: "a"), count: 64 * 1024)
        let fileURL = try makeFile(named: name, contents: header, size: fileSize)
        defer { try? FileManager.default.removeItem(at: fileURL.deletingLastPathComponent()) }

        #expect(FileExtensionGroupOCWrapper.verify(isEditableTextFileAtPath: fileURL.path) == isEditable)
    }

    @Test("A local file without an extension is binary only when its header has a NUL byte", arguments: sniffCases)
    func editableTextFileAtPathSniffsContent(name: String, contents: [UInt8], isEditable: Bool) throws {
        let fileURL = try makeFile(named: name, contents: Data(contents))
        defer { try? FileManager.default.removeItem(at: fileURL.deletingLastPathComponent()) }

        #expect(FileExtensionGroupOCWrapper.verify(isEditableTextFileAtPath: fileURL.path) == isEditable)
    }

    @Test("Only the 64KB header of a file without an extension is sniffed")
    func contentBeyondHeaderIsNotSniffed() throws {
        var contents = Data(repeating: UInt8(ascii: "a"), count: 64 * 1024)
        contents.append(0x00)
        let fileURL = try makeFile(named: "notes", contents: contents)
        defer { try? FileManager.default.removeItem(at: fileURL.deletingLastPathComponent()) }

        #expect(FileExtensionGroupOCWrapper.verify(isEditableTextFileAtPath: fileURL.path))
    }

    @Test("A missing file without an extension is not editable text")
    func missingFileIsNotEditableText() {
        let path = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString).path
        #expect(FileExtensionGroupOCWrapper.verify(isEditableTextFileAtPath: path) == false)
    }

    @Test("A nil path is not editable text")
    func nilPathIsNotEditableText() {
        #expect(FileExtensionGroupOCWrapper.verify(isEditableTextFileAtPath: nil) == false)
    }

    // MARK: - Helpers

    private func makeFile(named name: String, contents: Data, size: UInt64? = nil) throws -> URL {
        let directory = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString)
        try FileManager.default.createDirectory(at: directory, withIntermediateDirectories: true)
        let fileURL = directory.appendingPathComponent(name)
        try contents.write(to: fileURL)
        if let size {
            let fileHandle = try FileHandle(forWritingTo: fileURL)
            try fileHandle.truncate(atOffset: size)
            try fileHandle.close()
        }
        return fileURL
    }
}
