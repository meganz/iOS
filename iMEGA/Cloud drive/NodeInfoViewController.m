
#import "NodeInfoViewController.h"
#import "Helper.h"
#import "UIImage+MNZCategory.h"
#import "MEGASdkManager.h"
#import "NodePropertyTableViewCell.h"
#import "NodeTappablePropertyTableViewCell.h"
#import "MEGANode+MNZCategory.h"
#import "MEGAExportRequestDelegate.h"
#import "SVProgressHUD.h"
#import "ContactsViewController.h"
#import "GetLinkTableViewController.h"

@interface MegaNodeProperty : NSObject

@property (strong, nonatomic) NSString *title;
@property (strong, nonatomic) NSString *value;

@end

@implementation MegaNodeProperty

- (instancetype)initWithTitle:(NSString *)title value:(NSString*)value {
    self = [super init];
    if (self) {
        _title = title;
        _value = value;
    }
    return self;
}

@end

@interface NodeInfoViewController () <UITableViewDelegate, UITableViewDataSource>

@property (weak, nonatomic) IBOutlet UITableView *tableView;
@property (weak, nonatomic) IBOutlet UIImageView *thumbnailImageView;
@property (weak, nonatomic) IBOutlet UILabel *nameLabel;
@property (weak, nonatomic) IBOutlet UIBarButtonItem *cancelBarButtonItem;
@property (strong, nonatomic) NSArray<MegaNodeProperty *> *nodeProperties;
@property (nonatomic) MEGAExportRequestDelegate *exportDelegate;

@end

@implementation NodeInfoViewController

#pragma mark - Lifecycle

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view.
    
    [self configureView];
    
    self.nodeProperties = [self nodePropertyCells];
    
    self.exportDelegate = [[MEGAExportRequestDelegate alloc] initWithCompletion:^(MEGARequest *request) {
        [SVProgressHUD dismiss];
        NSIndexPath *indexPath = [NSIndexPath indexPathForRow:(self.node.isFolder ? 1 : 0) inSection:1];
        NodeTappablePropertyTableViewCell *linkCell = [self.tableView cellForRowAtIndexPath:indexPath];
        linkCell.titleLabel.text = [request link];
    } multipleLinks:NO];
}

#pragma mark - Layout

- (void)configureView {
    self.title = AMLocalizedString(@"info", nil);
    self.nameLabel.text = self.node.name;
    if ([self.node type] == MEGANodeTypeFile) {
        if ([self.node hasThumbnail]) {
            [Helper thumbnailForNode:self.node api:[MEGASdkManager sharedMEGASdk] cell:self.thumbnailImageView];
        } else {
            [self.thumbnailImageView setImage:[Helper imageForNode:self.node]];
        }
    } else if ([self.node type] == MEGANodeTypeFolder) {
        [self.thumbnailImageView setImage:[Helper imageForNode:self.node]];
    }
    self.cancelBarButtonItem.title = AMLocalizedString(@"close", nil);
    [self.cancelBarButtonItem setTitleTextAttributes:@{NSFontAttributeName:[UIFont mnz_SFUIRegularWithSize:17.0f], NSForegroundColorAttributeName:[UIColor whiteColor]} forState:UIControlStateNormal];
    self.navigationItem.rightBarButtonItems = @[self.cancelBarButtonItem];
}

#pragma mark - TableViewDelegate

- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath {
    if (indexPath.section == 0) {
        return 44;
    } else {
        return 60;
    }
}

- (CGFloat)tableView:(UITableView *)tableView heightForHeaderInSection:(NSInteger)section {
    return 60;
}

- (CGFloat)tableView:(UITableView *)tableView heightForFooterInSection:(NSInteger)section {
    return 1;
}

- (UIView *)tableView:(UITableView *)tableView viewForHeaderInSection:(NSInteger)section {
    UITableViewCell *sectionHeader = [self.tableView dequeueReusableCellWithIdentifier:@"nodeInfoHeader"];
    
    UILabel *titleSection = (UILabel*)[sectionHeader viewWithTag:1];
    switch (section) {
        case 0:
            titleSection.text = AMLocalizedString(@"details", @"Label title header of node details").uppercaseString;
            break;
        case 1:
            if (section == 1 && self.node.isExported) {
                titleSection.text = AMLocalizedString(@"sharing", @"Label title header of node sharing").uppercaseString;
            } else {
                titleSection.text = AMLocalizedString(@"versions", @"Label title header of node details").uppercaseString;
            }
            break;
        case 2:
            titleSection.text = AMLocalizedString(@"versions", @"Label title header of node versions").uppercaseString;
            break;
        default:
            break;
    }
    return sectionHeader;
}

