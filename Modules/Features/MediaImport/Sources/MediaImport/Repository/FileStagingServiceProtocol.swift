import Foundation

package protocol FileStagingServiceProtocol: Sendable {
    func stageFile(from sourceURL: URL, to destinationDirectory: URL) throws -> URL
}

package struct FileStagingService: FileStagingServiceProtocol {

    package init() {}

    package func stageFile(from sourceURL: URL, to destinationDirectory: URL) throws -> URL {
        try FileManager.default.createDirectory(at: destinationDirectory, withIntermediateDirectories: true)

        let destURL = uniqueDestinationURL(for: sourceURL, in: destinationDirectory)
        do {
            try FileManager.default.moveItem(at: sourceURL, to: destURL)
        } catch {
            try FileManager.default.copyItem(at: sourceURL, to: destURL)
        }

        return destURL
    }

    // MARK: - Private

    private func uniqueDestinationURL(
        for sourceURL: URL,
        in destinationDirectory: URL
    ) -> URL {
        let ext = sourceURL.pathExtension
        let formattedDate: String = {
            if let attributes = try? FileManager.default.attributesOfItem(atPath: sourceURL.path),
               let modificationDate = attributes[.modificationDate] as? Date {
                return modificationDate.formatted(
                    .verbatim(
                        "\(year: .padded(4))-\(month: .twoDigits)-\(day: .twoDigits) \(hour: .twoDigits(clock: .twentyFourHour, hourCycle: .zeroBased)).\(minute: .twoDigits).\(second: .twoDigits)",
                        timeZone: .current,
                        calendar: Calendar(identifier: .gregorian)
                    )
                )
            }
            return UUID().uuidString
        }()

        let baseName = ext.isEmpty ? formattedDate : "\(formattedDate).\(ext)"
        var candidate = destinationDirectory.appendingPathComponent(baseName)
        var counter = 1

        while FileManager.default.fileExists(atPath: candidate.path) {
            let newName = ext.isEmpty
                ? "\(formattedDate)_\(counter)"
                : "\(formattedDate)_\(counter).\(ext)"
            candidate = destinationDirectory.appendingPathComponent(newName)
            counter += 1
        }

        return candidate
    }
}
