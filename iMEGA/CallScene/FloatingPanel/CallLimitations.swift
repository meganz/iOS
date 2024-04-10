import Combine
import MEGADomain
import MEGAPresentation

/// This class is responsible for checking and monitoring the limitations of the free tier users in a call.
/// Note: we currently show limitations info for organisers and hosts
/// This logic had to be reused in few places:
///  * MeetingFloatingPanelViewModel
///  * WaitingRoomParticipantsListViewModel
///
/// so it was refactored out without copying the logic of checking multiple conditions.
/// With this logic extracted, it can be unit tested with ease without mocking dependencies of multiple view models.
///
/// Use `hasReachedInCallFreeUserParticipantLimit` to check all conditions are met:
///  * feature of chat monetisation is enabled
///  * user is moderator
///  * limit of call participants is achieved
///
/// To respond to conditions above changing subscribe to limitsChangedPublisher so that
/// UI can be dynamically reloaded.
/// related story: [MEET-3421]
class CallLimitations {
    private let callUseCase: any CallUseCaseProtocol
    // users can be upgraded to moderator/host or degraded so we need to check
    // that dynamically via observing chat rooms own priviledge
    private let chatRoomUseCase: any ChatRoomUseCaseProtocol

    private let featureFlagProvider: any FeatureFlagProviderProtocol
    private let _limitsChanged = PassthroughSubject<Void, Never>()
    
    /// will be sent whenever call has changed the callLimits.maxUsers property
    /// or user becomes or stops being a moderator/host
    var limitsChangedPublisher: AnyPublisher<Void, Never> {
        _limitsChanged.eraseToAnyPublisher()
    }
    
    private var subscriptions = Set<AnyCancellable>()
    // the limit 100 means 99 users can join plus the organiser
    // this will be fetched from SDK to get the current value
    // we also listen to notifications when this changes
    private var limitOfFreeTierUsers: Int = 100
    
    private var chatMonetisationEnabled: Bool {
        featureFlagProvider.isFeatureFlagEnabled(for: .chatMonetization)
    }
    
    private var isMyselfModerator: Bool
    private let chatRoom: ChatRoomEntity
    
    init(
        initialLimit: Int,
        chatRoom: ChatRoomEntity,
        callUseCase: some CallUseCaseProtocol,
        chatRoomUseCase: some ChatRoomUseCaseProtocol,
        featureFlagProvider: some FeatureFlagProviderProtocol
    ) {
        self.limitOfFreeTierUsers = initialLimit
        self.callUseCase = callUseCase
        self.chatRoomUseCase = chatRoomUseCase
        self.featureFlagProvider = featureFlagProvider
        isMyselfModerator = chatRoom.ownPrivilege == .moderator
        self.chatRoom = chatRoom
        
        // Subscription used to listen to changes
        // of call limits, we dynamically show and hide
        // limitations banner based on that limit:
        // * meeting floating panel
        // * expanded waiting room list
        //   * button to show is only shown at the bottom of meeting floating panel,
        //     after we reach more than 4 users in the waiting room)
        // * contact picker when inviting participants to a call
        // [MEET-3421] [MEET-3401]
        
        // Subscription also used to listen to changes
        // of number of call participants
        // limits banner in the contactsViewController
        // need to be dynamically shown/hidden when we are hitting the limit
        // [MEET-3401]
        callUseCase.onCallUpdate()
            .receive(on: DispatchQueue.main)
            .sink { [weak self] call in
                self?.onCallUpdate(call)
            }
            .store(in: &subscriptions)
        
        // Subscription is used to listen when
        // user has been added or removed a host privilege.
        // This is relevant as we show limitations banners when user
        // has this privilege, so we need to react when he's striped or decorated with it
        // [MEET-3421]
        chatRoomUseCase.ownPrivilegeChanged(forChatRoom: chatRoom)
            .receive(on: DispatchQueue.main)
            .sink { [weak self] _ in
                self?.ownPrivilegeChanged()
            }
            .store(in: &subscriptions)
    }
    
    private func ownPrivilegeChanged() {
        if let chatRoom = chatRoomUseCase.chatRoom(forChatId: chatRoom.chatId) {
            let previousValue = isMyselfModerator
            isMyselfModerator = chatRoom.ownPrivilege == .moderator
            if isMyselfModerator != previousValue {
                MEGALogDebug("[CallLimitations] did change privilege host: \(chatRoom.ownPrivilege == .moderator)")
                _limitsChanged.send(())
            }
        }
    }
    
    private func onCallUpdate(_ call: CallEntity) {
        switch call.changeType {
        case .callLimitsUpdated:
            let previousLimit = limitOfFreeTierUsers
            limitOfFreeTierUsers = call.callLimits.maxUsers
            if previousLimit != limitOfFreeTierUsers {
                MEGALogDebug("[CallLimitations] did change limits to \(limitOfFreeTierUsers) from previous \(previousLimit)")
                _limitsChanged.send(())
            }
        case .callComposition:
            MEGALogDebug("[CallLimitations] call composition changed)")
            _limitsChanged.send(())
        default:
            break
        }
    }
    
