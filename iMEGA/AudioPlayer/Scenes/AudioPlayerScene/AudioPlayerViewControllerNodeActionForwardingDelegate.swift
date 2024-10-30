import MEGADomain

/// A protocol that forwards node action selection from `NodeActionViewController` to an audio player view.
protocol AudioPlayerViewControllerNodeActionForwardingDelegate {
    
    /// Delegate function forwarding node action selection.
    /// - Parameter NodeActionTypeEntity: selected node action forwarding from `NodeActionViewController`
    func didSelectNodeActionTypeMenu(_ nodeActionTypeEntity: NodeActionTypeEntity)
}
