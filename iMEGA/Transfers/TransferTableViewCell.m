#import "TransferTableViewCell.h"
#import "MEGASdkManager.h"

@implementation TransferTableViewCell

- (void)setSelected:(BOOL)selected animated:(BOOL)animated {
    [super setSelected:selected animated:animated];
    
    if (selected) {
        UIView *view = [[UIView alloc] init];
        view.backgroundColor = [UIColor whiteColor];
        self.selectedBackgroundView = view;
        
        self.lineView.backgroundColor = [UIColor mnz_grayCCCCCC];
    }
}

- (void)setHighlighted:(BOOL)highlighted animated:(BOOL)animated {
    [super setHighlighted:highlighted animated:animated];
    
    if (highlighted) {
        UIView *view = [[UIView alloc] init];
        view.backgroundColor = [UIColor mnz_grayF7F7F7];
        self.selectedBackgroundView = view;
        
        self.lineView.backgroundColor = [UIColor mnz_grayCCCCCC];
    }
}

#pragma mark - IBActions

- (IBAction)cancelTransfer:(id)sender {
    if ([[MEGASdkManager sharedMEGASdk] transferByTag:self.transferTag] != nil) {
        [[MEGASdkManager sharedMEGASdk] cancelTransferByTag:self.transferTag];
    } else {
        if ([[MEGASdkManager sharedMEGASdkFolder] transferByTag:self.transferTag] != nil) {
            [[MEGASdkManager sharedMEGASdkFolder] cancelTransferByTag:self.transferTag];
        }
    }
}

@end
