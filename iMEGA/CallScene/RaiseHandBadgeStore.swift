import MEGADomain

protocol RaiseHandBadgeStoring: Sendable {
    func shouldPresentRaiseHandBadge() async -> Bool
    func incrementRaiseHandBadgePresented() async
    func saveRaiseHandBadgeAsPresented() async
}

struct RaiseHandBadgeStore: RaiseHandBadgeStoring {
    let userAttributeUseCase: any UserAttributeUseCaseProtocol

    enum Constants {
        static let raiseHandBadgeMaxPresentedCount = 5
    }
    
    func shouldPresentRaiseHandBadge() async -> Bool {
        do {
            if let raiseHandBadgePresentedTimeAttribute = try await userAttributeUseCase.retrieveRaiseHandAttribute() {
                return raiseHandBadgePresentedTimeAttribute.presentedCount < Constants.raiseHandBadgeMaxPresentedCount
            } else {
                return true
            }
        } catch {
            MEGALogError("Error getting raise hand badge attribute: \(error)")
            return false
        }
    }
    
    func incrementRaiseHandBadgePresented() async {
        do {
            if let raiseHandBadgePresentedTimeAttribute = try await userAttributeUseCase.retrieveRaiseHandAttribute() {
                try await userAttributeUseCase.saveRaiseHandNewFeatureBadge(presentedTimes: raiseHandBadgePresentedTimeAttribute.presentedCount + 1)
            } else {
                try await userAttributeUseCase.saveRaiseHandNewFeatureBadge(presentedTimes: 1)
            }
        } catch {
            MEGALogError("[Calls] Unable to increment raise hand badge presented times. \(error.localizedDescription)")
        }
    }
    
    func saveRaiseHandBadgeAsPresented() async {
        do {
            try await userAttributeUseCase.saveRaiseHandNewFeatureBadge(presentedTimes: Constants.raiseHandBadgeMaxPresentedCount)
        } catch {
            MEGALogError("[Calls] Unable to save raise hand badge presented. \(error.localizedDescription)")
        }
    }
}