- (UIView *)tableView:(UITableView *)tableView viewForFooterInSection:(NSInteger)section {
    UITableViewCell *sectionFooter = [self.tableView dequeueReusableCellWithIdentifier:@"nodeInfoFooter"];

    return sectionFooter;
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    NSLog(@"%@", indexPath);
    switch (indexPath.section) {
        case 1:
            switch (indexPath.row) {
                case 0:
                    if (self.node.isFolder) {
                        if (self.node.isShared) {
                            ContactsViewController *contactsVC =  [[UIStoryboard storyboardWithName:@"Contacts" bundle:nil] instantiateViewControllerWithIdentifier:@"ContactsViewControllerID"];
                            contactsVC.contactsMode = ContactsModeFolderSharedWith;
                            contactsVC.node = self.node;
                            [self.navigationController pushViewController:contactsVC animated:YES];
                        } else {
                            UIActivityViewController *activityVC = [Helper activityViewControllerForNodes:@[self.node] sender:self.thumbnailImageView];
                            [self presentViewController:activityVC animated:YES completion:nil];
                        }
                    } else {
                        [self showManageLinkView];
                    }
                    break;
                case 1:
                    [self showManageLinkView];
                    break;
                default:
                    break;
            }
        case 2:
            //TODO: show versions view
            break;
        default:
            break;
    }
}

#pragma mark - TableViewDataSource

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    if (section == 0) {
        return self.nodeProperties.count;
    } else if (section == 1) {
        if (self.node.type == MEGANodeTypeFolder) {
            return 2;
        } else {
            return 1;
        }
    } else {
        return 1;
    }
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    if (indexPath.section == 0) {
        NodePropertyTableViewCell *propertyCell = [self.tableView dequeueReusableCellWithIdentifier:@"nodePropertyCell" forIndexPath:indexPath];
        propertyCell.keyLabel.text = [self.nodeProperties objectAtIndex:indexPath.row].title;
        propertyCell.valueLabel.text = [self.nodeProperties objectAtIndex:indexPath.row].value;
        return propertyCell;
    } else if (indexPath.section == 1) {
        if (self.node.isFolder) {
            if (indexPath.row == 0) {
                return [self sharedFolderCellForIndexPath:indexPath];
            } else {
                return [self linkCellForIndexPath:indexPath];
            }
        } else {
            return [self linkCellForIndexPath:indexPath];
        }
    } else {
        return [self versionCellForIndexPath:indexPath];
    }
}

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
    int sections = 2;
    if ([self.node hasVersions]) {
        sections++;
    }
    return sections;
}

#pragma mark - Actions

- (IBAction)closeTapped:(id)sender {
    [self dismissViewControllerAnimated:YES completion:nil];
}

#pragma mark - Private

- (NSArray<MegaNodeProperty *> *)nodePropertyCells {
    NSMutableArray<MegaNodeProperty *> *propertiesNode = [NSMutableArray new];
    
    [propertiesNode addObject:[[MegaNodeProperty alloc] initWithTitle:AMLocalizedString(@"size", @"Size of the file or folder you are sharing") value:[Helper sizeForNode:self.node api:[MEGASdkManager sharedMEGASdk]]]];
    if (self.node.type == MEGANodeTypeFolder) {
        if ([self.node isInShare]) {
            [propertiesNode addObject:[[MegaNodeProperty alloc] initWithTitle:@"localizar type" value:@"localizar folder incoming"]];
        } else if ([self.node isOutShare]) {
            [propertiesNode addObject:[[MegaNodeProperty alloc] initWithTitle:@"localizar type" value:@"localizar folder outcomin"]];
        } else {
            [propertiesNode addObject:[[MegaNodeProperty alloc] initWithTitle:@"localizar type" value:@"localizar folder"]];
        }
    } else {
        [propertiesNode addObject:[[MegaNodeProperty alloc] initWithTitle:@"localizar type" value:@"de donde saco el tipo de archivo"]];
    }
    [propertiesNode addObject:[[MegaNodeProperty alloc] initWithTitle:@"localizar created" value:[Helper dateWithISO8601FormatOfRawTime:self.node.creationTime.timeIntervalSince1970]]];
    [propertiesNode addObject:[[MegaNodeProperty alloc] initWithTitle:@"localizar modified" value:[Helper dateWithISO8601FormatOfRawTime:self.node.modificationTime.timeIntervalSince1970]]];
    if (self.node.type == MEGANodeTypeFolder) {
        [propertiesNode addObject:[[MegaNodeProperty alloc] initWithTitle:@"localizar contains" value:[Helper filesAndFoldersInFolderNode:self.node api:[MEGASdkManager sharedMEGASdk]]]];
    }
    
    return [propertiesNode copy];
}

