import MEGASdk

@objc protocol QAQuotaEventSimulating {
    func qaSimulateStorageEvent(_ event: MEGAEvent)
}
