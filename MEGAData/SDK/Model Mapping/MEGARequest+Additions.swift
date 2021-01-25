
extension MEGARequest {
    var toPSAEntity: PSAEntity {
        return PSAEntity(
            identifier: number.intValue,
            title: name,
            description: text,
            imageURL: file,
            positiveText: password,
            positiveLink: link,
            URLString: email
        )
    }
}
