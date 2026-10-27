/// Lets tasks already waiting on the main actor run before the caller goes on.
@MainActor
func settle() async {
    for _ in 0..<20 {
        await Task.yield()
    }
}
