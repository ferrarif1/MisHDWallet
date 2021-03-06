//
//  ImportBTCWalletVC.m
//  TaiYiToken
//
//  Created by admin on 2018/9/6.
//  Copyright © 2018年 admin. All rights reserved.
//

#import "ImportBTCWalletVC.h"
#import "ControlBtnsView.h"
#import "SetPasswordView.h"
#import "WBQRCodeVC.h"

#define PRIVATEKEY_REMIND_TEXT  NSLocalizedString(@"输入private Key文件内容至输入框。或通过扫描PrivateKey内容生成的二维码录入。请留意字符大小写。", nil)
#define MNEMONIC_REMIND_TEXT    NSLocalizedString(@"使用助记词导入的同时可以修改钱包密码", nil)
typedef enum {
    PRIVATEKEY_IMPORT = 0,
    MNEMONIC_IMPORT = 1
}BTCWALLET_IMPORT_TYPE;
@interface ImportBTCWalletVC ()<UIImagePickerControllerDelegate>
@property(nonatomic,strong) UIButton *backBtn;
@property(nonatomic)UILabel *titleLabel;
@property(nonatomic)UILabel *remindLabel;
@property(nonatomic)UITextView *ImportContentTextView;
@property(nonatomic)ControlBtnsView *buttonView;
@property(nonatomic)SetPasswordView *setPasswordView;
@property(nonatomic,strong) UIButton *ImportBtn;
@property(nonatomic)UIView *shadowView;
@property(nonatomic)UIButton *scanBtn;
@property(nonatomic)BTCWALLET_IMPORT_TYPE importType;
@end

