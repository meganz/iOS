import KMTransferUtils
import MEGAAppPresentation
import MEGAUIComponent
import SwiftUI

public struct KMTransferQASettingsView: View {
    @State private var kmQueryConfigs: [KMQueryConfig]?
    @State private var isLoading: Bool = true

    private let kmTransferUtils: any KMTransferring

    public init(kmTransferUtils: some KMTransferring) {
        self.kmTransferUtils = kmTransferUtils
    }

    public var body: some View {
        content
            .task {
                getDataFromTransferFile()
                isLoading = false
            }
    }

    @ViewBuilder
    private var content: some View {
        if isLoading {
            ProgressView()
        } else {
            ScrollView {
                if let kmQueryConfigs {
                    if !kmQueryConfigs.isEmpty {
                        VStack(spacing: 30) {
                            Text("All the KM items in transfer file")
                                .bold()
                            Text("Format: service + account + group (optional)")
                            VStack(spacing: 8) {
                                ForEach(kmQueryConfigs, id: \.self) { kmQueryConfig in
                                    kmQueryRow(kmQueryConfig: kmQueryConfig)
                                }
                            }

                            deleteTransferFileButton
                        }
                        .padding(.horizontal, 16)
                    } else {
                        VStack(spacing: 30) {
                            Text("There are no KM items in transfer file")
                                .bold()
                            deleteTransferFileButton
                        }
                        .padding(.horizontal, 16)
                    }
                } else {
                    VStack(spacing: 30) {
                        Text("There are no KM transfer file")
                            .bold()
                        createTransferFileButton
                    }
                    .padding(.horizontal, 16)
                }
            }
        }
    }

    private func kmQueryRow(kmQueryConfig: KMQueryConfig) -> some View {
        HStack(spacing: .zero) {
            VStack(alignment: .leading, spacing: .zero) {
                HStack(spacing: 20) {
                    Text(kmQueryConfig.service)
                        .font(.callout)
                    Text(kmQueryConfig.account)
                        .font(.callout)
                        .bold()
                }
                if let group = kmQueryConfig.group {
                    Text(group)
                        .font(.callout)
                }
            }
            Spacer()
            Text("✅")
        }
    }

    private var deleteTransferFileButton: some View {
        MEGAButton("Delete KM transfer file") {
            do {
                try kmTransferUtils.deleteTransferFile()
                kmQueryConfigs = nil
            } catch {}
        }
    }

    private var createTransferFileButton: some View {
        MEGAButton("Create KM transfer file") {
            Task { @MainActor [kmTransferUtils] in
                isLoading = true
                try? await kmTransferUtils.createTransferFile()
                getDataFromTransferFile()
                isLoading = false
            }
        }
    }

    @MainActor func getDataFromTransferFile() {
        kmQueryConfigs = try? kmTransferUtils.getDataFromTransferFile()
    }
}
