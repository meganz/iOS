import Foundation
import MEGADomain
import MEGADomainMock
import Testing
@testable import Transfer

@Suite("TransferEntityMapper completed rows")
struct TransferEntityMapperTests {

    @Test func completedDownload_carriesLocationAndDateInSubtitle() {
        let entity = TransferEntity(
            type: .download,
            totalBytes: 7_000_000,
            fileName: "Document_1A.pdf",
            updateTime: Date(timeIntervalSince1970: 1_723_316_940),
            state: .complete
        )

        let state = TransferEntityMapper.rowState(for: entity, location: "/Downloads/MEGA")

        #expect(state.status == .completed)
        #expect(state.direction == .download)
        #expect(state.fileName == "Document_1A.pdf")
        #expect(state.location == "/Downloads/MEGA")
        #expect(state.subtitle.hasPrefix("↓ "))
        #expect(state.subtitle.contains(" · "))
    }

    @Test func completedUpload_usesUpArrowAndLocation() {
        let entity = TransferEntity(
            type: .upload,
            totalBytes: 1024,
            fileName: "note.txt",
            updateTime: Date(timeIntervalSince1970: 1_723_316_940),
            state: .complete
        )

        let state = TransferEntityMapper.rowState(for: entity, location: "/Cloud drive/Documents")

        #expect(state.direction == .upload)
        #expect(state.location == "/Cloud drive/Documents")
        #expect(state.subtitle.hasPrefix("↑ "))
        #expect(state.subtitle.contains(" · "))
    }

    @Test func completedWithoutUpdateTime_omitsDateSeparator() {
        let entity = TransferEntity(
            type: .download,
            totalBytes: 2048,
            fileName: "b.txt",
            updateTime: nil,
            state: .complete
        )

        let state = TransferEntityMapper.rowState(for: entity)

        #expect(state.status == .completed)
        #expect(state.location == nil)
        #expect(!state.subtitle.contains(" · "))
    }

    @Test func activeRow_defaultsLocationToNil() {
        let entity = TransferEntity(
            type: .download,
            transferredBytes: 50,
            totalBytes: 100,
            fileName: "c.txt",
            state: .active
        )

        let state = TransferEntityMapper.rowState(for: entity)

        #expect(state.status == .active)
        #expect(state.location == nil)
    }
}
