import Foundation
import Yams

struct StoreMetadataConverter {
    let data: Data

    func toOutputs() throws -> [MetadataOutput] {
        let metadata = try YAMLDecoder().decode(StoreMetadata.self, from: data)
        var outputs: [MetadataOutput] = []

        if let title = metadata.title {
            outputs.append(MetadataOutput(filename: "name.txt", content: title, maxAllowedLength: 30))
        }

        if let subtitle = metadata.subtitle {
            outputs.append(MetadataOutput(filename: "subtitle.txt", content: subtitle, maxAllowedLength: 30))
        }

        if let keywords = metadata.keywords {
            outputs.append(MetadataOutput(filename: "keywords.txt", content: keywords, maxAllowedLength: 100))
        }

        if let promotionalText = metadata.promotionalText {
            outputs.append(MetadataOutput(filename: "promotional_text.txt", content: promotionalText, maxAllowedLength: 170))
        }

        let descriptionText = try metadata.formattedString
        outputs.append(MetadataOutput(filename: "description.txt", content: descriptionText, maxAllowedLength: 4000))

        return outputs
    }
}
