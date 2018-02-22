#import "NodeTableViewCell.h"
#import "MEGASdkManager.h"
#import "Helper.h"

@implementation NodeTableViewCell

- (void)awakeFromNib {
    [super awakeFromNib];
    
    if ([[UIDevice currentDevice] iPadDevice] || [[UIDevice currentDevice] iPhonePlus]) {
        self.cancelButtonTrailingConstraint.constant = 10;
    } else {
        self.cancelButtonTrailingConstraint.constant = 6;
    }
}

- (void)setEditing:(BOOL)editing animated:(BOOL)animated {
    [super setEditing:editing animated:animated];
    
    if (editing) {
        [self setSeparatorInset:UIEdgeInsetsMake(0, 100, 0, 0)];
        self.cancelButton.hidden = YES;
    } else {
        [self setSeparatorInset:UIEdgeInsetsMake(0, 60, 0, 0)];
        self.cancelButton.hidden = NO;
    }
}

- (void)hideCancelButton:(BOOL)hide {
    self.cancelButton.hidden = hide;
}

#pragma mark - Private

- (IBAction)cancelTransfer:(id)sender {
    NSNumber *transferTag = [[Helper downloadingNodes] objectForKey:[MEGASdk base64HandleForHandle:self.nodeHandle]];
    if ([[MEGASdkManager sharedMEGASdk] transferByTag:transferTag.integerValue] != nil) {
        [[MEGASdkManager sharedMEGASdk] cancelTransferByTag:transferTag.integerValue];
    } else {
        if ([[MEGASdkManager sharedMEGASdkFolder] transferByTag:transferTag.integerValue] != nil) {
            [[MEGASdkManager sharedMEGASdkFolder] cancelTransferByTag:transferTag.integerValue];
        }
    }
}

@end