- (NodeTappablePropertyTableViewCell *)versionCellForIndexPath:(NSIndexPath *)indexPath {
    NodeTappablePropertyTableViewCell *cell = [self.tableView dequeueReusableCellWithIdentifier:@"nodeTappablePropertyCell" forIndexPath:indexPath];
    cell.iconImageView.image = [UIImage imageNamed:@"versions"];
    cell.titleLabel.text = [NSString stringWithFormat:@"%ld localizar Versiones", (long)[self.node numberOfVersions]];
    return cell;
}

- (NodeTappablePropertyTableViewCell *)sharedFolderCellForIndexPath:(NSIndexPath *)indexPath {
    NodeTappablePropertyTableViewCell *cell = [self.tableView dequeueReusableCellWithIdentifier:@"nodeTappablePropertyCell" forIndexPath:indexPath];
    cell.iconImageView.image = [UIImage imageNamed:@"share"];
    if (self.node.isShared) {
        cell.titleLabel.text = AMLocalizedString(@"sharedWidth", @"Label title indicating the number of users having a node shared");
        cell.subtitleLabel.text = [NSString stringWithFormat:@"%lu localizar users",(unsigned long)[self outSharesForNode:self.node].count];
        [cell.subtitleLabel setHidden:NO];
    } else {
        cell.titleLabel.text = AMLocalizedString(@"share", @"Button title which, if tapped, will trigger the action of sharing with the contact or contacts selected");
    }
    return cell;
}

- (NodeTappablePropertyTableViewCell *)linkCellForIndexPath:(NSIndexPath *)indexPath {
    NodeTappablePropertyTableViewCell *cell = [self.tableView dequeueReusableCellWithIdentifier:@"nodeTappablePropertyCell" forIndexPath:indexPath];
    cell.iconImageView.image = [UIImage imageNamed:@"link"];
    if (self.node.isExported) {
        [[MEGASdkManager sharedMEGASdk] exportNode:self.node delegate:self.exportDelegate];
    } else {
        cell.titleLabel.text = AMLocalizedString(@"getLink", @"Title shown under the action that allows you to get a link to file or folder");
    }
    if (self.node.isFolder && indexPath.row == 1) {
        [cell.separatorView setHidden:YES];
    } else {
        [cell.separatorView setHidden:YES];
    }
    return cell;
}

- (NSMutableArray *)outSharesForNode:(MEGANode *)node {
    NSMutableArray *outSharesForNodeMutableArray = [[NSMutableArray alloc] init];
    
    MEGAShareList *outSharesForNodeShareList = [[MEGASdkManager sharedMEGASdk] outSharesForNode:node];
    NSUInteger outSharesForNodeCount = [[outSharesForNodeShareList size] unsignedIntegerValue];
    for (NSInteger i = 0; i < outSharesForNodeCount; i++) {
        MEGAShare *share = [outSharesForNodeShareList shareAtIndex:i];
        if ([share user] != nil) {
            [outSharesForNodeMutableArray addObject:share];
        }
    }
    
    return outSharesForNodeMutableArray;
}

- (void)showManageLinkView {
    UINavigationController *getLinkNavigationController = [[UIStoryboard storyboardWithName:@"Cloud" bundle:nil] instantiateViewControllerWithIdentifier:@"GetLinkNavigationControllerID"];
    GetLinkTableViewController *getLinkTVC = getLinkNavigationController.childViewControllers[0];
    getLinkTVC.nodesToExport = @[self.node];
    [self presentViewController:getLinkNavigationController animated:YES completion:nil];
}

@end
