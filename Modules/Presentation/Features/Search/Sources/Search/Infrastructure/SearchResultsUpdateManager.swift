import Foundation

struct SearchResultsUpdateManager {
    enum Result {
        case none
        case generic
        case specificUpdateResults([SearchResult])
    }

    private let signals: [SearchResultUpdateSignal]

    init(signals: [SearchResultUpdateSignal]) {
        self.signals = signals
    }

    // MARK: - Interface

    func processSignals() -> Result {
        guard signals.isNotEmpty else { return .none }

        if containsGenericSignal(in: signals) {
            return .generic
        } else {
            let results = extractedSpecificUpdateResults(from: signals)
            return .specificUpdateResults(results)
        }
    }

    // MARK: - Helpers

    private func containsGenericSignal(in signals: [SearchResultUpdateSignal]) -> Bool {
        signals.contains { signal in
            guard case .generic = signal else {
                return false
            }

            return true
        }
    }

    private func extractedSpecificUpdateResults(from signals: [SearchResultUpdateSignal]) -> [SearchResult] {
        signals.compactMap { signal in
            guard case .specific(let result) = signal else {
                return nil
            }

            return result
        }
    }
}
