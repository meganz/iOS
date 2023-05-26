import SwiftUI

struct ShareAttachmentCellView: View {
    @StateObject var viewModel: ShareAttachmentCellViewModel
    
    var body: some View {
        GeometryReader { geo in
            HStack {
                Image(viewModel.fileIconName)
                    .resizable()
                    .scaledToFit()
                    .frame(width: geo.size.height * 0.80, height: geo.size.height * 0.80)

                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 0) {
                        TextField("", text: $viewModel.fileName)
                            .font(.system(size: 15))
                            .autocorrectionDisabled()
                            .foregroundColor(Color(Colors.General.View.textForeground.color))
                            .fixedSize()
                            .onReceive(NotificationCenter.default.publisher(for: UITextField.textDidBeginEditingNotification),
                                       perform: { notif in
                                guard let field = notif.object as? UITextField else { return }
                                field.selectedTextRange = field.textRange(from: field.beginningOfDocument,
                                                                          to: field.endOfDocument)
                            })
                            .onReceive(NotificationCenter.default.publisher(for: UITextField.textDidEndEditingNotification),
                                       perform: { _ in
                                viewModel.saveNewFileName()
                            })
                        
                        Text(viewModel.fileExtension)
                            .font(.system(size: 15))
                            .foregroundColor(.gray)
                            .fixedSize()
                    }
                }
                .onAppear {
                    UIScrollView.appearance().bounces = false
                }
            }
            .frame(maxHeight: .infinity)
            .padding(.horizontal, 10)
        }
        .frame(height: 60)
        .background(Color(Colors.General.View.cellBackground.color))
    }
}
