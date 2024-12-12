import SwiftUI

/// A ViewModifier that provides an adaptive presentation style which presents a destination view differently based on the device's horizontal size class
private struct AdaptiveSheetModalViewModifier<T: View>: ViewModifier {
    @Environment(\.horizontalSizeClass) var horizontalSizeClass
    @Binding var isPresented: Bool
    let destination: () -> T
    
    @ViewBuilder
    public func body(content: Content) -> some View {
        if horizontalSizeClass == .compact {
            content
                .fullScreenCover(isPresented: $isPresented, content: destination)
        } else {
            content
                .sheet(isPresented: $isPresented, content: destination)
        }
    }
}

public extension View {
    /// Adds a presentation style that adapts based on the device's horizontal size class:
    /// - Displays the destination view as a fullScreen cover when the size class is `.compact` (e.g., on iPhones).
    /// - Displays the destination view as a modal sheet when the size class is `.regular` (e.g., on iPads).
    ///
    /// - Parameter isPresented: A binding that determines whether to present or dismiss the destination view.
    /// - Parameter destination: A closure that provides the view to be presented.
    /// - Returns: A modified view that presents the destination as a fullScreen cover or a sheet, depending on the size class.
    func adaptiveSheetModal(
        isPresented: Binding<Bool>,
        destination: @escaping () -> some View
    ) -> some View {
        modifier(
            AdaptiveSheetModalViewModifier(
                isPresented: isPresented,
                destination: destination
            )
        )
    }
}
