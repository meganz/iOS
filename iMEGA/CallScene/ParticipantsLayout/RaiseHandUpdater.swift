import MEGADomain

/// implements the actual logic to compare changes before and after call raise hands state was changed
/// and calls corresponding closures to:
/// 1. update parent state
/// 2. update  UI
///    a) local camera feed view
///    b) remote participant cells
///    c) snack bar
struct RaiseHandUpdater {
    init(
        snackBarFactory: some RaiseHandSnackBarProviding,
        updateLocalRaiseHand: @escaping (Bool) -> Void,
        stateUpdater: @escaping (Int, RaiseHandDiffing.Change) -> Void,
        snackBarUpdater: @escaping (SnackBar?) -> Void
    ) {
        self.snackBarFactory = snackBarFactory
        self.updateLocalRaiseHand = updateLocalRaiseHand
        self.stateUpdater = stateUpdater
        self.snackBarUpdater = snackBarUpdater
    }
    
    /// produces actual config for `SnackBarView` or `nil`,
    private let snackBarFactory: any RaiseHandSnackBarProviding
    
    /// updates local camera feed Raise Hand icon (LOCAL USER RAISE HAND)
    private var updateLocalRaiseHand: (_ hidden: Bool) -> Void
    
    /// updates collection view cells with raise hand icon and storage of state
    /// so that `CallParticipantEntity` can be updated
    /// (REMOTE USER RAISE HAND)
    private var stateUpdater: (_ index: Int, _ change: RaiseHandDiffing.Change) -> Void
    
    /// shows SnackBarView with config or hides it when `snackBar` nil
    private var snackBarUpdater: (_ snackBar: SnackBar?) -> Void
    
    func update(
        /// this does __not__ contain local user
        callParticipants: [CallParticipantEntity],
        raiseHandListBefore: [HandleEntity],
        raiseHandListAfter: [HandleEntity],
        localUserHandle: HandleEntity
    ) {
        updateRemoteRaisedHandChanges(
            callParticipants: callParticipants,
            raiseHandListBefore: raiseHandListBefore,
            raiseHandListAfter: raiseHandListAfter,
            localUserHandle: localUserHandle
        )
        let localUserHandLowered = raiseHandListAfter.notContains(localUserHandle)
        updateLocalRaiseHand(localUserHandLowered)
    }
    
    private func updateRemoteRaisedHandChanges(
        callParticipants: [CallParticipantEntity],
        raiseHandListBefore: [HandleEntity],
        raiseHandListAfter: [HandleEntity],
        localUserHandle: HandleEntity
    ) {
        
        // compute changes to minimally update collection view and show/hide snack bar only when needed
        let diffed = RaiseHandDiffing.applyingRaisedHands(
            callParticipantHandles: callParticipants.map(\.participantId),
            raiseHandListBefore: raiseHandListBefore,
            raiseHandListAfter: raiseHandListAfter,
            localUserParticipantId: localUserHandle
        )
        
        diffed.changes.forEach { change in
            // update CallParticipantEntity objects and reload cells
            guard let index = change.index else { return }
            stateUpdater(index, change)
        }
        
        MEGALogDebug("[RaiseHand] raise hand changed \(diffed.changes.isNotEmpty) : \(raiseHandListAfter)")
        
        let localJustRaisedHand = (
            !raiseHandListBefore.contains(localUserHandle) &&
            raiseHandListAfter.contains(localUserHandle)
        )
        
        let callParticipantsThatJustRaisedHands = callParticipants.filter {
            diffed.hasRaisedHand(participantId: $0.participantId)
        }
        
        // to show snack bar we need to check that
        // raised hands are changed but increased to avoid scenario:
        // 1. local user raised hand (show snack bar)
        // 2. remote user raised hand (show snack bar)
        // 3. remote user lowered hand (do not show snack bar) <--- diff is not empty but we already showed snack bar for local user raising hand
        if diffed.shouldUpdateSnackBar {
            updateSnackBar(
                callParticipantsThatJustRaisedHands: callParticipantsThatJustRaisedHands,
                localRaisedHand: localJustRaisedHand
            )
        }
    }
    
    private func updateSnackBar(
        callParticipantsThatJustRaisedHands: [CallParticipantEntity],
        localRaisedHand: Bool
    ) {
        
        // make sure we hide snack bar immediately after ANY action is triggered
        let hideSnackBar: () -> Void = {
            snackBarUpdater(nil)
        }
        
        let snackBarModel = snackBarFactory.snackBar(
            participantsThatJustRaisedHands: callParticipantsThatJustRaisedHands,
            localRaisedHand: localRaisedHand
        )?.withSupplementalAction(hideSnackBar)
        
        snackBarUpdater(snackBarModel)
    }
}
