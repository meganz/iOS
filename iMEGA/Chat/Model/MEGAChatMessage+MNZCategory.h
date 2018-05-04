
#import "MEGAChatMessage.h"
#import "JSQMessageData.h"

@class MEGAChatRoom;

typedef NS_ENUM(NSInteger, MEGAChatMessageWarningDialog) {
    MEGAChatMessageWarningDialogDismiss,
    MEGAChatMessageWarningDialogNone,
    MEGAChatMessageWarningDialogInitial,
    MEGAChatMessageWarningDialogStandard
};

@interface MEGAChatMessage (MNZCategory) <JSQMessageData>

@property (copy, nonatomic) MEGAChatRoom *chatRoom;
@property (copy, nonatomic) NSAttributedString *attributedText;
@property (nonatomic) MEGAChatMessageWarningDialog warningDialog;

@end
