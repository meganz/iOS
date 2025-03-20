import MEGADomain
import MEGASDKRepo

/// Protocol responsible for managing the display behavior of the 'NEW' badge in the 'Note to Self' UI.
/// The display count is stored as a user attribute, ensuring persistence across iOS sessions.
public protocol NoteToSelfNewFeatureBadgeStoring: Sendable {
    
    /// Determines whether the 'NEW' badge should be displayed, based on how many times it has been shown.
    /// The maximum allowed display count is defined by `Constants.noteToSelfNewFeatureBadgeMaxPresentedCount`.
    /// - Returns: `true` if the badge should be shown, `false` otherwise.
    func shouldShowNoteToSelfNewFeatureBadge() async -> Bool
    
    /// Increments the display count of the 'NEW' badge by one.
    /// This method should persist the updated count as a user attribute.
    func incrementNoteToSelfNewFeatureBadgePresented() async
}

public struct NoteToSelfNewFeatureBadgeStore: NoteToSelfNewFeatureBadgeStoring {
    public init(
        userAttributeUseCase: any UserAttributeUseCaseProtocol
    ) {
        self.userAttributeUseCase = userAttributeUseCase
    }
    
    let userAttributeUseCase: any UserAttributeUseCaseProtocol

    enum Constants {
        static let noteToSelfNewFeatureBadgeMaxPresentedCount = 5
    }
    
    public func shouldShowNoteToSelfNewFeatureBadge() async -> Bool {
        do {
            if let noteToSelfNewFeatureBadgePresentedTimeAttribute = try await userAttributeUseCase.retrieveNoteToSelfNewFeatureBadgeAttribute() {
                return noteToSelfNewFeatureBadgePresentedTimeAttribute.presentedCount < Constants.noteToSelfNewFeatureBadgeMaxPresentedCount
            } else {
                return true
            }
        } catch {
            MEGALogError("[NoteToSelfBadgeStore] Error getting note to self new feature badge attribute: \(error)")
            return false
        }
    }
    
    public func incrementNoteToSelfNewFeatureBadgePresented() async {
        do {
            if let noteToSelfNewFeatureBadgePresentedTimeAttribute = try await userAttributeUseCase.retrieveNoteToSelfNewFeatureBadgeAttribute() {
                try await userAttributeUseCase.saveNoteToSelfNewFeatureBadge(presentedTimes: noteToSelfNewFeatureBadgePresentedTimeAttribute.presentedCount + 1)
            } else {
                try await userAttributeUseCase.saveNoteToSelfNewFeatureBadge(presentedTimes: 1)
            }
        } catch {
            MEGALogError("[NoteToSelfBadgeStore] Unable to increment note to self new feature badge presented times. \(error.localizedDescription)")
        }
    }
}
