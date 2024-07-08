extension Array where Element == CallParticipantEntity {
    public func sortByRaiseHand(call: CallEntity?) -> [CallParticipantEntity] {
        guard let call, call.raiseHandsList.isNotEmpty else {
            return self
        }
        
        // Create a dictionary mapping each participantId to its index in the raiseHandsList
        // This will allow us to sort the participants by their raise hand order
        // For example, if call.raiseHandsList = [103, 101], becomes [103: 0, 101: 1]
        let raiseHandOrderIndexMap = Dictionary(
            uniqueKeysWithValues: call.raiseHandsList.enumerated().map { ($1, $0) }
        )

        // Sort the participants comparing their raise hand order
        let sortedParticipants = self.sorted { (participant1, participant2) -> Bool in
            let index1 = raiseHandOrderIndexMap[participant1.participantId]
            let index2 = raiseHandOrderIndexMap[participant2.participantId]
            
            switch (index1, index2) {
            case (.some(let i1), .some(let i2)):
                // Both participants has raise hand, lower order goes first
                return i1 < i2
            case (.some, .none):
                // First participant has raise hand second one has not
                return true
            case (.none, .some):
                // Second participant has raise hand first one has not
                return false
            case (.none, .none):
                // None participant has raise hand
                return false
            }
        }
        return sortedParticipants
    }
}
