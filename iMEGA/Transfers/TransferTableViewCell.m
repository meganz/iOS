/**
 * @file TransferTableViewCell.m
 * @brief Custom table view cell for transfers.
 *
 * (c) 2013-2015 by Mega Limited, Auckland, New Zealand
 *
 * This file is part of the MEGA SDK - Client Access Engine.
 *
 * Applications using the MEGA API must present a valid application key
 * and comply with the the rules set forth in the Terms of Service.
 *
 * The MEGA SDK is distributed in the hope that it will be useful,
 * but WITHOUT ANY WARRANTY; without even the implied warranty of
 * MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.
 *
 * @copyright Simplified (2-clause) BSD License.
 *
 * You should have received a copy of the license along with this
 * program.
 */

#import "TransferTableViewCell.h"
#import "MEGASdkManager.h"
#import "Helper.h"

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
