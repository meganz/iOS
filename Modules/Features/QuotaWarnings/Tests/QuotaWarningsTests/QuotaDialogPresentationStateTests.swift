@testable import QuotaWarnings
import Testing

@MainActor
@Suite("QuotaDialogPresentationState")
struct QuotaDialogPresentationStateTests {

    @Test("Claims the slot when no dialog is on screen")
    func claimsFreeSlot() {
        let sut = QuotaDialogPresentationState()

        #expect(sut.beginPresenting())
        #expect(sut.isPresenting)
    }

    @Test("Refuses to claim a slot that is already taken")
    func refusesTakenSlot() {
        let sut = QuotaDialogPresentationState()
        #expect(sut.beginPresenting())

        #expect(sut.beginPresenting() == false)
        #expect(sut.isPresenting)
    }

    @Test("Ending a presentation frees the slot for the next dialog")
    func endingFreesSlot() {
        let sut = QuotaDialogPresentationState()
        #expect(sut.beginPresenting())

        sut.endPresenting()

        #expect(sut.isPresenting == false)
        #expect(sut.beginPresenting())
    }
}
