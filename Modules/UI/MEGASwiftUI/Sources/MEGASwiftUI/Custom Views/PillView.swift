import SwiftUI

public struct PillViewModel {
    public init(
        title: String,
        icon: PillView.Icon,
        foreground: Color,
        background: Color
    ) {
        self.title = title
        self.icon = icon
        self.foreground = foreground
        self.background = background
    }
    
    public let title: String
    public let icon: PillView.Icon
    public let foreground: Color
    public let background: Color
}

public struct PillView: View {
    public enum Icon {
        case leading(Image)
        case trailing(Image)
        case none
    }

    let viewModel: PillViewModel
    
    public init(viewModel: PillViewModel) {
        self.viewModel = viewModel
    }
    
    public var body: some View {
        HStack(spacing: 4) {
            if case let .leading(image) = viewModel.icon {
                image
            }
            Text(viewModel.title)
            if case let .trailing(image) = viewModel.icon {
                image
                    .resizable()
                    .scaledToFit()
                    .frame(width: 10, height: 22)
            }
        }
        .foregroundColor(viewModel.foreground)
        .padding(.horizontal, 12)
        .padding(.vertical, 6)
        .background(viewModel.background)
        .font(.system(size: 15, weight: .medium, design: .default))
        .cornerRadius(8)
    }
}

struct PillView_Previews: PreviewProvider {
    static var previews: some View {
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
        }
    }
}
