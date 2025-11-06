import MEGADomain

public protocol RaiseHandBadgeStoring: Sendable {
    func shouldPresentRaiseHandBadge() async -> Bool
    func incrementRaiseHandBadgePresented() async
    func saveRaiseHandBadgeAsPresented() async
}

public struct RaiseHandBadgeStore: RaiseHandBadgeStoring {
    public init(
        userAttributeUseCase: any UserAttributeUseCaseProtocol
    ) {
        self.userAttributeUseCase = userAttributeUseCase
    }
    
    let userAttributeUseCase: any UserAttributeUseCaseProtocol

    enum Constants {
        static let raiseHandBadgeMaxPresentedCount = 5
    }
    
    public func shouldPresentRaiseHandBadge() async -> Bool {
        do {
            if let raiseHandBadgePresentedTimeAttribute = try await userAttributeUseCase.retrieveRaiseHandAttribute() {
                return raiseHandBadgePresentedTimeAttribute.presentedCount < Constants.raiseHandBadgeMaxPresentedCount
            } else {
                return true
            }
        } catch {
            logError("Error getting raise hand badge attribute: \(error)")
            return false
        }
    }
    
    public func incrementRaiseHandBadgePresented() async {
        do {
            if let raiseHandBadgePresentedTimeAttribute = try await userAttributeUseCase.retrieveRaiseHandAttribute() {
                try await userAttributeUseCase.saveRaiseHandNewFeatureBadge(presentedTimes: raiseHandBadgePresentedTimeAttribute.presentedCount + 1)
            } else {
                try await userAttributeUseCase.saveRaiseHandNewFeatureBadge(presentedTimes: 1)
            }
        } catch {
            logError("[Calls] Unable to increment raise hand badge presented times. \(error.localizedDescription)")
        }
    }
    
    public func saveRaiseHandBadgeAsPresented() async {
        do {
            try await userAttributeUseCase.saveRaiseHandNewFeatureBadge(presentedTimes: Constants.raiseHandBadgeMaxPresentedCount)
        } catch {
            logError("[Calls] Unable to save raise hand badge presented. \(error.localizedDescription)")
        }
    }
}
