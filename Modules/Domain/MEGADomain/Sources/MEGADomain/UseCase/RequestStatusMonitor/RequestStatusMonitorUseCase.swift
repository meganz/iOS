public protocol RequestStatusMonitorUseCaseProtocol {
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

public struct RequestStatusMonitorUseCase<T: RequestStatusMonitorRepositoryProtocol>: RequestStatusMonitorUseCaseProtocol {
    
    private let repo: T
    
    public init(repo: T) {
        self.repo = repo
    }
    
    public func enableRequestStatusMonitor(_ enable: Bool) {
        repo.enableRequestStatusMonitor(enable)
    }
    
    public func isRequestStatusMonitorEnabled() -> Bool {
        repo.isRequestStatusMonitorEnabled()
    }
}

