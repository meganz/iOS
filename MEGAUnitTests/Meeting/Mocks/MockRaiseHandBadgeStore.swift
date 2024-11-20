@testable import MEGA

class MockRaiseHandBadgeStore: RaiseHandBadgeStoring, @unchecked Sendable {
    var shouldPresentRaiseHandBadge_CallCount = 0
    var incrementRaiseHandBadgePresented_CallCount = 0
    var saveRaiseHandBadgeAsPresented_CallCount = 0
    var shouldPresentRaiseHandBadge: Bool = false
    var onSaveRaiseHandBadgeAsPresented: (() -> Void)?

    func shouldPresentRaiseHandBadge() async -> Bool {
        shouldPresentRaiseHandBadge_CallCount += 1
        return shouldPresentRaiseHandBadge
    }
    
    func incrementRaiseHandBadgePresented() async {
        incrementRaiseHandBadgePresented_CallCount += 1
    }
    
    func saveRaiseHandBadgeAsPresented() async {
        saveRaiseHandBadgeAsPresented_CallCount += 1
        onSaveRaiseHandBadgeAsPresented?()
    }
}
