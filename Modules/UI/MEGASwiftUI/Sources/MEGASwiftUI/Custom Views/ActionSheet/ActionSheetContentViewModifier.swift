import SwiftUI

/// A view modifier that presents an action sheet with customizable content and presentation style.
///
/// Actions are executed after the sheet is dismissed to ensure proper UI state management.
struct ActionSheetContentViewModifier<HeaderView: View>: ViewModifier {
    @Binding var isPresented: Bool
    let actionSheetButtonViewModels: [ActionSheetButtonViewModel]
    let sheetHeight: CGFloat
    let headerView: HeaderView
    @State private var pendingAction: (() -> Void)?
    
    func body(content: Content) -> some View {
        content
            .sheet(isPresented: $isPresented, onDismiss: {
                pendingAction?()
                pendingAction = nil
            }, content: {
                bottomView()
            })
    }
    
    @ViewBuilder
    private func bottomView() -> some View {
        if #available(iOS 16.4, *) {
            bottomSheetView()
                .presentationCornerRadius(16)
        } else {
            bottomSheetView()
        }
    }
    
    private func bottomSheetView() -> some View {
        ActionSheetContentView(
            style: .plainIgnoreHeaderIgnoreScrolling,
            headerView: headerView,
            actionSheetButtonViewModels: actionSheetButtonViewModels,
        ) {
            pendingAction = $0
        }
        .presentationDetents([ .height(sheetHeight) ])
        .presentationDragIndicator(.hidden)
    }
}

public extension View {
    /// Presents an action sheet with the specified configuration
    ///
    /// Selected actions are executed after the sheet is dismissed to ensure proper UI state transitions.
    ///
    /// - Parameters:
    ///   - isPresented: A binding that controls the presentation of the sheet
    ///   - actionSheetButtonViewModels: An array of button view models that define the available actions
    ///   - sheetHeight: The height of the presented sheet
    /// - Returns: A view with the sheet presentation modifier applied
    func sheet(
        isPresented: Binding<Bool>,
        actionSheetButtonViewModels: [ActionSheetButtonViewModel],
        sheetHeight: CGFloat,
    ) -> some View {
        modifier(
            ActionSheetContentViewModifier(
                isPresented: isPresented,
                actionSheetButtonViewModels: actionSheetButtonViewModels,
                sheetHeight: sheetHeight,
                headerView: EmptyView())
        )
    }
}
