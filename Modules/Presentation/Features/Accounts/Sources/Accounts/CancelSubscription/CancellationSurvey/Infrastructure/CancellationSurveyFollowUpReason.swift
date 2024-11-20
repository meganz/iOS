
struct CancellationSurveyFollowUpReason: Hashable {
    enum ID: String {
        case a, b, c
    }
    
    let id: ID
    let mainReasonID: CancellationSurveyReason.ID
    let title: String
    
    init(
        id: ID,
        mainReasonID: CancellationSurveyReason.ID,
        title: String
    ) {
        self.id = id
        self.mainReasonID = mainReasonID
        self.title = title
    }
    
    var formattedID: String {
        String(mainReasonID.rawValue) + "." + id.rawValue
    }
}
