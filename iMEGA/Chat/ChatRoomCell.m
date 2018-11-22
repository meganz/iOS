#import "ChatRoomCell.h"

@implementation ChatRoomCell

- (void)awakeFromNib {
    [super awakeFromNib];
    
    if (@available(iOS 10.0, *)) {
        self.chatTitle.adjustsFontForContentSizeCategory = YES;
        self.chatLastMessage.adjustsFontForContentSizeCategory = YES;
        self.chatLastTime.adjustsFontForContentSizeCategory = YES;
        self.unreadCount.adjustsFontForContentSizeCategory = YES;
    }
}

- (void)setSelected:(BOOL)selected animated:(BOOL)animated {
    UIColor *color = self.onlineStatusView.backgroundColor;
    [super setSelected:selected animated:animated];
    
    if (selected){
        self.onlineStatusView.backgroundColor = color;
    }
}

-(void)setHighlighted:(BOOL)highlighted animated:(BOOL)animated{
    UIColor *color = self.onlineStatusView.backgroundColor;
    [super setHighlighted:highlighted animated:animated];
    
    if (highlighted){
        self.onlineStatusView.backgroundColor = color;
    }
}

@end
