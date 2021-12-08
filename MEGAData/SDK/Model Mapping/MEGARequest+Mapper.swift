import SwiftUI

extension MEGARequest {
    func toPSAEntity() -> PSAEntity {
        PSAEntity(
            identifier: number.intValue,
            title: name,
            description: text,
            imageURL: file,
            positiveText: password,
            positiveLink: link,
            URLString: email
        )
    }
    
    func toFileURL() -> URL? {
        guard let path = file else {
            return nil
        }
        
        return URL(string: path)
    }
}
