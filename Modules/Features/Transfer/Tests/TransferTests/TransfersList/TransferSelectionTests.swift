import Testing
@testable import Transfer

@MainActor
@Suite("TransferSelection")
struct TransferSelectionTests {

    // MARK: - Select all

    @Test func toggleSelectAll_selectsEveryListedTag_thenDeselectsThemAll() {
        let sut = TransferSelection()
        sut.setListedTags([1, 2, 3])

        sut.toggleSelectAll()
        #expect(sut.selectedTags == [1, 2, 3])

        sut.toggleSelectAll()
        #expect(sut.selectedTags.isEmpty)
    }

    @Test func toggleSelectAll_withPartialSelection_selectsTheRest() {
        let sut = TransferSelection()
        sut.setListedTags([1, 2, 3])
        sut.selectedTags = [2]

        sut.toggleSelectAll()

        #expect(sut.selectedTags == [1, 2, 3])
    }

    @Test func toggleSelectAll_deselectsEvenWhenTheSelectionOutgrewTheList() {
        // A row can be selected a moment before it drops off the list, leaving a
        // tag the listed set no longer has. Under set equality that leftover made
        // every tap re-select instead of clearing, so the button looked dead.
        let sut = TransferSelection()
        sut.setListedTags([1, 2])
        sut.selectedTags = [1, 2, 99]

        sut.toggleSelectAll()

        #expect(sut.selectedTags.isEmpty)
    }

    @Test func toggleSelectAll_withNothingListed_staysEmpty() {
        let sut = TransferSelection()

        sut.toggleSelectAll()

        #expect(sut.selectedTags.isEmpty)
    }

    @Test func toggleSelectAll_alternatesOnEverySingleTap() {
        // Regression: the first tap selected everything and the second did nothing,
        // taking a third to clear. Every tap must flip the state.
        let sut = TransferSelection()
        sut.setListedTags([1, 2, 3])

        sut.toggleSelectAll()
        #expect(sut.selectedTags == [1, 2, 3])

        sut.toggleSelectAll()
        #expect(sut.selectedTags.isEmpty)

        sut.toggleSelectAll()
        #expect(sut.selectedTags == [1, 2, 3])
    }

    // MARK: - Converging on the listed rows

    @Test func setListedTags_dropsSelectedTagsThatLeftTheList() {
        let sut = TransferSelection()
        sut.setListedTags([1, 2, 3])
        sut.selectedTags = [1, 2, 3]

        sut.setListedTags([2])

        #expect(sut.selectedTags == [2])
    }

    @Test func setListedTags_keepsSelectionWhenRowsOnlyAppear() {
        let sut = TransferSelection()
        sut.setListedTags([1])
        sut.selectedTags = [1]

        sut.setListedTags([1, 2])

        #expect(sut.selectedTags == [1])
    }

    @Test func dropListedTag_removesItFromBothTheListAndTheSelection() {
        let sut = TransferSelection()
        sut.setListedTags([1, 2])
        sut.selectedTags = [1, 2]

        sut.dropListedTag(1)

        #expect(sut.selectedTags == [2])
        #expect(sut.listedTags == [2])
        // Every remaining row is selected, so the next toggle deselects...
        sut.toggleSelectAll()
        #expect(sut.selectedTags.isEmpty)
        // ...and selecting all again cannot resurrect the dropped tag.
        sut.toggleSelectAll()
        #expect(sut.selectedTags == [2])
    }

    @Test func dropListedTag_forAnUnselectedRow_leavesTheSelectionAlone() {
        let sut = TransferSelection()
        sut.setListedTags([1, 2])
        sut.selectedTags = [2]

        sut.dropListedTag(1)

        #expect(sut.selectedTags == [2])
    }

    // MARK: - Clear

    @Test func clear_emptiesTheSelectionButKeepsTheListedTags() {
        let sut = TransferSelection()
        sut.setListedTags([1, 2])
        sut.selectedTags = [1, 2]

        sut.clear()

        #expect(sut.selectedTags.isEmpty)
        #expect(sut.listedTags == [1, 2])
    }
}
