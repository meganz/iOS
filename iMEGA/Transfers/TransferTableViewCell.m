#import "TransferTableViewCell.h"
#import "MEGASdkManager.h"

@implementation TransferTableViewCell

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
