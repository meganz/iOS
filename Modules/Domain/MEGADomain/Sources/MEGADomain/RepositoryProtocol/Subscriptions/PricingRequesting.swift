public protocol PricingRequesting: Sendable {
    /// Starts a pricing request, or joins the one already in flight
    ///
    /// The function
    ///   * Suspends until the request complets, either by loading the products successfully or failing.
    ///   * Returns immediately once a request has completed, without suspending.
    ///
    /// What a later call does depends on how the last one ended:
    ///   * After a success, it returns straight away and no new request is made, means the loaded products are reused.
    ///   * After a failure, it starts a new request and waits for it, so a failure is always retried.
    ///   * After a `cancel()`, it starts a new request and waits for it, because the previously loaded products are gone.
    /// - Throws: `CancellationError` if the calling task is cancelled while waiting, or if `cancel()`
    ///           is called before the request finishes.
    /// - Note: Successfully loaded products are cached and reused.
    ///   Callers that need the latest products should use `refreshPricing()` instead.
    func requestPricing() async throws

    /// Forgets the last completed request and loads the products again, then waits for it like `requestPricing()`.
    /// A request already in flight is joined rather than restarted: it is loading the current products anyway.
    /// - Throws: `CancellationError` under the same conditions as `requestPricing()`.
    func refreshPricing() async throws

    /// Cancels the in-flight pricing request, if there is one, and forgets the last one, so the next
    /// `requestPricing()` starts fresh.
    ///
    /// Call this when the products being loaded, or already loaded, stop being valid, such as on logout.
    /// Everyone waiting on the cancelled request stops waiting with a `CancellationError`, and the next
    /// caller starts a new request instead of reusing what the previous one produced.
    func cancel()
}
