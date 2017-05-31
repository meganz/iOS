//
//  FileProvider.h
//  MEGAPickerFileProvider
//
//  Created by Javier Trujillo on 29/5/17.
//  Copyright © 2017 MEGA. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "MEGATransferDelegate.h"
#import "MEGARequestDelegate.h"

@interface FileProvider : NSFileProviderExtension <MEGATransferDelegate, MEGARequestDelegate>

@property (nonatomic) MEGANode *oldNode;
@property (nonatomic) NSURL *url;
@property (nonatomic) dispatch_semaphore_t semaphore;

@end
