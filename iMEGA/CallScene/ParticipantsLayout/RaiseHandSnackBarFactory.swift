import MEGADomain
import MEGAL10n

///  Creates a SnackBar instance for given Raise Hand scenario, taking into account
///  _only_ necessary variables, local hand state and number of other participant that raised hands
struct RaiseHandSnackBarFactory {
    enum Scenario {
        case nobodyRaisedHand
        case onlyMe
        case onlyOther(name: String)
        case othersNotMe(firstOther: String, count: Int) // count >= 0
        case meAndOthers(count: Int) // count >= 0
    }
    
    var viewRaisedHandsHandler: () -> Void
    var lowerHandHandler: () -> Void
    
    func snackBar(
        participantsThatJustRaisedHands: [CallParticipantEntity],
        localRaisedHand: Bool
    ) -> SnackBar? {
        snackBar(
            from: scenario(
                from: participantsThatJustRaisedHands,
                localRaisedHand: localRaisedHand
            )
        )
    }
    
    /// mapping scenarios to actual SnackBar config
    /// it's optional, that signals that in scenario `nobodyRaisedHand`
    /// there's no snack bar shown at all, hence we return nil in that case
    private func snackBar(from scenario: Scenario) -> SnackBar? {
        switch scenario {
        case .nobodyRaisedHand:
            nil
        case .onlyMe:
            .raiseHandSnackBar(
                message: Strings.Localizable.Chat.Call.RaiseHand.SnackBar.ownUserRaisedHand,
                action: lowerHandAction
            )
            
        case .onlyOther(name: let name):
            .raiseHandSnackBar(
                message: Strings.Localizable.Chat.Call.RaiseHand.SnackBar.otherPersonRaisedHand(name),
                action: viewRaisedHandsAction
            )
        case .othersNotMe(let firstOther, let count):
            .raiseHandSnackBar(
                message: formattedFirstOther(firstOther, count),
                action: viewRaisedHandsAction
            )
        case .meAndOthers(count: let count):
            .raiseHandSnackBar(
                message: Strings.Localizable.Chat.Call.RaiseHands.SnackBar.youAndOtherPersonRaisedHands(count),
                action: lowerHandAction
            )
        }
    }
    
    private func formattedFirstOther(
        _ firstOther: String,
        _ count: Int
    ) -> String {
        let string = Strings.Localizable.Chat.Call.RaiseHands.SnackBar.manyOtherPersonsRaisedHands(count)
        return string.replacingOccurrences(of: "[A]", with: firstOther)
    }
    
    /// analyses content of the participants and by using supplied closures isMe and amIContained
    /// produces complete set of possible states that Snack bar for raise hands can be in
    private func scenario(
        from participants: [CallParticipantEntity],
        localRaisedHand: Bool
    ) -> Scenario {
        let raisedHands = participants.filter { $0.raisedHand }
        
        if raisedHands.isEmpty && !localRaisedHand {
            return .nobodyRaisedHand
        }
        
        if localRaisedHand && raisedHands.isEmpty {
            return .onlyMe
        }
        
        if !localRaisedHand && raisedHands.count == 1, let participant = raisedHands.first {
            return .onlyOther(name: participant.name ?? "")
        }
        
        return if localRaisedHand {
            .meAndOthers(count: raisedHands.count)
        } else {
            .othersNotMe(firstOther: raisedHands.first?.name ?? "", count: raisedHands.count - 1)
        }
    }
    
    /// only two possible actions configs for 5 total possible states, so
    /// extracting here for easy reuse
    private var lowerHandAction: SnackBar.Action {
        .init(
            title: Strings.Localizable.Chat.Call.RaiseHand.SnackBar.lowerHand,
            handler: lowerHandHandler
        )
    }
    
    private var viewRaisedHandsAction: SnackBar.Action {
        .init(
            title: Strings.Localizable.Chat.Call.RaiseHand.SnackBar.view,
            handler: viewRaisedHandsHandler
        )
    }
}

extension SnackBar {
    /// extracted factory to keep common parameters in sync:
    /// - layout
    /// - colors (slightly different, background is white solid always)
    static func raiseHandSnackBar(
        message: String,
        action: SnackBar.Action
    ) -> SnackBar? {
        .init(
            message: message,
            layout: .horizontal,
            action: action,
            colors: .raiseHand
        )
    }
}