    private var participantsNumberLimitationsEnabled: Bool {
        return Self.participantsNumberLimitationsEnabled(
            featureFlagEnabled: chatMonetisationEnabled,
            isMyselfModerator: isMyselfModerator,
            currentLimit: limitOfFreeTierUsers
        )
    }
    
    func hasReachedInCallFreeUserParticipantLimit(callParticipantCount: Int) -> Bool {
        return callLimitReached(callParticipantCount)
    }
    
    private func callLimitReached(
        _ callParticipantCount: Int
    ) -> Bool {
        Self.callParticipantsLimitReached(
            featureFlagEnabled: chatMonetisationEnabled,
            isMyselfModerator: isMyselfModerator,
            currentLimit: limitOfFreeTierUsers,
            callParticipantCount: callParticipantCount
        )
    }
    
    private func callLimitWillBeReached(
        _ callParticipantCount: Int,
        afterAdding additionalParticipantCount: Int
    ) -> Bool {
        Self.callParticipantsLimitReached(
            featureFlagEnabled: chatMonetisationEnabled,
            isMyselfModerator: isMyselfModerator,
            currentLimit: limitOfFreeTierUsers,
            callParticipantCount: callParticipantCount,
            additionalParticipantCount: additionalParticipantCount
        )
    }
    
    static func participantsNumberLimitationsEnabled(
        featureFlagEnabled: Bool,
        isMyselfModerator: Bool,
        currentLimit: Int
    ) -> Bool {
        guard featureFlagEnabled else { return false }
        guard isMyselfModerator else { return false }
        // -1 means no limit
        return currentLimit != CallLimitsEntity.noLimits
    }
    
    // Extracted this function to a static function to enable reuse exactly the same logic
    // in places [MainTabBarCallsViewModel.swift] where it doesn't make sense to observe and keep state of current limit, as
    // there are pipelines observing and all data to compute the result already in place.
    //
    // By extracting the logic both this class and other components guarantee running the same code,
    // to make a decision using exactly the same set of parameters.
    //
    // Reason a static method is used here, is to :
    //   * make sure there's no implicit state used to make decision
    //   * can be safely called from the outside with the same set of parameters
    // It's crucial to keep this logic in sync to trigger it under the same conditions.
    static func callParticipantsLimitReached(
        featureFlagEnabled: Bool,
        isMyselfModerator: Bool,
        currentLimit: Int,
        callParticipantCount: Int,
        additionalParticipantCount: Int = 0
    ) -> Bool {
        MEGALogDebug("[CallLimitations] check limits call participants \(callParticipantCount), FF: \(featureFlagEnabled), host: \(isMyselfModerator), limit: \(currentLimit)")
        
        let shouldActuallyCheckLimits = participantsNumberLimitationsEnabled(
            featureFlagEnabled: featureFlagEnabled,
            isMyselfModerator: isMyselfModerator,
            currentLimit: currentLimit
        )
        
        guard shouldActuallyCheckLimits else { return false }
        // We do a check with non-zero additionalParticipantCount
        // when:
        // * selecting participants to add to a cal from the contact picker
        // * disabling `Admit all` button in the floating panel in the call UI
        // For other cases `additionalParticipantCount` is 0 so we juts check if we are at,
        // or exceeding the limit
        return additionalParticipantCount + callParticipantCount >= currentLimit
    }
    
    func hasReachedInCallPlusWaitingRoomFreeUserParticipantLimit(
        callParticipantCount: Int,
        callParticipantsInWaitingRoom: Int
    ) -> Bool {
        callLimitWillBeReached(callParticipantCount, afterAdding: callParticipantsInWaitingRoom)
    }
    
    /// this function contains logic of showing the limitations banner in the contact picker
    /// for  a user with permission to add participants, all conditions need to be satisfied:
    /// * feature flags needs to be enabled
    /// * max user limit must not be -1
    /// * user has to have permission to invite (allowsNonHostToInvite)
    /// * sum of selected users and call participants must be greater than the limit
    func contactPickerLimitChecker(
        callParticipantCount: Int,
        selectedCount: Int,
        allowsNonHostToInvite: Bool
    ) -> Bool {
        MEGALogDebug("[CallLimitations] contact picker limit checker participants = \(callParticipantCount), selected: \(selectedCount), allowsNonHostToInvite: \(allowsNonHostToInvite)")
        return Self.callParticipantsLimitReached(
            featureFlagEnabled: chatMonetisationEnabled,
            // from the logic of contact picker and showing the banner,
            // once chat room has `allowsNonHostToInvite` his behaviour is the same as moderator
            isMyselfModerator: allowsNonHostToInvite,
            currentLimit: limitOfFreeTierUsers,
            callParticipantCount: callParticipantCount,
            additionalParticipantCount: selectedCount
        )
    }
}
