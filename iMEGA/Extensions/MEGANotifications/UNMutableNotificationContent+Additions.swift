
extension UNMutableNotificationContent {
   private enum NotificationType: Int {
       case startScheduleMeeting = 7
   }
   
   var isStartScheduledMeetingNotification: Bool {
       userInfo["megatype"] as? Int == NotificationType.startScheduleMeeting.rawValue
   }
}
