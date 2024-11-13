public protocol RequestStatusMonitorRepositoryProtocol: RepositoryProtocol {
    /// Enable or disable the request status monitor
    ///
    /// - Note: When it's enabled, the request status monitor generates events of type
    /// `EventReqStatProgress` with the per mille progress in
    /// the field [MEGAEvent number], or -1 if there isn't any operation in progress.
    ///
    /// - Parameters:
    ///    - enable: true to enable the request status monitor, or false to disable it
    func enableRequestStatusMonitor(_ enable: Bool)
    
    /// Get the status of the request status monitor
    /// - Returns: true when the request status monitor is enabled, or false if it's disabled
    func isRequestStatusMonitorEnabled() -> Bool
}
