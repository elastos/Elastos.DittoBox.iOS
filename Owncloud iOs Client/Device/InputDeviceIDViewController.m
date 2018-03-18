#import "AddDeviceViewController.h"
#import "InputDeviceIDViewController.h"
#import "ImageUtils.h"
#import "MBProgressHUD.h"
#import <ElastosCarrier/ElastosCarrier.h>

@interface InputDeviceIDViewController()<UITextFieldDelegate>
@property (nonatomic, strong) UIButton *commitButton;
@property (nonatomic, strong) UITextField *inputTextFeild;
@end

@implementation InputDeviceIDViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    self.edgesForExtendedLayout = UIRectEdgeNone;

    [self addIntroduceLabel];
    [self addInputTextFeild];
    [self addCommitButton];
    [self.view setBackgroundColor: UIColorFromRGB(0xF2F2F2)];
    self.navigationItem.title = NSLocalizedString(@"输入服务器地址", nil);
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
}

-(void)addIntroduceLabel
{
    UILabel *label = [[UILabel alloc]initWithFrame:CGRectMake(10, 10, self.view.bounds.size.width-20, 30)];
    label.text = NSLocalizedString(@"请输入服务器地址", nil);
    label.font = [UIFont systemFontOfSize:14];
    label.textColor = UIColorFromRGB(0x9E9E9E);
    [self.view addSubview: label];
}

- (void)addInputTextFeild
{
    CGRect rect = CGRectMake(0, 44, self.view.bounds.size.width, 32);
    UIView *view = [[UIView alloc] initWithFrame:rect];
    view.layer.borderWidth = 0.5f;
    view.layer.borderColor = [UIColorFromRGB(0xD9D9D9) CGColor];
    view.backgroundColor = UIColorFromRGB(0xFFFFFF);
    rect.origin.x = rect.origin.x + 10;
    rect.size.width = rect.size.width - 20;
    UITextField *inputTextFeild = [[UITextField alloc] initWithFrame:rect];
    inputTextFeild.keyboardType = UIKeyboardTypeASCIICapable;
    inputTextFeild.delegate = self;
    [inputTextFeild addTarget:self action:@selector(textFieldEditObserver)forControlEvents:UIControlEventEditingChanged];
    _inputTextFeild = inputTextFeild;
    [self.view addSubview: view];
    [self.view addSubview: inputTextFeild];
}

-(void)addCommitButton
{
    UIButton *button = [[UIButton alloc]initWithFrame:CGRectMake(7, 94, self.view.bounds.size.width-14,32)];
    [button setTitle:NSLocalizedString(@"添加",nil) forState:UIControlStateNormal];
    [button setBackgroundColor:UIColorFromRGB(0x0077d9)];
    [button setBackgroundImage:[ImageUtils imageWithColor:[UIColor grayColor]] forState:UIControlStateDisabled];
    [button.layer setMasksToBounds:YES];
    [button.layer setCornerRadius:4.0];
    [button addTarget:self action:@selector(commitInputDeviceID) forControlEvents:UIControlEventTouchUpInside];
    [button setEnabled:NO];

    _commitButton = button;
    [self.view addSubview: button];
}

- (void)commitInputDeviceID
{
    [self.inputTextFeild resignFirstResponder];
    
    if (self.inputTextFeild.text.length == 0)
    {
        return;
    }
    
    MBProgressHUD *hud = [MBProgressHUD HUDForView:self.view];
    if (hud) {
        [NSObject cancelPreviousPerformRequestsWithTarget:hud];
    }
    
    if ([ELACarrier isValidAddress:self.inputTextFeild.text])
    {
        if (hud) {
            [hud hide:YES];
        }
        
        AddDeviceViewController* addDeviceViewController = [[AddDeviceViewController alloc]init];
        addDeviceViewController.deviceAddress = self.inputTextFeild.text;
        [self.navigationController pushViewController:addDeviceViewController animated:YES];
    }
    else {
        if (hud == nil) {
            hud = [[MBProgressHUD alloc] initWithView:self.view];
            hud.removeFromSuperViewOnHide = YES;
            hud.mode = MBProgressHUDModeText;
            hud.labelText = NSLocalizedString(@"服务器地址验证失败", nil);
            [self.view addSubview:hud];
            [hud show:YES];
        }
        
        [hud hide:YES afterDelay:1];
    }
}

-(BOOL)textFieldShouldReturn:(UITextField *)textField
{
    [_inputTextFeild resignFirstResponder];
    [self commitInputDeviceID];
    return YES;
}

-(void)textFieldEditObserver
{
    if(_inputTextFeild.text.length > 0)
    {
        [_commitButton setEnabled:YES];
    }
    else
    {
        [_commitButton setEnabled:NO];
    }
}

-(void)touchesBegan:(NSSet *)touches withEvent:(UIEvent *)event
{
    [self.inputTextFeild resignFirstResponder];
}

@end
