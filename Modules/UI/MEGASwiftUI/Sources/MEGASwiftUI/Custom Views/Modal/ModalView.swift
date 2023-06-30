import SwiftUI

struct ModalViewModifier<V: View>: ViewModifier {
    let isPresented: Binding<Bool>
    let modalView: () -> V

    @ViewBuilder
    func body(content: Content) -> some View {
        if #available(iOS 15.0, *) {
            content
                .sheet(isPresented: isPresented, content: modalView)
        } else {
            content
                .fullScreenCover(isPresented: isPresented, content: modalView)
        }
    }
}

public extension View {
    func modalView<Content: View>(isPresented: Binding<Bool>, @ViewBuilder content: @escaping () -> Content) -> some View {
        self.modifier(ModalViewModifier(isPresented: isPresented, modalView: content))
    }
}
