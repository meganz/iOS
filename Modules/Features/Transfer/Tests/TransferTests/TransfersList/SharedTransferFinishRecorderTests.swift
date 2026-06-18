import Foundation
import MEGADomain
import MEGADomainMock
import Testing
@testable import Transfer

@Suite("SharedTransferFinishRecorder")
struct SharedTransferFinishRecorderTests {

    @Test func date_forUnrecordedTag_isNil() {
        let sut = SharedTransferFinishRecorder(counterUseCase: MockTransferCounterUseCase())

        #expect(sut.finishDate(forTag: 1) == nil)
    }

    @Test func recordIfAbsent_storesAndReturnsDate_lookedUpByTag() {
        let sut = SharedTransferFinishRecorder(counterUseCase: MockTransferCounterUseCase())
        let date = Date(timeIntervalSince1970: 1_723_316_940)

        let returned = sut.recordIfAbsent(tag: 1, date: date)

        #expect(returned == date)
        #expect(sut.finishDate(forTag: 1) == date)
    }

    @Test func recordIfAbsent_isIdempotent_keepsFirstDate() {
        let sut = SharedTransferFinishRecorder(counterUseCase: MockTransferCounterUseCase())
        let first = Date(timeIntervalSince1970: 1_723_316_940)
        let second = Date(timeIntervalSince1970: 1_999_999_999)

        sut.recordIfAbsent(tag: 1, date: first)
        let returned = sut.recordIfAbsent(tag: 1, date: second)

        #expect(returned == first)
        #expect(sut.finishDate(forTag: 1) == first)
    }

    @Test func recordIfAbsent_keepsDistinctTagsSeparate() {
        let sut = SharedTransferFinishRecorder(counterUseCase: MockTransferCounterUseCase())
        let dateOne = Date(timeIntervalSince1970: 1_000)
        let dateTwo = Date(timeIntervalSince1970: 2_000)

        sut.recordIfAbsent(tag: 1, date: dateOne)
        sut.recordIfAbsent(tag: 2, date: dateTwo)

        #expect(sut.finishDate(forTag: 1) == dateOne)
        #expect(sut.finishDate(forTag: 2) == dateTwo)
    }

    @Test func removeDates_removesOnlySpecifiedTags() {
        let sut = SharedTransferFinishRecorder(counterUseCase: MockTransferCounterUseCase())
        let dateOne = Date(timeIntervalSince1970: 1_000)
        let dateTwo = Date(timeIntervalSince1970: 2_000)

        sut.recordIfAbsent(tag: 1, date: dateOne)
        sut.recordIfAbsent(tag: 2, date: dateTwo)
        sut.removeDates(forTags: [1])

        #expect(sut.finishDate(forTag: 1) == nil)
        #expect(sut.finishDate(forTag: 2) == dateTwo)
    }

    @Test func recordCompletedFinish_recordsOnlyCompletedTransfers() {
        let sut = SharedTransferFinishRecorder(counterUseCase: MockTransferCounterUseCase())

        sut.recordCompletedFinish(TransferEntity(type: .download, tag: 1, state: .failed))
        sut.recordCompletedFinish(TransferEntity(type: .download, tag: 2, state: .complete))

        #expect(sut.finishDate(forTag: 1) == nil)
        #expect(sut.finishDate(forTag: 2) != nil)
    }
}
