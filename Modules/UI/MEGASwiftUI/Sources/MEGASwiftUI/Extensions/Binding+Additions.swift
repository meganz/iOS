import SwiftUI

public extension Binding {
    func onChange(_ handler: @Sendable @escaping (Value) -> Void) -> Binding<Value> where Value: Sendable {
        Binding(
            get: { self.wrappedValue },
            set: { newValue in
                self.wrappedValue = newValue
                handler(newValue)
            }
        )
    }
}
