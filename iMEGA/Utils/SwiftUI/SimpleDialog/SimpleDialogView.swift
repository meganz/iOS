import MEGADesignToken
import SwiftUI

struct SimpleDialogConfig {
    let imageResource: ImageResource
    let title: String
    let message: String
    let buttonTitle: String
    let buttonAction: () -> Void
}

/// This view is intended to show a dialog to the user.
/// Can be wrapped in a UIKit view or used in SwiftUI directly.
/// It contains  image, title, description and  button for an action.
struct SimpleDialogView: View {
    @Environment(\.colorScheme) private var colorScheme
    let dialogConfig: SimpleDialogConfig

    init(dialogConfig: SimpleDialogConfig) {
        self.dialogConfig = dialogConfig
    }
    
    var body: some View {
        VStack(spacing: 20) {
            Image(dialogConfig.imageResource)
                .resizable()
                .frame(width: 90, height: 90)
            Text(dialogConfig.title)
                .font(.callout)
                .foregroundStyle(TokenColors.Text.primary.swiftUI)
            Text(dialogConfig.message)
                .multilineTextAlignment(.center)
                .font(.subheadline)
                .foregroundStyle(TokenColors.Text.secondary.swiftUI)
            Button {
                dialogConfig.buttonAction()
            } label: {
                Text(dialogConfig.buttonTitle)
                    .frame(maxWidth: 288)
                    .frame(height: 50)
                    .background(TokenColors.Icon.accent.swiftUI)
                    .foregroundStyle(TokenColors.Text.inverseAccent.swiftUI)
                    .cornerRadius(10)
                    .font(.headline)
            }
        }
        .padding(30)
        .background(TokenColors.Background.page.swiftUI)
    }
}

#Preview {
    let dialogConfig = SimpleDialogConfig(
        imageResource: .upgradeToProPlan,
        title: "Dialog title",
        message: "Fancy dialog message",
        buttonTitle: "Button action title"
    ) { }
    
    return VStack {
        SimpleDialogView(dialogConfig: dialogConfig)
            .colorScheme(.light)
        
        SimpleDialogView(dialogConfig: dialogConfig)
            .colorScheme(.dark)
    }
}
