import MEGADomain

/// Component that calculates what has changed for the raise hand structure
/// we need to show or hide snack bar when state is changed
/// WARNING: CallParticipantEntity is a class (most other entities are structs)
enum RaiseHandDiffing {
    
    struct Change: Equatable, Hashable {
        var handle: HandleEntity
        var raisedHand: Bool
        var index: Int? // for own user there's no index as this user is not in the callParticipant array
    }
    
    struct DiffResult: Equatable, Hashable {
        var changes: Set<Change>
        
        /// A.   signals that there are new raised hands between raiseHandListBefore and raiseHandListAfter structures,
        ///    it will be false when there are changes but users only lowered hands.
        ///    This is needed to make SnackBar appear only for new raised hands and eliminate scenario:
        ///    1. local user raises hand (we show snack bar : "Your hand is raised")
        ///    2. remote user raises hand (we show snack bar to indicate that "You and remote raised hands")
        ///    3. remote user lowers hand (we SHOULD NOT show snack bar , there are changes but only some hands were lowered)
        ///
        ///  B. signals that local user changed raise hand state so that we know to nil out the state of snack bar
        var shouldUpdateSnackBar: Bool
    }
    
    /// returns list of changed states of raise hand feature
    /// this can be used to:
    /// - update cached list of participants (needs index and new state)
    /// - reload UI (needs index)
    /// callers need to provide ordered list of handles and raise hand id list before and after mutation
    /// callParticipantHandles is used to get the indexes of call participant _after mutation_
    static func applyingRaisedHands(
        callParticipantHandles: [HandleEntity],
        raiseHandListBefore: [HandleEntity],
        raiseHandListAfter: [HandleEntity],
        localUserParticipantId: HandleEntity
    ) -> DiffResult {
        
        MEGALogDebug("[RaiseHand] callParticipantHandles: \(callParticipantHandles), raiseHandListBefore \(raiseHandListBefore),  raiseHandListAfter \(raiseHandListAfter) ")
        
        // here we cache the mapping of participant id to index for fast acceess
        var indexMapping = [HandleEntity: Int]()
        callParticipantHandles.enumerated().forEach { index, participantId in
            indexMapping[participantId] = index
        }
        
        let raiseHandBeforeSet = Set(raiseHandListBefore)
        let raiseHandAfterSet = Set(raiseHandListAfter)
        
        // here we subtract set of hands after from set of hands before
        // to get participants who lowered their hands
        //            before   after
        // example : (1,2,3) - (1,2) = (3) → user with id=3 lowered hand
        let lowered = raiseHandBeforeSet.subtracting(raiseHandAfterSet)
        
        // here we subtract set of hands before from set of hands
        // to get ids of participant who raised hands
        //            after   before
        // example : (3,4,9) - (3) = (4,9) → users with ids 4 and 9 raised hands
        let raised = raiseHandAfterSet.subtracting(raiseHandBeforeSet)
        
        let hasNewRaisedHands = raised.isNotEmpty
        let localRaisedHandStateChanged = (
            lowered.contains(localUserParticipantId) || raised.contains(localUserParticipantId)
        )
        
        // we sum (union) sets to get both raised and lowered hands indexes and state
        // to minimally update the cached callParticipants and UI
        let changed = (raised.union(lowered))
            .map { participantId in
                Change(
                    handle: participantId,
                    raisedHand: raised.contains(participantId),
                    index: indexMapping[participantId]
                )
            }
         
        return .init(
            changes: Set(changed),
            shouldUpdateSnackBar: hasNewRaisedHands || localRaisedHandStateChanged
        )
    }
}
