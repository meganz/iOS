import Foundation
import MEGADomain
import MEGADomainMock
import MEGAL10n
import Testing
@testable import Transfer

@Suite("TransferEntityMapper completed rows")
struct TransferEntityMapperTests {

    @Test func completedDownload_carriesLocationAndCompletionDateInSubtitle() {
        let finishDate = Date(timeIntervalSince1970: 1_723_316_940)
        let entity = TransferEntity(
            type: .download,
            totalBytes: 7_000_000,
            fileName: "Document_1A.pdf",
            updateTime: Date(timeIntervalSince1970: 0),
            state: .complete
        )

        let state = TransferEntityMapper.rowState(
            for: entity,
            location: "/Downloads/MEGA",
            finishDate: finishDate
        )

        #expect(state.status == .completed)
        #expect(state.direction == .download)
        #expect(state.fileName == "Document_1A.pdf")
        #expect(state.location == "/Downloads/MEGA")
        #expect(state.subtitle.hasPrefix("↓ "))
        #expect(state.subtitle.contains(" · "))
    }

    @Test func completedUpload_usesUpArrowLocationAndCompletionDate() {
        let finishDate = Date(timeIntervalSince1970: 1_723_316_940)
        let entity = TransferEntity(
            type: .upload,
            totalBytes: 1024,
            fileName: "note.txt",
            updateTime: Date(timeIntervalSince1970: 0),
            state: .complete
        )

        let state = TransferEntityMapper.rowState(
            for: entity,
            location: "/Cloud drive/Documents",
            finishDate: finishDate
        )

        #expect(state.direction == .upload)
        #expect(state.location == "/Cloud drive/Documents")
        #expect(state.subtitle.hasPrefix("↑ "))
        #expect(state.subtitle.contains(" · "))
    }

    @Test func completedWithoutCompletionDate_ignoresUpdateTimeAndOmitsDateSeparator() {
        let entity = TransferEntity(
            type: .download,
            totalBytes: 2048,
            fileName: "b.txt",
            updateTime: Date(timeIntervalSince1970: 0),
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

@Suite("TransferEntityMapper failed rows")
struct TransferEntityMapperFailedRowsTests {

    @Test func failedDownload_withoutDate_usesFailedLabelOnly() {
        let entity = TransferEntity(type: .download, fileName: "a.txt", state: .failed)

        let state = TransferEntityMapper.rowState(for: entity)

        #expect(state.status == .failed)
        #expect(state.subtitle == "↓ \(Strings.Localizable.Transfers.Tab.failed)")
        #expect(state.location == nil)
    }

    @Test func cancelledUpload_withoutDate_usesCancelledLabelOnly() {
        let entity = TransferEntity(type: .upload, fileName: "b.txt", state: .cancelled)

        let state = TransferEntityMapper.rowState(for: entity)

        #expect(state.status == .cancelled)
        #expect(state.subtitle == "↑ \(Strings.Localizable.cancelled)")
        #expect(state.location == nil)
    }

    @Test func failedDownload_withDateStillUsesFailedLabelOnly() {
        let finishDate = Date(timeIntervalSince1970: 1_723_316_940)
        let entity = TransferEntity(type: .download, fileName: "a.txt", state: .failed)

        let state = TransferEntityMapper.rowState(for: entity, finishDate: finishDate)

        #expect(state.subtitle == "↓ \(Strings.Localizable.Transfers.Tab.failed)")
    }

    @Test func cancelledUpload_withDateStillUsesCancelledLabelOnly() {
        let finishDate = Date(timeIntervalSince1970: 1_723_316_940)
        let entity = TransferEntity(type: .upload, fileName: "b.txt", state: .cancelled)

        let state = TransferEntityMapper.rowState(for: entity, finishDate: finishDate)

        #expect(state.subtitle == "↑ \(Strings.Localizable.cancelled)")
    }
}
