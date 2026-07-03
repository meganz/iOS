import MEGADesignToken
import SwiftUI

/// QA-only sub-page for configuring and starting a storage / transfer over-quota event simulation.
/// Select a scenario (radio), set how many times to send and the delay before each send, then tap
/// **Start**. The run is owned by `DebugQuotaEventSimulator.shared`, so it keeps firing after this
/// page (and the whole QA settings screen) is dismissed letting us verify ODQ/OBQ appears from
/// any screen.
struct QuotaEventSimulatorView: View {

    private enum Constants {
        static let title = "Quota event simulator"
        static let scenarioHeader = "Scenario"
        static let configHeader = "Configuration"
        static let tip = "Select a scenario, set the delay, then tap Start and navigate to another screen to check ODQ/OBQ appears from anywhere. The run continues after leaving this page. Use Stop to cancel."
    }

    @State private var selectedScenario: DebugQuotaEventSimulator.Scenario?
    @State private var sendCount: Int = 1
    @State private var sendInterval: Double = 3

    var body: some View {
        List {
            Section(
                header:
                    Text(Constants.scenarioHeader)
                    .textCase(nil)
                    .foregroundStyle(TokenColors.Text.secondary.swiftUI)) {
                        ForEach(DebugQuotaEventSimulator.Scenario.allCases) { scenario in
                            Button {
                                selectedScenario = scenario
                            } label: {
                                HStack {
                                    Text(scenario.title)
                                        .foregroundStyle(TokenColors.Text.primary.swiftUI)
                                    Spacer()
                                    if selectedScenario == scenario {
                                        Image(systemName: "checkmark")
                                            .foregroundStyle(TokenColors.Support.success.swiftUI)
                                    }
                                }
                                .contentShape(Rectangle())
                            }
                        }
                    }
                    .listRowSeparatorTint(TokenColors.Border.strong.swiftUI)

            Section(
                header:
                    Text(Constants.configHeader)
                    .textCase(nil)
                    .foregroundStyle(TokenColors.Text.secondary.swiftUI)) {
                        Stepper("Send count: \(sendCount)", value: $sendCount, in: 1...50)
                        Stepper("Delay before each send: \(Int(sendInterval))s", value: $sendInterval, in: 0...60)
                    }
                    .listRowSeparatorTint(TokenColors.Border.strong.swiftUI)

            Section(
                footer:
                    Text(Constants.tip)
                    .foregroundStyle(TokenColors.Text.secondary.swiftUI)) {
                        Button("Start") {
                            guard let selectedScenario else { return }
                            DebugQuotaEventSimulator.shared.start(
                                selectedScenario,
                                count: sendCount,
                                interval: sendInterval
                            )
                        }
                        .disabled(selectedScenario == nil)

                        Button("Stop") {
                            DebugQuotaEventSimulator.shared.stop()
                        }
                        .foregroundStyle(TokenColors.Text.error.swiftUI)
                    }
                    .listRowSeparatorTint(TokenColors.Border.strong.swiftUI)
        }
        .listStyle(.grouped)
        .navigationTitle(Constants.title)
    }
}
