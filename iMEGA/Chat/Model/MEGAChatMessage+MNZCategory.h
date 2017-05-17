
#import "MEGAChatMessage.h"
#import "JSQMessageData.h"

@class MEGAChatRoom;

@interface MEGAChatMessage (MNZCategory) <JSQMessageData>

@property (copy, nonatomic) MEGAChatRoom *chatRoom;
@property (copy, nonatomic) NSAttributedString *attributedText;

@end