@implementation ImportBTCWalletVC
-(void)viewWillAppear:(BOOL)animated{
    [super viewWillAppear:YES];
    [MobClick beginLogPageView:@"ImportBTCWalletVC"];
    self.navigationController.navigationBar.hidden = YES;
    self.navigationController.navigationBar.barStyle = UIStatusBarStyleDefault;
    self.navigationController.hidesBottomBarWhenPushed = YES;
    self.tabBarController.tabBar.hidden = YES;
}
-(void)viewWillDisappear:(BOOL)animated{
    [super viewWillDisappear:YES];
    [MobClick endLogPageView:@"ImportBTCWalletVC"];
    self.tabBarController.tabBar.hidden = NO;
    self.navigationController.navigationBar.hidden = NO;
    self.navigationController.hidesBottomBarWhenPushed = NO;
}
- (void)popAction{
    [self.navigationController popViewControllerAnimated:YES];
}
- (void)viewDidLoad {
    [super viewDidLoad];
    self.view.backgroundColor = [UIColor ExportBackgroundColor];
    [self initHeadView];
    [self initUI];
    self.importType = MNEMONIC_IMPORT;
}
-(void)initHeadView{
    UIView *headBackView = [UIView new];
    headBackView.backgroundColor = [UIColor whiteColor];
    [self.view addSubview:headBackView];
    [headBackView mas_makeConstraints:^(MASConstraintMaker *make) {
        make.left.right.equalTo(0);
        make.top.equalTo(0);
        make.height.equalTo(SafeAreaTopHeight);
    }];
    
    _backBtn = [UIButton buttonWithType:UIButtonTypeCustom];
    _backBtn.backgroundColor = [UIColor clearColor];
    _backBtn.tintColor = [UIColor whiteColor];
    [_backBtn.imageView setContentMode:UIViewContentModeScaleAspectFit];
    [_backBtn setImage:[UIImage imageNamed:@"ico_right_arrow"] forState:UIControlStateNormal];
    [_backBtn addTarget:self action:@selector(popAction) forControlEvents:UIControlEventTouchUpInside];
    [self.view addSubview:_backBtn];
    _backBtn.userInteractionEnabled = YES;
    [_backBtn mas_makeConstraints:^(MASConstraintMaker *make) {
        make.top.equalTo(SafeAreaTopHeight - 34);
        make.height.equalTo(25);
        make.left.equalTo(10);
        make.width.equalTo(30);
    }];
    
    _titleLabel = [UILabel new];
    _titleLabel.font = [UIFont boldSystemFontOfSize:17];
    _titleLabel.textColor = [UIColor textBlackColor];
    [_titleLabel setText:[NSString stringWithFormat:NSLocalizedString(@"导入BITCOIN钱包", nil)]];
    _titleLabel.textAlignment = NSTextAlignmentLeft;
    [self.view addSubview:_titleLabel];
    [_titleLabel mas_makeConstraints:^(MASConstraintMaker *make) {
        make.top.equalTo(SafeAreaTopHeight - 30);
        make.left.equalTo(45);
        make.width.equalTo(200);
        make.height.equalTo(20);
    }];
    
    _scanBtn = [UIButton buttonWithType: UIButtonTypeCustom];
    [_scanBtn setBackgroundImage:[UIImage imageNamed:@"wallet_scan"] forState:UIControlStateNormal];
    [_scanBtn addTarget:self action:@selector(scanBtnAction) forControlEvents:UIControlEventTouchUpInside];
    [self.view addSubview:_scanBtn];
    [_scanBtn mas_makeConstraints:^(MASConstraintMaker *make) {
        make.right.equalTo(-20);
        make.top.equalTo(SafeAreaTopHeight - 29);
        make.width.equalTo(16);
        make.height.equalTo(16);
    }];
    
}
-(void)selectImportWay:(UIButton *)btn{
    self.importType = btn.tag == 0? MNEMONIC_IMPORT : PRIVATEKEY_IMPORT;
    [_buttonView setBtnSelected:btn];
    [self.ImportContentTextView setText:@""];
    self.remindLabel.text =  btn.tag == 0?MNEMONIC_REMIND_TEXT : PRIVATEKEY_REMIND_TEXT;
    
}
-(void)initUI{
    _buttonView = [ControlBtnsView new];
    [_buttonView initButtonsViewWithTitles:@[NSLocalizedString(@"助记词", nil),NSLocalizedString(@"私钥", nil)] Width:ScreenWidth Height:44];
    for (UIButton *btn in _buttonView.btnArray) {
        [btn addTarget:self action:@selector(selectImportWay:) forControlEvents:UIControlEventTouchUpInside];
    }
    [self.view addSubview:_buttonView];
    [_buttonView mas_makeConstraints:^(MASConstraintMaker *make) {
        make.top.equalTo(SafeAreaTopHeight);
        make.left.right.equalTo(0);
        make.height.equalTo(44);
    }];
    
    _remindLabel = [UILabel new];
    _remindLabel.font = [UIFont boldSystemFontOfSize:12];
    _remindLabel.textColor = [UIColor textGrayColor];
    _remindLabel.numberOfLines = 0;
    [_remindLabel setText:MNEMONIC_REMIND_TEXT];
    _remindLabel.textAlignment = NSTextAlignmentLeft;
    [self.view addSubview:_remindLabel];
    [_remindLabel mas_makeConstraints:^(MASConstraintMaker *make) {
        make.top.equalTo(125);
        make.left.equalTo(30);
        make.right.equalTo(-30);
        make.height.equalTo(65);
    }];
    
    
    _shadowView = [UIView new];
    _shadowView.layer.shadowColor = [UIColor grayColor].CGColor;
    _shadowView.layer.shadowOffset = CGSizeMake(0, 0);
    _shadowView.layer.shadowOpacity = 1;
    _shadowView.layer.shadowRadius = 3.0;
    _shadowView.layer.cornerRadius = 3.0;
    _shadowView.clipsToBounds = NO;
    [self.view addSubview:_shadowView];
    [_shadowView mas_makeConstraints:^(MASConstraintMaker *make) {
        make.top.equalTo(210);
        make.left.equalTo(15);
        make.right.equalTo(-15);
        make.height.equalTo(100);
    }];
    
    _ImportContentTextView = [UITextView new];
    _ImportContentTextView.layer.shadowColor = [UIColor grayColor].CGColor;
    _ImportContentTextView.layer.shadowOffset = CGSizeMake(0, 0);
    _ImportContentTextView.layer.shadowOpacity = 1;
    _ImportContentTextView.backgroundColor = [UIColor whiteColor];
    _ImportContentTextView.font = [UIFont systemFontOfSize:12];
    _ImportContentTextView.textAlignment = NSTextAlignmentLeft;
    _ImportContentTextView.editable = YES;
    [self.shadowView addSubview:_ImportContentTextView];
    [_ImportContentTextView mas_makeConstraints:^(MASConstraintMaker *make) {
        make.edges.equalTo(0);
    }];
    
    _setPasswordView = [SetPasswordView new];
    [_setPasswordView initSetPasswordViewUI];
    [self.view addSubview:_setPasswordView];
    [_setPasswordView mas_makeConstraints:^(MASConstraintMaker *make) {
        make.top.equalTo(self.ImportContentTextView.mas_bottom).equalTo(20);
        make.left.right.equalTo(0);
        make.height.equalTo(162);
    }];

    
    _ImportBtn = [UIButton buttonWithType: UIButtonTypeSystem];
    _ImportBtn.titleLabel.textColor = [UIColor textBlackColor];
    _ImportBtn.titleLabel.textAlignment = NSTextAlignmentCenter;
    _ImportBtn.titleLabel.font = [UIFont boldSystemFontOfSize:16];
    [_ImportBtn gradientButtonWithSize:CGSizeMake(ScreenWidth, 44) colorArray:@[[UIColor colorWithHexString:@"#4090F7"],[UIColor colorWithHexString:@"#57A8FF"]] percentageArray:@[@(0.3),@(1)] gradientType:GradientFromLeftTopToRightBottom];
    _ImportBtn.tintColor = [UIColor textWhiteColor];
    _ImportBtn.userInteractionEnabled = YES;
    [_ImportBtn setTitle:NSLocalizedString(@"开始导入", nil) forState:UIControlStateNormal];
    [_ImportBtn addTarget:self action:@selector(ImportWalletAction) forControlEvents:UIControlEventTouchUpInside];
    [self.view addSubview:_ImportBtn];
    [_ImportBtn mas_makeConstraints:^(MASConstraintMaker *make) {
        make.left.equalTo(16);
        make.right.equalTo(-16);
        make.bottom.equalTo(-71);
        make.height.equalTo(44);
    }];
    
}
-(void)touchesBegan:(NSSet<UITouch *> *)touches withEvent:(UIEvent *)event{
    [self.view endEditing:YES];
}
//导入
-(void)ImportWalletAction{
    if (![self.setPasswordView.passwordTextField.text isEqualToString:self.setPasswordView.repasswordTextField.text]) {
        [self.view showMsg:NSLocalizedString(@"两次密码输入不一致！", nil)];
        return;
    }
    MJWeakSelf
    if (self.importType == MNEMONIC_IMPORT) {
         
        //去除多余空格
        NSString *cleanmne = [self.ImportContentTextView.text stringByReplacingOccurrencesOfString:@"  " withString:@" "];
        NSString *cleanmne2 = [cleanmne stringByReplacingOccurrencesOfString:@"   " withString:@" "];
        Account *account = [Account accountWithMnemonicPhrase:cleanmne2];
        if (account == nil) {
            [self.view showAlert:@"" DetailMsg:NSLocalizedString(@"请输入正确的助记词！", nil)];
            return;
        }
        
        [self.view showHUD];
        CoinType typex = BTC;
        if (ChangeToTESTNET == 0) {
            typex = BTC;
        }else if (ChangeToTESTNET == 1){
            typex = BTC_TESTNET;
        }
        
        [CreateAll ImportWalletByMnemonic:cleanmne2 CoinType:typex Password:self.setPasswordView.passwordTextField.text PasswordHint:self.setPasswordView.passwordHintTextField.text callback:^(MissionWallet *wallet, NSError *error) {
            [weakSelf.view hideHUD];
            if (wallet == nil) {
                if (error) {
                    [weakSelf.view showAlert:[NSString stringWithFormat:@"error:%ld",error.code] DetailMsg:error.localizedDescription];
                    //[weakSelf.view showMsg:NSLocalizedString(@"导入失败！钱包已存在！", nil)];
                }else{
                    [weakSelf.view showMsg:NSLocalizedString(@"导入失败！", nil)];
                }
            }else{
                [weakSelf.view showMsg:NSLocalizedString(@"导入成功！", nil)];
                NSString *str = [NSString stringWithFormat:@"%@:BTC",wallet.address];
                [NetManager AddAccountLogWithuserName:[CreateAll GetCurrentUserName] AccountInfo:str RecordType:IMPORT_LOG_TYPE CompletionHandler:^(id responseObj, NSError *error) {
                    if (!error) {
                        if (![[NSString stringWithFormat:@"%@",responseObj[@"resultCode"]] isEqualToString:@"20000"]) {
                            [weakSelf.view showAlert:@"" DetailMsg:responseObj[@"resultMsg"]];
                            return ;
                        }
                    }else{
                        [weakSelf.view showAlert:[NSString stringWithFormat:@"Error:%ld",error.code] DetailMsg:error.localizedDescription];
                    }
                }];
                dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(2 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
                    [weakSelf.navigationController popToRootViewControllerAnimated:YES];
                });
            }
        }];
        
    }else if(self.importType == PRIVATEKEY_IMPORT){
        if (![self.ImportContentTextView.text isValidBitcoinPrivateKey]) {
            [self.view showMsg:NSLocalizedString(@"请输入正确格式的私钥！", nil)];
            return;
        }
        [self.view showHUD];
        CoinType typex = BTC;
        if (ChangeToTESTNET == 0) {
            typex = BTC;
        }else if (ChangeToTESTNET == 1){
            typex = BTC_TESTNET;
        }
        
        
        MissionWallet *wallet = [CreateAll ImportWalletByPrivateKey:self.ImportContentTextView.text CoinType:typex Password:self.setPasswordView.passwordTextField.text PasswordHint:self.setPasswordView.passwordHintTextField.text];
        [self.view hideHUD];
        
        if (wallet == nil) {
            [self.view showMsg:NSLocalizedString(@"导入失败！", nil)];
        }else{
            if ([wallet.address isValidBitcoinAddress]) {
                NSString *str = [NSString stringWithFormat:@"%@:BTC",wallet.address];
                [NetManager AddAccountLogWithuserName:[CreateAll GetCurrentUserName] AccountInfo:str RecordType:IMPORT_LOG_TYPE CompletionHandler:^(id responseObj, NSError *error) {
                    if (!error) {
                        if (![[NSString stringWithFormat:@"%@",responseObj[@"resultCode"]] isEqualToString:@"20000"]) {
                            [weakSelf.view showAlert:@"" DetailMsg:responseObj[@"resultMsg"]];
                            return ;
                        }
                    }else{
                        [weakSelf.view showAlert:[NSString stringWithFormat:@"Error:%ld",error.code] DetailMsg:error.localizedDescription];
                    }
                }];
                [self.view showMsg:NSLocalizedString(@"导入成功！", nil)];
                dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(2 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
                    [weakSelf.navigationController popToRootViewControllerAnimated:YES];
                });
            }else{
                [self.view showMsg:NSLocalizedString(@"导入失败！", nil)];
            }
        }
    }
}
//扫描二维码
-(void)scanBtnAction{
    WBQRCodeVC *WBVC = [[WBQRCodeVC alloc] init];
    [self QRCodeScanVC:WBVC];
    MJWeakSelf
    [WBVC setGetQRCodeResult:^(NSString *string) {
        NSLog(@"QRCode result = %@",string);
        weakSelf.ImportContentTextView.text = string;
    }];
}

