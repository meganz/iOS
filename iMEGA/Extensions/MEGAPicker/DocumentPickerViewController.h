//
//  DocumentPickerViewController.h
//  MEGAPicker
//
//  Created by Javier Trujillo on 29/5/17.
//  Copyright © 2017 MEGA. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "MEGARequestDelegate.h"
#import "BrowserViewController.h"

@interface DocumentPickerViewController : UIDocumentPickerExtensionViewController <MEGARequestDelegate, MEGATransferDelegate, BrowserViewControllerDelegate>

@property (weak, nonatomic) IBOutlet UIImageView *megaLogo;
@property (weak, nonatomic) IBOutlet UITextView *loginText;
@property (weak, nonatomic) IBOutlet UIButton *openMega;

@end
