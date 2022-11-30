
import SwiftUI

struct UploadLogFileView: View {
    var title: String
    var progress: Float
    var action: () -> Void
    var body: some View {
        VStack {
            Text(title)
                .font(.body.bold())
                .padding(.top)
            
            ProgressView(value: progress, total: 1)
                .padding()
            
            Divider()
            
            Button(Strings.Localizable.cancel) {
                action()
            }
            
            .font(.body.bold())
            .accentColor(Color.primary)
            .padding()
        }
        .frame(width: 270.0)
        .background(Color(.secondarySystemBackground))
        .cornerRadius(14)
    }
}
