import MEGADesignToken
import SwiftUI

struct CallControlView: View {
    struct Config {
        struct Colors {
            var background: Color
            var foreground: Color
        }
        var title: String
        var icon: Image
        var colors: Colors
        var action: () async -> Void = {}
    }
    
    var config: Config
    
    var body: some View {
        Button {
            Task {
                await config.action()
            }
        } label: {
            VStack(spacing: 8) {
                VStack {
                    config.icon
                        .resizable()
                        .aspectRatio(contentMode: .fit)
                        .frame(width: 24, height: 24)
                }
                .frame(maxWidth: 56, maxHeight: 56, alignment: .center)
                .background(config.colors.background)
                .clipShape(Circle())
                Text(config.title)
                    .font(.caption2)
                    .foregroundColor(config.colors.foreground)
            }
        }
    }
}

#Preview("Call control mic enabled") {
      CallControlView(config: .microphone(enabled: true) { })
}

#Preview("Call control camera enabled") {
    CallControlView(config: .camera(enabled: true) { })
}

#Preview("Call control speaker disabled") {
    CallControlView(config: .speaker(enabled: false) { })
}
