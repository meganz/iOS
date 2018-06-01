
#import "MEGAChatMessage.h"
#import "JSQMessageData.h"

@class MEGAChatRoom;

typedef NS_ENUM(NSInteger, MEGAChatMessageWarningDialog) {
    MEGAChatMessageWarningDialogDismiss,
    MEGAChatMessageWarningDialogNone,
    MEGAChatMessageWarningDialogInitial,
    MEGAChatMessageWarningDialogStandard,
    MEGAChatMessageWarningDialogConfirmation
};

@interface MEGAChatMessage (MNZCategory) <JSQMessageData>

@property (copy, nonatomic) MEGAChatRoom *chatRoom;
@property (copy, nonatomic) NSAttributedString *attributedText;
@property (nonatomic) MEGAChatMessageWarningDialog warningDialog;
@property (copy, nonatomic) NSURL *MEGALink;
@property (copy, nonatomic) MEGANode *node;
@property (copy, nonatomic) NSString *nodeDetails;

- (BOOL)containsMEGALink;

@end
