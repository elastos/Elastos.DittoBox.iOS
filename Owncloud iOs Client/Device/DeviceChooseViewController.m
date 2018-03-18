#import "DeviceChooseViewController.h"
#import "DeviceSettingViewController.h"
#import "ScanViewController.h"
#import "DeviceManager.h"
#import "MBProgressHUD.h"
#import "OCNavigationController.h"

@interface DeviceChooseViewController ()

@end

@implementation DeviceChooseViewController

- (void)dealloc
{
    [[NSNotificationCenter defaultCenter] removeObserver:self.tableView name:kNotificationDeviceListUpdated object:nil];
}

- (void)viewDidLoad {
    [super viewDidLoad];
    
    self.title = @"所有设备";
    
    self.navigationItem.leftBarButtonItem = [[UIBarButtonItem alloc] initWithImage:[UIImage imageNamed:@"back"] style:UIBarButtonItemStylePlain target:self action:@selector(back)];
    self.navigationItem.rightBarButtonItem = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemAdd target:self action:@selector(addDevice)];
    
    self.tableView.rowHeight = 55.0f;
    self.tableView.tableFooterView = [[UIView alloc] initWithFrame:CGRectZero];
    self.tableView.separatorInset = UIEdgeInsetsZero;
//    if ([self.tableView respondsToSelector:@selector(setLayoutMargins:)]) {
//        self.tableView.layoutMargins = UIEdgeInsetsZero;
//    }
    
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(reload) name:kNotificationDeviceListUpdated object:nil];
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

- (void)addDevice {
    UIViewController *viewController = nil;
    viewController = [[ScanViewController alloc] init];
    [self.navigationController pushViewController:viewController animated:YES];
}

- (void)reload {
    dispatch_async(dispatch_get_main_queue(), ^{
        [self.tableView reloadData];
    });
}

- (void)navigateFrom:(UIViewController *)currentVC {
    OCNavigationController *navController = [[OCNavigationController alloc] initWithRootViewController:self];
    
    //Check if is iPhone or iPad
    if (!IS_IPHONE) {
        //iPad
        navController.modalTransitionStyle=UIModalTransitionStyleCoverVertical;
        navController.modalPresentationStyle = UIModalPresentationFormSheet;
    }
    [currentVC presentViewController:navController animated:YES completion:nil];
}

- (void)back {
    [self dismissViewControllerAnimated:YES completion:nil];
}

#pragma mark - Table view data source

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
    return 1;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    return [DeviceManager sharedManager].devices.count;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:@"reuseIdentifier"];
    UIImageView *onlineImageView = nil;
    if (cell == nil) {
        cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleSubtitle reuseIdentifier:@"reuseIdentifier"];
        cell.textLabel.textColor = UIColorFromRGB(0x666666);
        cell.textLabel.font = [UIFont systemFontOfSize:16.0f];
        cell.detailTextLabel.textColor = UIColorFromRGB(0xB3B3B3);
        cell.detailTextLabel.font = [UIFont systemFontOfSize:13.0f];
        cell.accessoryType = UITableViewCellAccessoryDetailButton;
        cell.selectionStyle = UITableViewCellSelectionStyleDefault;

        onlineImageView = [[UIImageView alloc] initWithImage:[UIImage imageNamed:@"online"]];
        onlineImageView.frame = CGRectMake(cell.contentView.frame.size.width - 12, 21, 12, 12);
        onlineImageView.autoresizingMask = UIViewAutoresizingFlexibleLeftMargin;
        onlineImageView.tag = 1;
        [cell.contentView addSubview:onlineImageView];
    }
    else {
        onlineImageView = [cell.contentView viewWithTag:1];
    }
    
    // Configure the cell...
    Device *device = [DeviceManager sharedManager].devices[indexPath.row];
    cell.textLabel.text = device.deviceName;
    if (device.localPort > 0) {
        cell.detailTextLabel.text = [NSString stringWithFormat:@"https://localhost:%d", device.localPort];
    }
    if (device == [DeviceManager sharedManager].currentDevice) {
        cell.imageView.image = [UIImage imageNamed:@"select"];
    }
    else {
        cell.imageView.image = [UIImage imageNamed:@"unselect"];
    }
    onlineImageView.hidden = !device.isOnline;
    
    return cell;
}

//- (void)tableView:(UITableView *)tableView willDisplayCell:(UITableViewCell *)cell forRowAtIndexPath:(NSIndexPath *)indexPath
//{
//    cell.separatorInset = UIEdgeInsetsZero;
//    if ([cell respondsToSelector:@selector(setLayoutMargins:)]) {
//        cell.layoutMargins = UIEdgeInsetsZero;
//    }
//}

// Override to support conditional editing of the table view.
- (BOOL)tableView:(UITableView *)tableView canEditRowAtIndexPath:(NSIndexPath *)indexPath {
    // Return NO if you do not want the specified item to be editable.
    return YES;
}

// Override to support editing the table view.
- (void)tableView:(UITableView *)tableView commitEditingStyle:(UITableViewCellEditingStyle)editingStyle forRowAtIndexPath:(NSIndexPath *)indexPath {
    if (editingStyle == UITableViewCellEditingStyleDelete) {
        Device *device = [DeviceManager sharedManager].devices[indexPath.row];

        if (![[DeviceManager sharedManager] unPairDevice:device error:nil]) {
            [MBProgressHUD showToast:NSLocalizedString(@"删除失败", nil)
                              inView:self.view
                            duration:1
                            animated:YES];
        }
//        else {
//            [MBProgressHUD showHUDAddedTo:self.view animated:YES];
//        }
    }
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    [tableView deselectRowAtIndexPath:indexPath animated:YES];
    
    Device *device = [DeviceManager sharedManager].devices[indexPath.row];
    if (device != [DeviceManager sharedManager].currentDevice) {
        if (device.isOnline) {
            [[DeviceManager sharedManager].currentDevice disconnect];
            [DeviceManager sharedManager].currentDevice = device;
            [self.tableView reloadData];
            //[self.navigationController popViewControllerAnimated:YES];
        }
        else {
            [MBProgressHUD showToast:NSLocalizedString(@"该设备不在线", nil)
                              inView:self.view
                            duration:1
                            animated:YES];
        }
    }
}

- (void)tableView:(UITableView *)tableView accessoryButtonTappedForRowWithIndexPath:(NSIndexPath *)indexPath
{
    DeviceSettingViewController *vc = [[DeviceSettingViewController alloc] init];
    vc.device = [DeviceManager sharedManager].devices[indexPath.row];
    [self.navigationController pushViewController:vc animated:YES];
}

@end