//扫码判断权限
- (void)QRCodeScanVC:(UIViewController *)scanVC {
    MJWeakSelf
    AVCaptureDevice *device = [AVCaptureDevice defaultDeviceWithMediaType:AVMediaTypeVideo];
    if (device) {
        AVAuthorizationStatus status = [AVCaptureDevice authorizationStatusForMediaType:AVMediaTypeVideo];
        switch (status) {
            case AVAuthorizationStatusNotDetermined: {
                [AVCaptureDevice requestAccessForMediaType:AVMediaTypeVideo completionHandler:^(BOOL granted) {
                    if (granted) {
                        dispatch_sync(dispatch_get_main_queue(), ^{
                            // [weakSelf.navigationController pushViewController:scanVC animated:YES];
                            UINavigationController *navisc = [[UINavigationController alloc]initWithRootViewController:scanVC];
                            [weakSelf presentViewController:navisc animated:YES completion:^{
                                
                            }];
                        });
                        NSLog(NSLocalizedString(@"用户第一次同意了访问相机权限 - - %@", nil), [NSThread currentThread]);
                    } else {
                        NSLog(NSLocalizedString(@"用户第一次拒绝了访问相机权限 - - %@", nil), [NSThread currentThread]);
                    }
                }];
                break;
            }
            case AVAuthorizationStatusAuthorized: {
                // [weakSelf.navigationController pushViewController:scanVC animated:YES];
                UINavigationController *navisc = [[UINavigationController alloc]initWithRootViewController:scanVC];
                [weakSelf presentViewController:navisc animated:YES completion:^{
                    
                }];
                break;
            }
            case AVAuthorizationStatusDenied: {
                UIAlertController *alertC = [UIAlertController alertControllerWithTitle:NSLocalizedString(@"温馨提示", nil) message:NSLocalizedString(@"请去-> [设置 - 隐私 - 相机 - MisToken] 打开访问开关", nil) preferredStyle:(UIAlertControllerStyleAlert)];
                UIAlertAction *alertA = [UIAlertAction actionWithTitle:NSLocalizedString(@"确定", nil) style:(UIAlertActionStyleDefault) handler:^(UIAlertAction * _Nonnull action) {
                    
                }];
                
                [alertC addAction:alertA];
                [weakSelf presentViewController:alertC animated:YES completion:nil];
                break;
            }
            case AVAuthorizationStatusRestricted: {
                NSLog(NSLocalizedString(@"因为系统原因, 无法访问相册", nil));
                break;
            }
                
            default:
                break;
        }
        return;
    }
    
    UIAlertController *alertC = [UIAlertController alertControllerWithTitle:NSLocalizedString(@"温馨提示", nil) message:NSLocalizedString(@"未检测到您的摄像头", nil) preferredStyle:(UIAlertControllerStyleAlert)];
    UIAlertAction *alertA = [UIAlertAction actionWithTitle:NSLocalizedString(@"确定", nil) style:(UIAlertActionStyleDefault) handler:^(UIAlertAction * _Nonnull action) {
        
    }];
    
    [alertC addAction:alertA];
    [self presentViewController:alertC animated:YES completion:nil];
}
- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    
}


@end
