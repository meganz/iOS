import SwiftUI

public extension View {
    @ViewBuilder
    func searchableVisible(
        text: Binding<String>,
        isPresented: Binding<Bool>,
        placement: SearchFieldPlacement = .navigationBarDrawer(displayMode: .always)
    ) -> some View {
        if isPresented.wrappedValue {
            self
                .searchable(text: text, isPresented: isPresented, placement: placement)
        } else {
            self
        }
    }
}
