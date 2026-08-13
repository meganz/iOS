import CloudDrive
import Testing

@Suite("FloatingActionEntity requiresConnection Tests")
struct FloatingActionEntityRequiresConnectionTests {
    @Test("Every floating add action needs a connection")
    func allActionsRequireConnection() {
        // Hoisted out of `#expect`: the macro expansion treats `allSatisfy`'s `rethrows` as
        // throwing, which the expansion is not allowed to do
        let allRequireConnection = FloatingActionEntity.allCases.allSatisfy(\.requiresConnection)

        #expect(allRequireConnection)
    }
}
