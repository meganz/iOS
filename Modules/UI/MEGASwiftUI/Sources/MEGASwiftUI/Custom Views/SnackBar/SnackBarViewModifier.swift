import Foundation
import SwiftUI

extension View {
    
    /// Attaches an overlay container to present SnackBar Messages to your attached UI.
    /// - Parameters:
    ///   - snackBar: SnackBar Binding to show and remove snack bar item. When the snack auto disappears the binding will be set to nil.
    ///   - displayDuration: Duration in seconds for the Snack to remain visible before auto removal
    /// - Returns: A modified view that will attach an overlay with snack bare presentation logic embedded.
    public func snackBar(_ snackBar: Binding<SnackBar?>, displayDuration: TimeInterval = 4) -> some View {
        modifier(SnackBarViewModifier(snackBar: snackBar, displayDuration: displayDuration))
    }
}

struct SnackBarViewModifier: ViewModifier {
    
    @Binding var snackBar: SnackBar?
    let displayDuration: TimeInterval
        
    public func body(content: Content) -> some View {
        content
            .overlay(alignment: .bottom) {
                SnackBarView(
                    snackBar: $snackBar,
                    displayDuration: displayDuration)
            }
    }
}

#Preview {
    VStack { }
    .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .bottom)
    .snackBar(.constant(SnackBar(message: "MEGA has Arrived")))
}
