//
//  DocumentPickerViewController.m
//  MEGAPicker
//
//  Created by Javier Trujillo on 29/5/17.
//  Copyright © 2017 MEGA. All rights reserved.
//

#import "DocumentPickerViewController.h"

#import "SVProgressHUD.h"
#import "SAMKeychain.h"

@interface DocumentPickerViewController ()

@end

@implementation DocumentPickerViewController

-(void)viewDidLoad {
    [SVProgressHUD setViewForExtension:self.view];
    [SVProgressHUD show];
    
    NSString *sessionV3 = [SAMKeychain passwordForService:@"MEGA" account:@"sessionV3"];
    NSLog(@"Sesión: %@", sessionV3);
}

@end
