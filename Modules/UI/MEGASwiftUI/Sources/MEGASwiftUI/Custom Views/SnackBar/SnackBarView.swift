import Combine
import MEGADesignToken
import SwiftUI

public struct SnackBarView: View {
    
    @Binding private var snackBar: SnackBar?
    private let displayDuration: TimeInterval
    @State private var restartAutoHideSubject = PassthroughSubject<Void, Never>()
    
    public init(snackBar: Binding<SnackBar?>,
                displayDuration: TimeInterval = 4) {
        self._snackBar = snackBar
        self.displayDuration = displayDuration
    }
    
    public var body: some View {
        VStack {
            if let snackBar {
                SnackBarItemView(snackBar: snackBar)
                    .throwingTask {
                        await restartAutoHideSubject
                            .prepend(()) // Kick start the timer
                            .debounce(for: .seconds(displayDuration), scheduler: DispatchQueue.main)
                            .values
                            .first(where: { _ in true })
                        
                        self.snackBar = nil
                    }
                    .onChange(of: snackBar) { _ in
                        restartAutoHideSubject.send(())
                    }
            }
        }
        .opacity(snackBar != nil ? 1 : 0)
        .animation(.easeInOut(duration: 0.5), value: snackBar)
    }
}

// MARK: - Preview

#Preview {
    VStack {
        SnackBarView(
            snackBar: .constant(
                SnackBar(
                    message: "Your hand is raised",
                    layout: .crisscross,
                    action: .init(
                        title: "Lower hand",
                        handler: {}
                    ),
                    colors: .default
                )
            )
        )
        SnackBarView(
            snackBar: .constant(
                SnackBar(
                    message: "Your hand is raised",
                    layout: .horizontal,
                    action: .init(
                        title: "Lower hand",
                        handler: {}
                    ),
                    colors: .raiseHand
                )
            )
        )
        SnackBarView(
            snackBar: .constant(
                SnackBar(
                    message: "Message",
                    layout: .crisscross,
                    action: nil,
                    colors: .default
                )
            )
        )
        SnackBarView(
            snackBar: .constant(
                SnackBar(
                    message: "Message",
                    layout: .horizontal,
                    action: nil,
                    colors: .default
                )
            )
        )
    }
}
