import MEGADesignToken
import SwiftUI

public struct PillViewModel {
    public let title: String
    public let icon: PillView.Icon
    public let foreground: Color
    public let background: Color
    public let font: Font
    public let shape: PillView.Shape

    public init(
        title: String,
        icon: PillView.Icon,
        foreground: Color,
        background: Color,
        font: Font = .system(size: 15, weight: .medium, design: .default),
        shape: PillView.Shape = .rectangle
    ) {
        self.title = title
        self.icon = icon
        self.foreground = foreground
        self.background = background
        self.font = font
        self.shape = shape
    }
}

public struct PillView: View {
    public enum Icon {
        case leading(Image)
        case trailing(Image)
        case none
    }
    
    public enum Shape {
        case rectangle
        case capsule
    }

    let viewModel: PillViewModel
    
    public init(viewModel: PillViewModel) {
        self.viewModel = viewModel
    }
    
    public var body: some View {
        contentView
            .foregroundStyle(viewModel.foreground)
            .padding(
                EdgeInsets(
                    top: TokenSpacing._3,
                    leading: TokenSpacing._4,
                    bottom: TokenSpacing._3,
                    trailing: TokenSpacing._4
                )
            )
            .background(viewModel.background)
            .font(viewModel.font)
            .mask(viewModel.shape == .rectangle ? AnyView(Rectangle()) : AnyView(Capsule()))
            .cornerRadius(TokenRadius.medium)
    }

    // Using if condition inside the HStack seem to create an issue with geometry reader when added to the background of the view. Always returns 0 for some unknown reason.
    private var contentView: some View {
        Group {
            switch viewModel.icon {
            case .none:
                Text(viewModel.title)
            case .leading(let image):
                HStack(spacing: TokenSpacing._2) {
                    image
                    Text(viewModel.title)
                }
            case .trailing(let image):
                HStack(spacing: TokenSpacing._2) {
                    Text(viewModel.title)
                    image
                        .resizable()
                        .scaledToFit()
                        .frame(width: 10, height: 22)
                }
            }
        }
    }
}

#Preview {
    VStack {
        HStack {
            PillView(
                viewModel: .init(
                    title: "Videos",
                    icon: .trailing(Image(systemName: "checkmark")),
                    foreground: .white,
                    background: Color(red: 64.0/255.0, green: 155.0/255.0, blue: 125.0/255.0)
                )
            )
            PillView(
                viewModel: .init(
                    title: "Videos",
                    icon: .trailing(Image(systemName: "checkmark")),
                    foreground: .white,
                    background: Color(red: 64.0/255.0, green: 155.0/255.0, blue: 125.0/255.0)
                )
            )
        }
        HStack {
            PillView(
                viewModel: .init(
                    title: "Images",
                    icon: .trailing(Image(systemName: "checkmark")),
                    foreground: Color(red: 76.0/255.0, green: 76.0/255.0, blue: 76.0/255.0),
                    background: Color(red: 233.0/255.0, green: 233.0/255.0, blue: 233.0/255.0)
                )
            )
            PillView(
                viewModel: .init(
                    title: "GIFs",
                    icon: .trailing(Image(systemName: "checkmark")),
                    foreground: Color(red: 76.0/255.0, green: 76.0/255.0, blue: 76.0/255.0),
                    background: Color(red: 233.0/255.0, green: 233.0/255.0, blue: 233.0/255.0)
                )
            )
        }
        HStack {
            PillView(
                viewModel: .init(
                    title: "Play",
                    icon: .leading(Image(systemName: "play.fill")),
                    foreground: .white,
                    background: Color(red: 64.0/255.0, green: 155.0/255.0, blue: 125.0/255.0),
                    shape: .capsule
                )
            )
            PillView(
                viewModel: .init(
                    title: "Play",
                    icon: .leading(Image(systemName: "play.fill")),
                    foreground: Color(red: 76.0/255.0, green: 76.0/255.0, blue: 76.0/255.0),
                    background: Color(red: 233.0/255.0, green: 233.0/255.0, blue: 233.0/255.0),
                    shape: .capsule
                )
            )
        }
    }
}
