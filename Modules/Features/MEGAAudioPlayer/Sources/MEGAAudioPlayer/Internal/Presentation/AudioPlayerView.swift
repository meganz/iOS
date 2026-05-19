import MEGAAssets
import MEGADesignToken
import MEGASwiftUI
import SwiftUI
import UIKit

struct AudioPlayerView: View {
    @ObservedObject var vm: AudioPlayerViewModel

    var body: some View {
        ZStack {
        }
        .toolbar {
            ToolbarItem(placement: .topBarLeading) {
                Button {
                    vm.dismiss()
                } label: {
                    Image(systemName: "chevron.down")
                }
            }
            ToolbarItem(placement: .topBarTrailing) {
                if !vm.isActionsMenuHidden {
                    Button {
                        vm.didTapMore()
                    } label: {
                        Image(systemName: "ellipsis")
                    }
                }
            }
        }
        .preferredColorScheme(.dark)
    }
}

// MARK: - Preview

#Preview("Music — Playing") {
    AudioPlayerView(vm: {
        let vm = AudioPlayerViewModel()
        return vm
    }())
}
