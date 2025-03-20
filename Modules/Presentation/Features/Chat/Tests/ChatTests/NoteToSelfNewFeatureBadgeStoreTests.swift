@testable import Chat
import MEGADomain
import MEGADomainMock
import Testing

@MainActor
@Suite("NoteToSelfNewFeatureBadgeStoreTests")
struct NoteToSelfNewFeatureBadgeStoreTests {
    @MainActor class Harness {
        let sut: NoteToSelfNewFeatureBadgeStore
        let userAttributeUseCase: MockUserAttributeUseCase

        init(
            noteToSelfNewFeatureBadge: NoteToSelfNewFeatureBadgeEntity? = nil
        ) {
            userAttributeUseCase = MockUserAttributeUseCase()
            
            sut = .init(
                userAttributeUseCase: userAttributeUseCase
            )
        }
        
        static func presentedTimes(count: Int) async -> Harness {
            let harness = Harness()
            try? await harness.userAttributeUseCase.saveNoteToSelfNewFeatureBadge(presentedTimes: count)
            return harness
        }
    }
    
    @Test("Increment Note to self new feature badge count - count must be incremented by one")
    func testIncrementNoteToSelfNewFeatureBadgePresentedCount_countMustBeIncrementedByOne() async {
        let presentedCount = 3
        let harness = await Harness.presentedTimes(count: presentedCount)
        await harness.sut.incrementNoteToSelfNewFeatureBadgePresented()
        try? await #expect(harness.userAttributeUseCase.retrieveNoteToSelfNewFeatureBadgeAttribute()?.presentedCount == presentedCount + 1)
    }
    
    @Test("Should show Note to self new feature badge", arguments: 0...6)
    func testShouldShowNoteToSelfNewFeatureBadge(presentedCount: Int) async {
        let harness = await Harness.presentedTimes(count: presentedCount)
        let shouldShow = await harness.sut.shouldShowNoteToSelfNewFeatureBadge()
        #expect(shouldShow == (presentedCount < NoteToSelfNewFeatureBadgeStore.Constants.noteToSelfNewFeatureBadgeMaxPresentedCount))
    }
}
