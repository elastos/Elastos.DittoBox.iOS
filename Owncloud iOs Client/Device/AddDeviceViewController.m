#import "AddDeviceViewController.h"
#import "MBProgressHUD.h"
#import "DeviceManager.h"
#import <CommonCrypto/CommonDigest.h>

@interface AddDeviceViewController()
@property (nonatomic, strong) UITextField *inputTextFeild;
@end

@implementation AddDeviceViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    self.edgesForExtendedLayout = UIRectEdgeNone;
    
    [self addIntroduceLabel];
    [self setupDevicePasswordTextField];
    [self setupCommitButton];
    [self.view setBackgroundColor: UIColorFromRGB(0xF2F2F2)];
    self.navigationItem.title = NSLocalizedString(@"添加设备", nil);
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
}

- (void)addIntroduceLabel
{
    UILabel *label= [[UILabel alloc] initWithFrame:CGRectMake(10, 10, self.view.bounds.size.width - 20, 30)];
    label.text = NSLocalizedString(@"请输入密码", nil);
    label.font = [UIFont systemFontOfSize:14];
    label.textColor = UIColorFromRGB(0x9E9E9E);
    [self.view addSubview:label];
}

- (void)setupDevicePasswordTextField
{
    CGRect rect = CGRectMake(0, 44, self.view.bounds.size.width, 32);
    UIView *view = [[UIView alloc] initWithFrame:rect];
    view.layer.borderWidth = 0.5f;
    view.layer.borderColor = [UIColorFromRGB(0xD9D9D9) CGColor];
    view.backgroundColor = UIColorFromRGB(0xFFFFFF);
    [self.view addSubview: view];
    
    rect.origin.x = rect.origin.x + 10;
    rect.size.width = rect.size.width - 20;
    UITextField *inputTextFeild = [[UITextField alloc] initWithFrame:rect];
    inputTextFeild.keyboardType = UIKeyboardTypeASCIICapable;
    inputTextFeild.delegate = self;
    inputTextFeild.secureTextEntry = YES;
    [self.view addSubview: inputTextFeild];
    self.inputTextFeild = inputTextFeild;
}

-(void)setupCommitButton
{
    UIButton *button = [[UIButton alloc]initWithFrame:CGRectMake(7, 94, self.view.bounds.size.width - 14,32)];
    [button.layer setMasksToBounds:YES];
    [button.layer setCornerRadius:4.0];
    [button setTitle:NSLocalizedString(@"确定",nil) forState:UIControlStateNormal];
    [button setBackgroundColor :UIColorFromRGB(0x0077D9)];
    [button addTarget:self action:@selector(addDevice) forControlEvents:UIControlEventTouchUpInside];
    [self.view addSubview: button];
}

-(BOOL)textFieldShouldReturn:(UITextField *)textField
{
    [self.inputTextFeild resignFirstResponder];
    [self addDevice];
    return YES;
}

-(void)touchesBegan:(NSSet *)touches withEvent:(UIEvent *)event
{
    [self.inputTextFeild resignFirstResponder];
}

-(void)addDevice
{
    NSError *error = nil;
    NSString *password = self.inputTextFeild.text.length > 0 ? [self hash256:self.inputTextFeild.text] : self.inputTextFeild.text;
    BOOL alreadyPaired = [[DeviceManager sharedManager] pairWithDevice:self.deviceAddress passWord:password error:&error];
    
    MBProgressHUD *hud = [MBProgressHUD HUDForView:self.view];
    if (hud) {
        [NSObject cancelPreviousPerformRequestsWithTarget:hud];
    }
    else {
        hud = [[MBProgressHUD alloc] initWithView:self.view];
        hud.removeFromSuperViewOnHide = YES;
        [self.view addSubview:hud];
        [hud show:YES];
    }
    
    if (error == nil)
    {
        if (alreadyPaired) {
            hud.minSize = CGSizeZero;
            hud.mode = MBProgressHUDModeText;
            hud.labelText = NSLocalizedString(@"已添加过该设备", nil);
            [self performSelector:@selector(finish) withObject:nil afterDelay:1];
        }
        else {
            hud.minSize = CGSizeMake(135.f, 135.f);
            hud.mode = MBProgressHUDModeCustomView;
            hud.customView = [[UIImageView alloc] initWithImage:[UIImage imageNamed:@"check_ok"]];
            hud.labelText = NSLocalizedString(@"授权申请已发送", nil);
            //[hud hide:YES afterDelay:1];
            [self performSelector:@selector(finish) withObject:nil afterDelay:1];
        }
    }
    else {
        NSString *errorText = NSLocalizedString(@"添加失败", nil);
//        if (error.code == ECSDevErrorCode_NoDevice) {
//            errorText = NSLocalizedString(@"设备不存在", nil);
//        }
//        else if (error.code == ECSDevErrorCode_DeviceOffLine) {
//            errorText = NSLocalizedString(@"设备不在线", nil);
//        }
//        else if (error.code == ECSDevErrorCode_BadCredential) {
//            errorText = NSLocalizedString(@"密码错误", nil);
//        }
        
        hud.minSize = CGSizeZero;
        hud.mode = MBProgressHUDModeText;
        hud.labelText = errorText;
        [hud hide:YES afterDelay:1];
    }
}

-(void)finish
{
    [self.navigationController popToRootViewControllerAnimated:YES];
}

- (NSString *)hash256:(NSString*)string
{
    // Create pointer to the string as UTF8
    const char *ptr = [string UTF8String];
    
    // Create byte array of unsigned chars
    unsigned char buffer[CC_SHA256_DIGEST_LENGTH];
    
    // Create hash value, store in buffer
    CC_SHA256(ptr, (CC_LONG)strlen(ptr), buffer);
    
    // Convert hash value in the buffer to NSString of hex values
    NSMutableString *output = [NSMutableString stringWithCapacity:CC_SHA256_DIGEST_LENGTH * 2];
    for(int i = 0; i < CC_SHA256_DIGEST_LENGTH; i++)
        [output appendFormat:@"%02x", buffer[i]];
    
    return output;
}

@end
