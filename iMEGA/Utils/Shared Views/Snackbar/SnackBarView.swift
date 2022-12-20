import SwiftUI

struct SnackBar: Equatable {
    var message: String
    var title: String?
    var action: (() -> Void)?
   
    var isActionable: Bool {
        title != nil && action != nil
    }
    
    static func == (lhs: SnackBar, rhs: SnackBar) -> Bool {
        lhs.message == rhs.message && lhs.title == rhs.title
    }
}

struct SnackBarView: View {
    @Environment(\.colorScheme) private var colorScheme
    @StateObject var viewModel: SnackBarViewModel
    
    private enum Constants {
        static let padding: CGFloat = 16
        static let spacing: CGFloat = 8
        static let cornerRadius: CGFloat = 8
    }
    
    var body: some View {
        VStack(alignment: .trailing, spacing: Constants.spacing) {
            HStack {
                Text(viewModel.snackBar.message)
                    .font(.footnote)
                    .foregroundColor(colorScheme == .light ? .white: .black)
                    .multilineTextAlignment(.leading)
                    .lineLimit(nil)
                    .padding(viewModel.snackBar.isActionable ? [.leading, .top] : [.leading, .top, .trailing, .bottom], Constants.padding)
                Spacer()
            }
            if viewModel.snackBar.isActionable {
                HStack {
                    Spacer()
                    Button(action: {
                        viewModel.snackBar.action?()
                    }) {
                        Text(viewModel.snackBar.title ?? "")
                            .font(.footnote).bold()
                            .foregroundColor(Color(Colors.General.Green._00A886.name))
                    }
                    .padding([.trailing, .bottom], Constants.padding)
                }
            }
        }
        .background(colorScheme == .light ? Color(Colors.General.Gray._3A3A3C.name) : .white)
        .cornerRadius(Constants.cornerRadius)
        .shadow(color: Color.black.opacity(0.1), radius: 4, x: 0, y: 1)
        .padding(Constants.padding)
    }
}
