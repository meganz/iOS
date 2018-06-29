
#import "ShareFilesDestinationTableViewController.h"

#import "BrowserViewController.h"
#import "SendToViewController.h"
#import "ShareViewController.h"

@interface ShareFilesDestinationTableViewController ()

@property (nonatomic) NSMutableArray *filesArray;

@end

@implementation ShareFilesDestinationTableViewController

- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
    
    UINavigationController *navigationController = (UINavigationController *)self.parentViewController;
    [navigationController setToolbarHidden:YES animated:animated];
}

#pragma mark - Table view data source

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
    return 2;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    NSUInteger rows = 0;
    
    if (section == 0) {
        return 2;
    } else if (section == 1) {
        return self.filesArray.count;
    }
    
    return rows;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    UITableViewCell *cell = [self.tableView dequeueReusableCellWithIdentifier:@"destinationCell" forIndexPath:indexPath];
    if (!cell) {
        cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:@"destinationCell"];
    }
    
    if (indexPath.section == 0) {
        if (indexPath.row == 0) {
            cell.textLabel.text = AMLocalizedString(@"uploadToMega", nil);
        } else if (indexPath.row == 1) {
            cell.textLabel.text = AMLocalizedString(@"sendToContact", nil);
        }
    }
    
    return cell;
}

-(NSString *)tableView:(UITableView *)tableView titleForHeaderInSection:(NSInteger)section {
    NSString *sectionTitle = @"";
    
    if (section == 0) {
        sectionTitle = AMLocalizedString(@"selectDestination", nil);
    } else if (section == 1) {
        NSString *format = self.filesArray.count == 1 ? AMLocalizedString(@"oneFile", nil) : AMLocalizedString(@"files", nil);
        sectionTitle = [NSString stringWithFormat:format, self.filesArray.count];
    }
    
    return sectionTitle;
}

#pragma mark - Table view delegate

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    UINavigationController *navigationController = (UINavigationController *)self.parentViewController;
    ShareViewController *shareViewController = (ShareViewController *)navigationController.parentViewController;
    if (indexPath.section == 0) {
        if (indexPath.row == 0) {
            UIStoryboard *cloudStoryboard = [UIStoryboard storyboardWithName:@"Cloud" bundle:[NSBundle bundleForClass:BrowserViewController.class]];
            BrowserViewController *browserVC = [cloudStoryboard instantiateViewControllerWithIdentifier:@"BrowserViewControllerID"];
            browserVC.browserAction = BrowserActionShareExtension;
            browserVC.browserViewControllerDelegate = shareViewController;
            [navigationController setToolbarHidden:NO animated:YES];
            [navigationController pushViewController:browserVC animated:YES];
        } else if (indexPath.row == 1) {
            UIStoryboard *chatStoryboard = [UIStoryboard storyboardWithName:@"Chat" bundle:[NSBundle bundleForClass:SendToViewController.class]];
            SendToViewController *sendToViewController = [chatStoryboard instantiateViewControllerWithIdentifier:@"SendToViewControllerID"];
            sendToViewController.sendMode = SendModeShareExtension;
            sendToViewController.sendToViewControllerDelegate = shareViewController;
            [navigationController pushViewController:sendToViewController animated:YES];
        }
    }
}

@end
