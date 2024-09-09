import Combine
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
    
    @State private var initialAppearance = false
    @State private var restartAutoHideSubject = PassthroughSubject<Void, Never>()
    
    public func body(content: Content) -> some View {
        content
            .overlay(alignment: .bottom) {
                VStack {
                    if initialAppearance, let snackBar {
                        SnackBarItemView(snackBar: snackBar)
                            .throwingTask {
                                
                                defer { self.snackBar = nil }
                                
                                for await _ in restartAutoHideSubject
                                    .prepend(()) // Kick start the timer
                                    .debounce(for: .seconds(displayDuration), scheduler: DispatchQueue.main)
                                    .values {
                                    
                                    try Task.checkCancellation()
                                    
                                    self.snackBar = nil
                                }
                            }
                            .onChange(of: snackBar) { _ in
                                restartAutoHideSubject.send(())
                            }
                    }
                }
                .opacity(snackBar != nil ? 1 : 0)
                .animation(.easeInOut(duration: 0.5), value: snackBar)
                .onAppear {
                    if snackBar != nil {
                        // Delay the animation transition
                        DispatchQueue.main.asyncAfter(deadline: .now()) {
                            initialAppearance = true
                        }
                    } else {
                        initialAppearance = true
                    }
                }
            }
    }
}

#Preview {
    VStack {
        
    }
    .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .bottom)
    .snackBar(.constant(SnackBar(message: "MEGA has Arrived")))
}
