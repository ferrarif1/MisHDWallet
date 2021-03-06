//
//  NewHomePageVC.m
//  TaiYiToken
//
//  Created by Frued on 2018/10/22.
//  Copyright © 2018年 admin. All rights reserved.
//

#import "NewHomePageVC.h"
#import "WalletCell.h"
#import "MissionWallet.h"
#import "WalletListCell.h"
#import <AVFoundation/AVFoundation.h>
#import "WBQRCodeVC.h"
#import "CustomizedNavigationController.h"
#import "ReceiptQRCodeVC.h"
#import "WalletManagerVC.h"
#import "Customlayout.h"
#import "TransactionVC.h"
#import "BTCBalanceModel.h"
#import "CreateAccountVC.h"
#import "LoginVC.h"
#import "HeadInfoView.h"
#import "ControlBtnsView.h"
#import "ImportWalletSwitchVC.h"
#import "WalletDetailVC.h"
#import "SystemInitModel.h"
#import "JavascriptWebViewController.h"
#import "EOSWalletDetailVC.h"
#import "CreateAccountVC.h"
#import "ImportHDWalletVC.h"
#import "MarketProfitModel.h"
#import "WalletSectionHeaderView.h"
#import "HelpView.h"
#import "BTCBlockChainListModel.h"
#import "EOSWalletRegister.h"
#import "EOSAuthorityVC.h"
#import "EOSHelpRegisterVC.h"
@interface NewHomePageVC ()<UITableViewDelegate,UITableViewDataSource,UIImagePickerControllerDelegate, UINavigationControllerDelegate,MGSwipeTableCellDelegate>
@property(nonatomic,copy)NSString *headcontentstr;
@property(nonatomic,strong)FMDatabase *db;
@property(nonatomic,strong)SystemInitModel *systemmodel;
@property(nonatomic,strong)MarketProfitModel *marketProfitModel;

@property(nonatomic,strong)HeadInfoView *headInfoView;//总余额 钱包管理
@property(nonatomic,strong)ControlBtnsView *buttonView;
@property(nonatomic,strong)UIButton *importBtn;

@property(nonatomic,strong)UITableView *tableView;
@property(nonatomic,strong)UIButton *walletBtn;
@property(nonatomic,strong)UIButton *scanBtn;
@property(nonatomic,strong)UILabel *titleLabel;
@property(nonatomic)NSInteger selectedIndex;
@property(nonatomic,strong)MissionWallet *misWallet;
/* v2 改造
 @property(nonatomic,strong)NSMutableArray <NSMutableArray*> *miswalletArray;
 @property(nonatomic,strong)NSMutableArray <NSMutableArray*> *btcwalletArray;
 @property(nonatomic,strong)NSMutableArray <NSMutableArray*> *ethwalletArray;
 @property(nonatomic,strong)NSMutableArray <NSMutableArray*> *eoswalletArray;
 */

@property(nonatomic,strong)NSMutableArray <MissionWallet*> *walletArray;
@property(nonatomic,strong)NSMutableArray <MissionWallet*> *walletArrayCopy;
@property (nonatomic, strong)dispatch_source_t time;
@property(nonatomic)float TimeInterval;
@property(nonatomic,strong)UIView *headView;

//余额
@property(nonatomic,strong)NSMutableArray <NSNumber *>*walletBalance;
//保存对应walletBalance 的BTC钱包转账后未确认的转账金额，与walletBalance相加得到余额,其他类型钱包值为0
@property(nonatomic,strong)NSMutableArray *tempwalletBalance;
@property(nonatomic)CGFloat BTCCurrency;//btc 美元汇率
@property(nonatomic)CGFloat ETHCurrency;
@property(nonatomic)CGFloat EOSCurrency;
@property(nonatomic)CGFloat MISCurrency;
@property(nonatomic)CGFloat RMBDollarCurrency;//人民币汇率
@property(nonatomic,copy)NSString *currentCurrencySelected;//当前选择的货币单位
@property(nonatomic,strong)UIButton *createAccountBtn;
@property(nonatomic,strong)UIButton *importAccountBtn;
@property(nonatomic,strong)UIImageView *bottomImageView;
//当前选择
@property(nonatomic)WALLET_SELECT_TYPE currentSelectedType;

@property(nonatomic,strong)NSMutableArray <NSNumber *> *amountarray;//rmb或dollar余额
@property(nonatomic,strong)NSMutableArray <NSNumber *> *gainsarray;//rmb或dollar余额
@property(nonatomic,strong)JavascriptWebViewController *jvc;
// 2000导入，3000创建
@property(nonatomic,assign)NSInteger switchWalletImportWay;
//查询到的链上当前账户的pubkey
@property(nonatomic,copy)NSString *currentPubkeyForAccountInChain;

@property(nonatomic,strong)NSMutableArray <WalletSectionHeaderView *> *listheaderViewArray;

@property(nonatomic,strong)HelpView *help;
@property(nonatomic,strong)UIView *footerView;
@end

@implementation NewHomePageVC


#pragma mark - 获取帐号信息
- (void)getEOSKey:(NSString *)pubkey AccountSuccess:(void(^)(id response))handler{
    NSDictionary *dic = @{@"public_key":pubkey};
    [[HTTPRequestManager shareEosManager] post:eos_get_key_accounts paramters:dic success:^(BOOL isSuccess, id responseObject) {
        if (isSuccess) {
            handler(responseObject);
        }else{
            handler(nil);
        }
    } failure:^(NSError *error) {
        handler(nil);
    } superView:self.view showFaliureDescription:YES];
    
}
- (void)getAccountCointype:(CoinType)cointype Success:(void(^)(id response))handler{
    NSString *username = [CreateAll GetCurrentUserName];
    if (!username) {
        return;
    }
    MJWeakSelf
    NSDictionary *dic = @{@"account_name":username};
    if (cointype == MIS) {
        [[HTTPRequestManager shareManager] post:eos_get_account paramters:dic success:^(BOOL isSuccess, id responseObject) {
            if (isSuccess) {
                //帐号已存在
                handler(responseObject);
                @autoreleasepool {
                    AccountInfo *info = [AccountInfo parse:responseObject];
                    // 判断公钥是否相等
                    for (Permission *p in info.permissions) {
                        if ([p.perm_name isEqualToString:@"owner"]) {
                            if (p.required_auth.keys.count > 0) {
                                weakSelf.currentPubkeyForAccountInChain = p.required_auth.keys.firstObject.key;
                            }
                        }
                    }
                }
                
                [weakSelf showImportAccountBtn];
                
            }else{
                //帐号不存在
                [weakSelf showTwoBtn];
            }
        } failure:^(NSError *error) {
            [weakSelf showTwoBtn];
            //NSError *err = [NSError ErrorWithTitle:NSLocalizedString(@"账户信息查询失败，请稍后再试", nil) Code:102800];
            // [weakSelf.view showAlert:[NSString stringWithFormat:@"Error:%ld",err.code] DetailMsg:err.localizedDescription];
            
        } superView:self.view showFaliureDescription:YES];
    }else if (cointype == EOS){
        [[HTTPRequestManager shareEosManager] post:eos_get_account paramters:dic success:^(BOOL isSuccess, id responseObject) {
            
            if (isSuccess) {
               handler(responseObject);
            }else{
               handler(nil);
            }
        } failure:^(NSError *error) {
            
        } superView:self.view showFaliureDescription:YES];
    }
   
}

- (void)getEOSAccount:(NSString *)account Success:(void(^)(id response))handler{
    
    NSDictionary *dic = @{@"account_name":account};
    
    [[HTTPRequestManager shareEosManager] post:eos_get_account paramters:dic success:^(BOOL isSuccess, id responseObject) {
        
        if (isSuccess) {
            handler(responseObject);
        }else{
            handler(nil);
        }
    } failure:^(NSError *error) {
        
    } superView:self.view showFaliureDescription:YES];
    
}

-(void)showImportAccountBtn{
    self.switchWalletImportWay = 2000;
    self.bottomImageView.hidden = NO;
    self.createAccountBtn.hidden = YES;
    self.importAccountBtn.userInteractionEnabled = YES;
    [self.importAccountBtn setTitle:NSLocalizedString(@"导入钱包", nil) forState:UIControlStateNormal];
}

-(void)showTwoBtn{
    self.switchWalletImportWay = 3000;
    self.bottomImageView.hidden = NO;
    self.importAccountBtn.userInteractionEnabled = YES;
    self.createAccountBtn.userInteractionEnabled = YES;
    [self.importAccountBtn setTitle:NSLocalizedString(@"导入钱包", nil) forState:UIControlStateNormal];
    [self.createAccountBtn setTitle:NSLocalizedString(@"创建钱包", nil) forState:UIControlStateNormal];
}

-(void)hideHelpView:(UIButton *)btn{
    MJWeakSelf
    if (btn.tag == 7000) {
        btn.tag = 7001;
        [UIView animateWithDuration:0.6 animations:^{
            weakSelf.help.img0.alpha = 0;
            weakSelf.help.img1.alpha = 0;
            weakSelf.help.img2.alpha = 0;
            weakSelf.help.img3.alpha = 1;
        } completion:^(BOOL finished) {
            
        }];
    }else if (btn.tag == 7001){
        [UIView animateWithDuration:0.6 animations:^{
            weakSelf.help.alpha = 0;
        } completion:^(BOOL finished) {
            [weakSelf.help removeFromSuperview];
            weakSelf.help = nil;
        }];
    }
    
}

-(void)touchesBegan:(NSSet<UITouch *> *)touches withEvent:(UIEvent *)event{
    
    if (![CreateAll isLogin]) {
        LoginVC *vc = [LoginVC new];
        vc.showBackBtn = NO;
        [self.navigationController pushViewController:vc animated:YES];
    }
}


//接收到登录成功通知
-(void)receivelogin{
   
    [self getAccountCointype:MIS Success:^(id response) {
        
    }];
    
    [self viewWillAppear:YES];
    [self.view reloadInputViews];
}
//接收到退出通知
-(void)receivelogout{
    self.currentPubkeyForAccountInChain = nil;
    [self.walletBalance removeAllObjects];
    [self.tempwalletBalance removeAllObjects];
    [self.amountarray removeAllObjects];
    [self.gainsarray removeAllObjects];
    self.walletBalance = [NSMutableArray arrayWithObjects:@0,@0,@0,@0,@0,@0,@0,@0,@0,@0,@0,@0,@0,@0,@0, nil];
    self.tempwalletBalance = [NSMutableArray arrayWithObjects:@0,@0,@0,@0,@0,@0,@0,@0,@0,@0,@0,@0,@0,@0,@0, nil];
    self.amountarray = [NSMutableArray arrayWithObjects:@0,@0,@0,@0,@0,@0,@0,@0,@0,@0,@0,@0,@0,@0,@0, nil];
    self.gainsarray = [NSMutableArray arrayWithObjects:@0,@0,@0,@0,@0,@0,@0,@0,@0,@0,@0,@0,@0,@0,@0, nil];
    self.selectedIndex = 0;
    self.TimeInterval = 10.0;
    [self.walletArray removeAllObjects];
    [self.walletArrayCopy removeAllObjects];
    self.misWallet = nil;
    [self.tableView reloadData];
    
    [self.tableView setHidden:YES];
    [self.headView setHidden:YES];
    //self.createAccountBtn.hidden = NO;
    self.importBtn.hidden = YES;
    self.headInfoView.hidden = YES;
    self.buttonView.hidden = YES;
    [self.view reloadInputViews];
}




//BTC 找零地址
-(void)getBtcChangeAddress{
    
    for (MissionWallet *obj in self.walletArray) {
        MJWeakSelf
        @autoreleasepool {
            //助记词导入/生成的BTC钱包
            if ((obj.coinType == BTC || obj.coinType == BTC_TESTNET) && obj.importType != IMPORT_BY_PRIVATEKEY) {
                if ([obj.xprv isEqualToString:@""] || obj.xprv == nil) {
                    continue;
                }
                
                NSArray <BTCChangeAddressModel *>*arr = [CreateAll queryAllchange:weakSelf.db Address:obj.address];
                if (arr.count == 0 && obj.xprv) {
                    [CreateAll CreateBTCChangeAddressByXprv:obj.xprv CoinType:obj.coinType Password:@""];
                    continue;
                }
                
                if (arr && arr.count>0) {
                    obj.changeAddressArray = [arr mutableCopy];
                    NSString *str = @"";
                    for (BTCChangeAddressModel *model in arr) {
                        str = [str stringByAppendingString: [NSString stringWithFormat:@"%@,",model.changeaddress]];
                    }
                    str = [str stringByAppendingString:obj.address];
                    obj.changeAddressStr = str;
                    NSLog(@"\n%@",str);
                    [CreateAll SaveWallet:obj Name:obj.walletName WalletType:obj.walletType Password:nil];
                }else{
                    obj.changeAddressStr = obj.address;
                }
            }
        }
    }

}

-(void)viewWillAppear:(BOOL)animated{
    MJWeakSelf
    [super viewWillAppear:YES];
    [MobClick beginLogPageView:@"NewHomePageVC"];
    self.navigationController.navigationBar.hidden = YES;
    self.navigationController.navigationBar.barStyle = UIStatusBarStyleDefault;
    self.navigationController.hidesBottomBarWhenPushed = YES;
    self.tabBarController.tabBar.hidden = NO;
    [self systemDataInit];
    [self getAccountCointype:MIS Success:^(id response) {
        
    }];
    BOOL priConfig = [[NSUserDefaults standardUserDefaults] boolForKey:@"PrivacyModeON"];
    if (priConfig == YES) {
        self.headInfoView.balanceBtn.tag = 2300;
        self.headInfoView.gainsBtn.tag = 2500;
    }else{
        self.headInfoView.balanceBtn.tag = 1300;
        self.headInfoView.gainsBtn.tag = 1500;
    }
    
    if (![self.db isOpen]) {
        [self.db open];
    }
   
    if (![CreateAll isLogin]) {
        LoginVC *vc = [LoginVC new];
        vc.showBackBtn = NO;
        [self.navigationController pushViewController:vc animated:YES];
        return;
    }
    [self.view reloadInputViews];
    [self.importBtn setTitle:NSLocalizedString(@"导入新钱包", nil) forState:UIControlStateNormal];
   
    if ([[NSUserDefaults standardUserDefaults] boolForKey:@"ifHasAccount"] == YES) {
        @autoreleasepool {
            NSString *username = [CreateAll GetCurrentUserName];
            [_walletArray removeAllObjects];
            [_walletArrayCopy removeAllObjects];
            NSInteger otherscount = 0;
            NSInteger miscount = 0;
            if (self.misWallet == nil) {
                
                if (username) {
                    MissionWallet *walletMIS = [CreateAll GetMissionWalletByName: [NSString stringWithFormat:@"MIS_%@",username]];
                    if (walletMIS) {
                        UIButton *misbtn = (UIButton *)self.buttonView.btnArray[1];
                        [misbtn setTitle:@"MIS(1)" forState:UIControlStateNormal];
                        self.misWallet = walletMIS;
                        miscount ++;
                        if (self.currentSelectedType != WALLET_SELECT_OTHERS) {//ALL/MIS 有mis钱包
                            [self.walletArray addObject:walletMIS];
                        }
                        [self.walletArrayCopy addObject:walletMIS];
                    }
                }
            }else{
                miscount ++;
                if (self.currentSelectedType != WALLET_SELECT_OTHERS) {//ALL/MIS 有mis钱包
                    [self.walletArray addObject:self.misWallet];
                }
                [self.walletArrayCopy addObject:self.misWallet];
            }
            
            MissionWallet *walletBTC = [CreateAll GetMissionWalletByName:@"BTC"];
            MissionWallet *walletETH = [CreateAll GetMissionWalletByName:@"ETH"];
//            //usdt wallet
//            MissionWallet *walletUSDT = [CreateAll GetMissionWalletByName:@"BTC"];
//            walletUSDT.coinType = USDT;
//            walletUSDT.walletName = @"USDT";
//
            NSString *localeosname = [[NSUserDefaults standardUserDefaults] objectForKey:@"LocalEOSWalletName"];
            MissionWallet *walletEOS = [CreateAll GetMissionWalletByName:VALIDATE_STRING(localeosname)];
            if (walletBTC) {
                otherscount ++;
                if(self.currentSelectedType != WALLET_SELECT_MIS){//All / Other 有其他钱包
                    [self.walletArray addObject:walletBTC];
                    //usdt wallet
                   // [self.walletArray addObject:walletUSDT];
                }
                [self.walletArrayCopy addObject:walletBTC];
                //usdt wallet
               // [self.walletArrayCopy addObject:walletUSDT];
            }
            if (walletETH) {
                otherscount ++;
                if(self.currentSelectedType != WALLET_SELECT_MIS){//All / Other 有其他钱包
                    [self.walletArray addObject:walletETH];
                }
                [self.walletArrayCopy addObject:walletETH];
            }
            if (walletEOS) {
                otherscount ++;
                if(self.currentSelectedType != WALLET_SELECT_MIS){//All / Other 有其他钱包
                    [self.walletArray addObject:walletEOS];
                }
                [self.walletArrayCopy addObject:walletEOS];
            }
            
            //每次显示页面都刷新导入的钱包列表
            NSArray *importwalletarray = [CreateAll GetImportWalletNameArray];
            if (importwalletarray) {
                for (NSString *importwalletname in importwalletarray) {
                    MissionWallet *wallet = [CreateAll GetMissionWalletByName:importwalletname];
                    if(self.currentSelectedType != WALLET_SELECT_MIS){//All / Other 有其他钱包
                        [self.walletArray addObject:wallet];
                    }
                    otherscount ++;
                    [self.walletArrayCopy addObject:wallet];
                }
            }
            
            
            [self getBtcChangeAddress];
            UIButton *misbtn = (UIButton *)self.buttonView.btnArray[2];
            [misbtn setTitle:[NSString stringWithFormat:@"%@(%ld)",NSLocalizedString(@"MIS", nil),miscount] forState:UIControlStateNormal];
            
            UIButton *allbtn = (UIButton *)self.buttonView.btnArray[0];
            [allbtn setTitle:NSLocalizedString(@"全部", nil) forState:UIControlStateNormal];
            UIButton *otherbtn = (UIButton *)self.buttonView.btnArray[2];
            [otherbtn setTitle:[NSString stringWithFormat:@"%@(%ld)",NSLocalizedString(@"其他", nil),otherscount] forState:UIControlStateNormal];
            
            [self.tableView setHidden:NO];
            [self.headView setHidden:NO];
            
            [self.tableView reloadData];
            if (![[NSUserDefaults standardUserDefaults] objectForKey:@"CurrentCurrencySelected"]) {
                [[NSUserDefaults standardUserDefaults] setObject:@"rmb" forKey:@"CurrentCurrencySelected"];
                [[NSUserDefaults standardUserDefaults] synchronize];
            }
            self.currentCurrencySelected = [[NSUserDefaults standardUserDefaults] objectForKey:@"CurrentCurrencySelected"];
            self.buttonView.hidden = NO;
            self.importBtn.hidden = NO;
            self.headInfoView.hidden = NO;
        }
      
        
        
        //回到页面 开始请求余额
        [_bottomImageView removeFromSuperview];
        [_importAccountBtn removeFromSuperview];
        [_createAccountBtn removeFromSuperview];
        _bottomImageView  = nil;
        _importAccountBtn  = nil;
        _createAccountBtn  = nil;
        self.time = nil;
        [self InitTimerRequest];
        //显示帮助引导
        
        NSInteger isFirstUse = [[NSUserDefaults standardUserDefaults] integerForKey:@"isFirstUse"];
        if (isFirstUse == 200) {
            [[NSUserDefaults standardUserDefaults] setInteger:300 forKey:@"isFirstUse"];
            [[NSUserDefaults standardUserDefaults] synchronize];
            self.help.alpha = 0;
            [UIView animateWithDuration:0.6 animations:^{
                weakSelf.help.alpha = 1;
            }];
        }
       
    }else{
        
        [self.walletArray removeAllObjects];
        [self.tableView reloadData];
        [self.tableView setHidden:YES];
        [self.headView setHidden:YES];
        self.bottomImageView.hidden = NO;
        self.createAccountBtn.hidden = NO;
        self.importAccountBtn.hidden = NO;
        [self.importAccountBtn setTitle:NSLocalizedString(@"导入钱包", nil) forState:UIControlStateNormal];
        [self.createAccountBtn setTitle:NSLocalizedString(@"创建钱包", nil) forState:UIControlStateNormal];
        self.importBtn.hidden = YES;
        self.headInfoView.hidden = YES;
        self.buttonView.hidden = YES;
        [self.view reloadInputViews];
    }
}

-(UIImageView *)bottomImageView{
    if (!_bottomImageView && [[NSUserDefaults standardUserDefaults] boolForKey:@"ifHasAccount"] == NO) {
        _bottomImageView = [UIImageView new];
        _bottomImageView.image = [UIImage imageNamed:@"startpage"];
        _bottomImageView.contentMode = UIViewContentModeScaleAspectFit;
        [self.view addSubview:_bottomImageView];
        [_bottomImageView mas_makeConstraints:^(MASConstraintMaker *make) {
            make.centerX.equalTo(0);
            make.centerY.equalTo(-80);
            make.width.equalTo(200);
            make.height.equalTo(200);
        }];
    }
    return _bottomImageView;
}
-(UIButton *)importAccountBtn{
    if (!_importAccountBtn && [[NSUserDefaults standardUserDefaults] boolForKey:@"ifHasAccount"] == NO) {
        _importAccountBtn = [UIButton buttonWithType: UIButtonTypeSystem];
        _importAccountBtn.backgroundColor = [UIColor whiteColor];
        _importAccountBtn.layer.cornerRadius = 4;
        _importAccountBtn.layer.masksToBounds = YES;
        _importAccountBtn.layer.borderWidth = 1;
        _importAccountBtn.tag = 6001;
        _importAccountBtn.layer.borderColor = [UIColor blackColor].CGColor;
        [_importAccountBtn setTitle:NSLocalizedString(@"导入钱包", nil) forState:UIControlStateNormal];
        [_importAccountBtn setTintColor:[UIColor textBlackColor]];
        [_importAccountBtn addTarget:self action:@selector(CreateAccount:) forControlEvents:UIControlEventTouchUpInside];
        [self.view addSubview:_importAccountBtn];
        [_importAccountBtn mas_makeConstraints:^(MASConstraintMaker *make) {
            make.centerY.equalTo(50);
            make.centerX.equalTo(0);
            make.width.equalTo(180);
            make.height.equalTo(40);
        }];
    }
    return _importAccountBtn;
}
-(UIButton *)createAccountBtn{
    if (!_createAccountBtn && [[NSUserDefaults standardUserDefaults] boolForKey:@"ifHasAccount"] == NO) {
        _createAccountBtn = [UIButton buttonWithType: UIButtonTypeSystem];
        _createAccountBtn.backgroundColor = [UIColor whiteColor];
        _createAccountBtn.layer.cornerRadius = 4;
        _createAccountBtn.layer.masksToBounds = YES;
        _createAccountBtn.layer.borderWidth = 1;
        _createAccountBtn.tag = 6002;
        _createAccountBtn.layer.borderColor = [UIColor blackColor].CGColor;
        [_createAccountBtn setTitle:NSLocalizedString(@"创建钱包", nil) forState:UIControlStateNormal];
        [_createAccountBtn setTintColor:[UIColor textBlackColor]];
        [_createAccountBtn addTarget:self action:@selector(CreateAccount:) forControlEvents:UIControlEventTouchUpInside];
        [self.view addSubview:_createAccountBtn];
        [_createAccountBtn mas_makeConstraints:^(MASConstraintMaker *make) {
            make.centerY.equalTo(110);
            make.centerX.equalTo(0);
            make.width.equalTo(180);
            make.height.equalTo(40);
        }];
    }
    return _createAccountBtn;
}
//初始化节点等信息
-(void)systemDataInit{
    MJWeakSelf
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_HIGH, 0), ^{
        [NetManager SysInitCompletionHandler:^(id responseObj, NSError *error) {
            if (!error) {
                if (![[NSString stringWithFormat:@"%@",responseObj[@"resultCode"]] isEqualToString:@"20000"]) {
                    [weakSelf.view showAlert:[NSString stringWithFormat:@"Error:%ld",error.code] DetailMsg:responseObj[@"resultMsg"]];
                    return ;
                }
                SystemInitModel *model = [SystemInitModel parse:responseObj[@"data"]];
                if (model) {
                    weakSelf.systemmodel = model;
                    [CreateAll SaveSystemData:model];
                }
            }else{
                
                [weakSelf.view showAlert:[NSString stringWithFormat:@"Error:%ld",error.code] DetailMsg:error.localizedDescription];
            }
        }];
    });
}

-(void)viewWillDisappear:(BOOL)animated{
    if ([self.db isOpen]) {
        [self.db close];
    }
    [super viewWillDisappear:YES];
    [MobClick endLogPageView:@"NewHomePageVC"];
    //离开页面 停止请求余额
    MJWeakSelf
    if ([[NSUserDefaults standardUserDefaults] boolForKey:@"ifHasAccount"] == YES) {
        dispatch_cancel(weakSelf.time);
    }
    self.navigationController.navigationBar.hidden = YES;
    self.navigationController.hidesBottomBarWhenPushed = YES;
}
-(void)initUI{
    _titleLabel = [UILabel new];
    _titleLabel.font = [UIFont boldSystemFontOfSize:17];
    _titleLabel.textColor = [UIColor textBlackColor];
    _titleLabel.textAlignment = NSTextAlignmentCenter;
    _titleLabel.text =  @"misToken";
    [self.view addSubview:_titleLabel];
    [_titleLabel mas_makeConstraints:^(MASConstraintMaker *make) {
        make.top.equalTo(SafeAreaTopHeight -32);
        make.centerX.equalTo(0);
        make.width.equalTo(200);
        make.height.equalTo(20);
    }];
    //
    _walletBtn = [UIButton buttonWithType: UIButtonTypeCustom];
    [_walletBtn setBackgroundImage:[UIImage imageNamed:@"wallet_code-2"] forState:UIControlStateNormal];
    [_walletBtn addTarget:self action:@selector(QRCodeAction) forControlEvents:UIControlEventTouchUpInside];
    [self.view addSubview:_walletBtn];
    [_walletBtn mas_makeConstraints:^(MASConstraintMaker *make) {
        make.left.equalTo(20);
        make.top.equalTo(SafeAreaTopHeight - 29);
        make.width.equalTo(24);
        make.height.equalTo(24);
    }];
    
    _scanBtn = [UIButton buttonWithType: UIButtonTypeCustom];
    [_scanBtn setBackgroundImage:[UIImage imageNamed:@"wallet_scan"] forState:UIControlStateNormal];
    [_scanBtn addTarget:self action:@selector(scanBtnAction) forControlEvents:UIControlEventTouchUpInside];
    [self.view addSubview:_scanBtn];
    [_scanBtn mas_makeConstraints:^(MASConstraintMaker *make) {
        make.right.equalTo(-20);
        make.top.equalTo(SafeAreaTopHeight - 25);
        make.width.equalTo(18);
        make.height.equalTo(18);
    }];
    
}


- (void)viewDidLoad {
    [super viewDidLoad];
    [self getAccountCointype:MIS Success:^(id response) {
        
    }];
    [self initUI];
    self.walletBalance = [NSMutableArray arrayWithObjects:@0,@0,@0,@0,@0,@0,@0,@0,@0,@0,@0,@0,@0,@0,@0, nil];
    self.tempwalletBalance = [NSMutableArray arrayWithObjects:@0,@0,@0,@0,@0,@0,@0,@0,@0,@0,@0,@0,@0,@0,@0, nil];
    self.amountarray = [NSMutableArray arrayWithObjects:@0,@0,@0,@0,@0,@0,@0,@0,@0,@0,@0,@0,@0,@0,@0, nil];
    self.gainsarray = [NSMutableArray arrayWithObjects:@0,@0,@0,@0,@0,@0,@0,@0,@0,@0,@0,@0,@0,@0,@0, nil];
    self.selectedIndex = 0;
    self.TimeInterval = 10.0;
    self.walletArray = [NSMutableArray new];
    self.walletArrayCopy = [NSMutableArray new];
    if (![[NSUserDefaults standardUserDefaults] objectForKey:@"CurrentCurrencySelected"]) {
        [[NSUserDefaults standardUserDefaults] setObject:@"rmb" forKey:@"CurrentCurrencySelected"];
        [[NSUserDefaults standardUserDefaults] synchronize];
    }
    self.currentCurrencySelected = [[NSUserDefaults standardUserDefaults] objectForKey:@"CurrentCurrencySelected"];
    //注册退出账号通知
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(receivelogout) name:@"userlogout" object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(receivelogin) name:@"userlogin" object:nil];
    
    //1.获得数据库文件的路径
    NSString *doc=[NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES) lastObject];
    NSString *fileName=[doc stringByAppendingPathComponent:@"changeaddress.sqlite"];
    //2.获得数据库
    self.db=[FMDatabase databaseWithPath:fileName];
    
   
//    [self.headInfoView.balanceBtn addTarget:self action:@selector(hideContent:) forControlEvents:UIControlEventTouchUpInside];
//    [self.headInfoView.gainsBtn addTarget:self action:@selector(hideContent:) forControlEvents:UIControlEventTouchUpInside];
}


//没有账号 创建/恢复账号
-(void)CreateAccount:(UIButton *)btn{

    if (btn.tag == 6002) {
        CreateAccountVC *cvc = [CreateAccountVC new];
        [self.navigationController pushViewController:cvc animated:YES];
    }else if(btn.tag == 6001){
       ImportHDWalletVC *imvc = [ImportHDWalletVC new];
        if (self.switchWalletImportWay == 2000 && self.currentPubkeyForAccountInChain) {
            imvc.ifverify = 2000;
            imvc.pubkeyInChain = self.currentPubkeyForAccountInChain;
        }
        [self.navigationController pushViewController:imvc animated:YES];
    }else{
        [self.view showMsg:NSLocalizedString(@"请稍后，正在查询帐号信息", nil)];
        [self getAccountCointype:MIS Success:^(id response) {
            
        }];
    }
    
   
}
//点击进入钱包管理
-(void)walletBtnAction{
    @autoreleasepool {
        NSArray *walletarray = [CreateAll GetWalletNameArray];
        NSMutableArray *array = [NSMutableArray array];
        if (walletarray != nil) {
            for (NSString *walletname in walletarray) {
                MissionWallet *wallet = [CreateAll GetMissionWalletByName:walletname];
                //只显示主钱包
                if(wallet.index == 0 && wallet != nil){
                    [array addObject:wallet];
                }
            }
            
            WalletManagerVC *walletVC = [WalletManagerVC new];
            walletVC.walletArray = [array mutableCopy];
            [self.navigationController pushViewController:walletVC animated:YES];
        }else{
            [self.view showMsg:NSLocalizedString(@"没有钱包", nil)];
        }
    }
   
}
//扫描二维码
-(void)scanBtnAction{
    NSString *username = [CreateAll GetCurrentUserName];
    if (!username) {
        return;
    }
    MissionWallet *walletMIS = [CreateAll GetMissionWalletByName: [NSString stringWithFormat:@"MIS_%@",username]];
    if (!walletMIS) {
        [self.view showMsg:NSLocalizedString(@"没有钱包", nil)];
        return;
    }
    WBQRCodeVC *WBVC = [[WBQRCodeVC alloc] init];
    [self QRCodeScanVC:WBVC];
    MJWeakSelf
    [WBVC setGetQRCodeResult:^(NSString *string) {
        if(VALIDATE_STRING(string)){
            TransactionVC *tranvc = [TransactionVC new];
            if([string isValidBitcoinAddress]){
                for (MissionWallet *wallet in weakSelf.walletArray) {
                    if (wallet.walletType == LOCAL_WALLET && (wallet.coinType == BTC ||wallet.coinType == BTC_TESTNET)) {
                        tranvc.wallet = wallet;
                    }
                }
                tranvc.toAddress = string;
                [weakSelf.navigationController pushViewController:tranvc animated:YES];
            }else if ([CreateAll ValidHexString:string]){
                for (MissionWallet *wallet in weakSelf.walletArray) {
                    if (wallet.walletType == LOCAL_WALLET && (wallet.coinType == ETH)) {
                        tranvc.wallet = wallet;
                    }
                }
                tranvc.toAddress = string;
                [weakSelf.navigationController pushViewController:tranvc animated:YES];
            }else if([string containsString:@"MIS"]){
                for (MissionWallet *wallet in weakSelf.walletArray) {
                    if (wallet.walletType == LOCAL_WALLET && (wallet.coinType == MIS)) {
                        tranvc.wallet = wallet;
                    }
                }
                tranvc.toAddress = [string componentsSeparatedByString:@"@MIS@"].lastObject;
                [weakSelf.navigationController pushViewController:tranvc animated:YES];
            }else if([NSString checkEOSAccount:string] == YES){
                for (MissionWallet *wallet in weakSelf.walletArray) {
                    if (wallet.walletType == LOCAL_WALLET && (wallet.coinType == EOS)) {
                        tranvc.wallet = wallet;
                    }
                }
                tranvc.toAddress = string;
                [weakSelf.navigationController pushViewController:tranvc animated:YES];
            }else if([string containsString:@"eos:new_eos_account-"]){
                EOSHelpRegisterVC *vc = [EOSHelpRegisterVC new];
//                @"eos:new_eos_account-?accountName=%@&activeKey=%@&ownerKey=%@"
                NSString *str1 = [string componentsSeparatedByString:@"accountName="].lastObject;
                NSString *str2 = [str1 componentsSeparatedByString:@"&activeKey="].firstObject;//account
                NSString *str3 = [str1 componentsSeparatedByString:@"activeKey="].lastObject;
                NSString *str4 = [str3 componentsSeparatedByString:@"&ownerKey="].firstObject;//activeKey
                NSString *str5 = [str3 componentsSeparatedByString:@"&ownerKey="].lastObject;//ownerKey
                vc.eosAccount = VALIDATE_STRING(str2);
                vc.eosAccountActiveKey = VALIDATE_STRING(str4);
                vc.eosAccountOwnerKey = VALIDATE_STRING(str5);
                [weakSelf.navigationController pushViewController:vc animated:YES];
            }else{
                UIPasteboard *pasteboard = [UIPasteboard generalPasteboard];
                pasteboard.string = string;
                [weakSelf.view showMsg:[NSString stringWithFormat:@"\"%@\" %@",string, NSLocalizedString(@"已复制", nil)]];
            }
            
            NSLog(@"QRCode result = %@",string);
        }
    }];
}

//左上二维码按钮
-(void)QRCodeAction{
    NSString *username = [CreateAll GetCurrentUserName];
    if (!username) {
        return;
    }
    MissionWallet *walletMIS = [CreateAll GetMissionWalletByName: [NSString stringWithFormat:@"MIS_%@",username]];
    
    if (!walletMIS) {
        [self.view showMsg:NSLocalizedString(@"没有MIS钱包", nil)];
        return;
    }
    ReceiptQRCodeVC *revc = [ReceiptQRCodeVC new];
    revc.wallet = walletMIS;
    [self.navigationController pushViewController:revc animated:YES];
}

////点击进入钱包详情
//-(void)detailBtnAction:(UIButton *)btn{
//    TransactionRecordVC *trvc = [TransactionRecordVC new];
//    trvc.wallet = self.walletArray[btn.tag];
//    [self.navigationController pushViewController:trvc animated:YES];
//}

////点击复制地址
//-(void)addressBtnAction:(UIButton *)btn{
//    MissionWallet *wallet = self.walletArray[btn.tag];
//    UIPasteboard *pasteboard = [UIPasteboard generalPasteboard];
//    pasteboard.string = wallet.address;
//    [self.view showMsg:NSLocalizedString(@"地址已复制", nil)];
//    NSLog(@"addressBtn %ld %@",btn.tag,pasteboard.string);
//}

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
                            // [self.navigationController pushViewController:scanVC animated:YES];
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
                // [self.navigationController pushViewController:scanVC animated:YES];
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
    [weakSelf presentViewController:alertC animated:YES completion:nil];
}
//导入钱包
-(void)importWallet{
    ImportWalletSwitchVC *isvc = [ImportWalletSwitchVC new];
    [self.navigationController pushViewController:isvc animated:YES];
}


#pragma tableView

- (UIView *)tableView:(UITableView *)tableView viewForHeaderInSection:(NSInteger)section{
    if (self.listheaderViewArray.count == 0) {
        return [UIView new];
    }
    WalletSectionHeaderView *view = self.listheaderViewArray[section];
//    SectionHeaderView *view = [\ dequeueReusableSupplementaryViewOfKind:UICollectionElementKindSectionHeader withReuseIdentifier:@"headerV" forIndexPath:indexPath];
    if (section == 0) {
        [view.remindlb setText:NSLocalizedString(@"当前身份下钱包", nil)];
    }else{
        [view.remindlb setText:NSLocalizedString(@"导入的钱包", nil)];
    }
    return view;
}
-(CGFloat)tableView:(UITableView *)tableView heightForHeaderInSection:(NSInteger)section{
    return 20;
}

-(UIView *)tableView:(UITableView *)tableView viewForFooterInSection:(NSInteger)section{
    if (section == 1) {
        return self.footerView;
    }else{
        return nil;
    }
    
}

-(CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath{
    return 65;
}

-(CGFloat)tableView:(UITableView *)tableView heightForFooterInSection:(NSInteger)section{
    if (section == 1) {
        return 50;
    }else{
        return 0;
    }
}
-(NSInteger)numberOfSectionsInTableView:(UITableView *)tableView{
    return 2;
}

-(NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section{
    NSInteger localcount = 0;
    for (MissionWallet *wallet in self.walletArray) {
        if (wallet.walletType == LOCAL_WALLET) {
            localcount ++;
        }
    }
    if (section == 0) {
        return localcount;
    }else{
        return self.walletArray.count - localcount;
    }
}

-(void) swipeTableCell:(WalletListCell*) cell didChangeSwipeState:(MGSwipeState) state gestureIsActive:(BOOL) gestureIsActive{
    MJWeakSelf
    MissionWallet *wallet = nil;
    NSInteger localcount = 0;
    for (MissionWallet *wallet in self.walletArray) {
        if (wallet.walletType == LOCAL_WALLET) {
            localcount++;
        }
    }
    if ([self.tableView indexPathForCell:cell].section == 0) {
        wallet = self.walletArray[[self.tableView indexPathForCell:cell].row];
    }else{
        wallet = self.walletArray[[self.tableView indexPathForCell:cell].row+localcount];
    }
    
    //EOS钱包需要有帐号前提下才能转账收款
    if (wallet.coinType == EOS && wallet.address.length < 12) {
        return;
    }
    
    NSLog(@"swipe  state = %ld",state);
    if (state == MGSwipeStateSwipingLeftToRight) {//收款
        ReceiptQRCodeVC *revc = [ReceiptQRCodeVC new];
        revc.wallet = wallet;
        dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(0.3 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
            [weakSelf.navigationController pushViewController:revc animated:YES];
        });
        
    }
    if(state == MGSwipeStateSwipingRightToLeft){//转账
        TransactionVC *tranvc = [TransactionVC new];
        tranvc.wallet = wallet;
        dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(0.3 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
            [weakSelf.navigationController pushViewController:tranvc animated:YES];
        });
    }
}

-(void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath{
   // [self.titleLabel setText: self.walletArray[indexPath.row].walletName];
   // self.selectedIndex = indexPath.row;
    WalletListCell *cell = [tableView cellForRowAtIndexPath:indexPath];
    
    UIImage *image = cell.iconImageView.image;
    MissionWallet *wallet = nil;
    NSInteger localcount = 0;
    for (MissionWallet *wallet in self.walletArray) {
        if (wallet.walletType == LOCAL_WALLET) {
            localcount++;
        }
    }
    if (indexPath.section == 0) {
        wallet = self.walletArray[indexPath.row];
    }else{
        wallet = self.walletArray[indexPath.row+localcount];
    }
    if (wallet.coinType == BTC || wallet.coinType == BTC_TESTNET || wallet.coinType == ETH) {
        WalletDetailVC *vc = [WalletDetailVC new];
        vc.wallet = wallet;
        vc.iconimage = image;
        vc.symbolname = cell.symboldetaillb.text;
        vc.RMBDollarCurrency = self.RMBDollarCurrency;
        vc.walletArray = [self.walletArrayCopy mutableCopy];
        if ([self.currentCurrencySelected isEqualToString:@"rmb"]) {
            vc.amountstring = cell.rmbvaluelb.text;
        }else{
            vc.amountstring = [NSString stringWithFormat:@"≈%@",cell.valuelb.text];
        }
        if(wallet.coinType == ETH){
            vc.balancestring = [NSString stringWithFormat:@"= %@ ETH", cell.amountlb.text];
        }else{
            vc.balancestring = [NSString stringWithFormat:@"= %@ BTC", cell.amountlb.text];
        }
        
        [self.navigationController pushViewController:vc animated:YES];
    }else if (wallet.coinType == MIS){
        EOSWalletDetailVC *vc = [EOSWalletDetailVC new];
        vc.wallet = wallet;
        vc.iconimage = image;
        vc.symbolname = cell.symboldetaillb.text;
        vc.RMBDollarCurrency = self.RMBDollarCurrency;
        vc.walletArray = [self.walletArrayCopy mutableCopy];
        if(wallet.coinType == MIS){
            vc.balancestring = [NSString stringWithFormat:@"= %@ MIS", cell.amountlb.text];
        }else{
            vc.balancestring = [NSString stringWithFormat:@"= %@ EOS", cell.amountlb.text];
        }
        
        if ([self.currentCurrencySelected isEqualToString:@"rmb"]) {
            vc.amountstring = cell.rmbvaluelb.text;
        }else{
            vc.amountstring = [NSString stringWithFormat:@"≈%@",cell.valuelb.text];
        }
        [self.navigationController pushViewController:vc animated:YES];
        
    }else if (wallet.coinType == EOS){
        if (wallet.ifEOSAccountRegistered == NO) {
            //未注册
            EOSWalletRegister *vc = [EOSWalletRegister new];
            vc.wallet = self.walletArray[indexPath.row];
            [self.navigationController pushViewController:vc animated:YES];
            
        }else{
            //已注册
            EOSWalletDetailVC *vc = [EOSWalletDetailVC new];
            vc.wallet = wallet;
            vc.iconimage = image;
            vc.symbolname = cell.symboldetaillb.text;
            vc.RMBDollarCurrency = self.RMBDollarCurrency;
            vc.walletArray = [self.walletArrayCopy mutableCopy];
            vc.balancestring = [NSString stringWithFormat:@"= %@ EOS", cell.amountlb.text];
            if ([self.currentCurrencySelected isEqualToString:@"rmb"]) {
                vc.amountstring = cell.rmbvaluelb.text;
            }else{
                vc.amountstring = [NSString stringWithFormat:@"≈%@",cell.valuelb.text];
            }
            [self.navigationController pushViewController:vc animated:YES];
        }
    }else if (wallet.coinType == USDT){
        //usdt
        
    }
   
}

-(UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath{
    WalletListCell *cell = [tableView dequeueReusableCellWithIdentifier:@"WalletListCell" forIndexPath:indexPath];
    
    if (cell == nil) {
        cell = [WalletListCell new];
    }
    MissionWallet *wallet = nil;
    NSInteger localcount = 0;
    for (MissionWallet *wallet in self.walletArray) {
        if (wallet.walletType == LOCAL_WALLET) {
            localcount++;
        }
    }
   
    if (indexPath.section == 0) {
        wallet = self.walletArray[indexPath.row];
    }else{
        wallet = self.walletArray[indexPath.row+localcount];
    }
    cell.wallettype = wallet.walletType;
    NSString *address = @"";
    if(wallet.address.length > 20){
        NSString *str1 = [wallet.address substringToIndex:9];
        NSString *str2 = [wallet.address substringFromIndex:wallet.address.length - 10];
        address = [NSString stringWithFormat:@"%@...%@",str1,str2];
    }
    cell.addresslb.text = wallet.address.length > 20?address:wallet.address;
    [cell.qulb setText:NSLocalizedString(@"数量", nil)];
    NSInteger i = [self.walletArrayCopy indexOfObject:wallet];
    if (wallet.coinType == BTC || wallet.coinType == BTC_TESTNET) {//BTC
        cell.symbolNamelb.text = wallet.walletName;
        [cell.iconImageView setImage:[UIImage imageNamed:@"ico_btc"]];
        cell.symboldetaillb.text = NSLocalizedString(@"比特币", nil);
        CGFloat balance = [self.walletBalance[i] doubleValue] + [self.tempwalletBalance[i] doubleValue];
        cell.amountlb.text = [NSString stringWithFormat:@"%.8f", balance];
        cell.valuelb.text = [NSString stringWithFormat:@"$%.2f", balance* self.BTCCurrency];
        cell.rmbvaluelb.text = [NSString stringWithFormat:@"≈¥%.2f", balance * self.BTCCurrency * (self.RMBDollarCurrency / 100.0)];
        self.amountarray[i] = [NSNumber numberWithDouble:balance * self.BTCCurrency];
        self.gainsarray[i] = [NSNumber numberWithDouble:balance * self.BTCCurrency * self.marketProfitModel.btcChangeRate];
        NSLog(@"%lf \n %@ \n %lf",balance,self.amountarray[0],self.BTCCurrency);
    }else if(wallet.coinType == ETH){//ETH
        cell.symbolNamelb.text = wallet.walletName;
        [cell.iconImageView setImage:[UIImage imageNamed:@"ico_eth-1"]];
        cell.symboldetaillb.text = NSLocalizedString(@"以太坊", nil);
        CGFloat ethbalance = [self.walletBalance[i] unsignedIntegerValue] * 1.0/pow(10,18);
        cell.amountlb.text = [NSString stringWithFormat:@"%.8f",ethbalance];
        cell.valuelb.text = [NSString stringWithFormat:@"$%.2f", ethbalance * self.ETHCurrency];
        cell.rmbvaluelb.text = [NSString stringWithFormat:@"≈¥%.2f", ethbalance * self.self.ETHCurrency * (self.RMBDollarCurrency / 100.0)];
        self.amountarray[i] = [NSNumber numberWithDouble:ethbalance * self.ETHCurrency];
        self.gainsarray[i] = [NSNumber numberWithDouble:ethbalance * self.ETHCurrency * self.marketProfitModel.ethChangeRate];
    }else if(wallet.coinType == MIS){
        NSString *name = [wallet.walletName componentsSeparatedByString:@"_"].firstObject;
        NSString *accountname = [wallet.walletName componentsSeparatedByString:@"_"].lastObject;
        cell.addresslb.text = accountname;
        cell.symbolNamelb.text = name;
        [cell.iconImageView setImage:[UIImage imageNamed:@"ico_mis"]];
        cell.symboldetaillb.text = NSLocalizedString(@"misToken", nil);
        cell.amountlb.text = [NSString stringWithFormat:@"%.4f", [self.walletBalance[i] doubleValue]];
        cell.valuelb.text = [NSString stringWithFormat:@"$%.2f", [self.walletBalance[i] doubleValue] * self.MISCurrency];
        cell.rmbvaluelb.text = [NSString stringWithFormat:@"≈¥%.2f", [self.walletBalance[i] doubleValue] * self.MISCurrency * (self.RMBDollarCurrency / 100.0)];
        self.amountarray[i] = [NSNumber numberWithDouble:[self.walletBalance[i] doubleValue] * self.MISCurrency];
    }else if(wallet.coinType == EOS){
        NSString *name = [wallet.walletName componentsSeparatedByString:@"_"].firstObject;
        NSString *accountname = [wallet.walletName componentsSeparatedByString:@"_"].lastObject;
        cell.addresslb.text = accountname;
        cell.symbolNamelb.text = wallet.walletType == LOCAL_WALLET?name:[NSString stringWithFormat:@"EOS(%d)",wallet.index];
        cell.symboldetaillb.text = NSLocalizedString(@"eosio", nil);
        cell.amountlb.text = [NSString stringWithFormat:@"%.4f", [self.walletBalance[i] doubleValue]];
        cell.valuelb.text = [NSString stringWithFormat:@"$%.2f", [self.walletBalance[i] doubleValue] * self.EOSCurrency];
        cell.rmbvaluelb.text = [NSString stringWithFormat:@"≈¥%.2f", [self.walletBalance[i] doubleValue] * self.EOSCurrency * (self.RMBDollarCurrency / 100.0)];
        self.amountarray[i] = [NSNumber numberWithDouble:[self.walletBalance[i] doubleValue] * self.EOSCurrency];
        [cell.iconImageView setImage:[UIImage imageNamed:@"ico_eos"]];
    }else if (wallet.coinType == USDT){
        //usdt
        cell.symbolNamelb.text = wallet.walletName;
        [cell.iconImageView setImage:[UIImage imageNamed:@"usdticon"]];
        cell.symboldetaillb.text = NSLocalizedString(@"TetherUS", nil);
        CGFloat balance = [self.walletBalance[i] doubleValue];
        cell.amountlb.text = [NSString stringWithFormat:@"%.8f", balance];
        cell.valuelb.text = [NSString stringWithFormat:@"$%.2f", balance];
        cell.rmbvaluelb.text = [NSString stringWithFormat:@"≈¥%.2f", balance * (self.RMBDollarCurrency / 100.0)];
        self.amountarray[i] = [NSNumber numberWithDouble:balance];
        self.gainsarray[i] = [NSNumber numberWithDouble:0];
    }
    
    
    BOOL priConfig = [[NSUserDefaults standardUserDefaults] boolForKey:@"PrivacyModeON"];
    if (priConfig == YES) {
        cell.amountlb.text = @"********";
        cell.valuelb.text = @"$***";
        cell.rmbvaluelb.text = @"≈¥***";
    }
    cell.delegate = self;
    MGSwipeButton *leftBtn = [MGSwipeButton buttonWithTitle:NSLocalizedString(@"收款", nil) backgroundColor:[UIColor appBlueColor] padding:30];
    leftBtn.titleLabel.font = [UIFont systemFontOfSize:14];
    cell.leftButtons = @[leftBtn];
    cell.leftSwipeSettings.transition = MGSwipeTransitionDrag;
    
    //configure right buttons
    MGSwipeButton *rightBtn = [MGSwipeButton buttonWithTitle:NSLocalizedString(@"转账", nil) backgroundColor:[UIColor redColor] padding:30];
    rightBtn.titleLabel.font = [UIFont systemFontOfSize:14];
    cell.rightButtons = @[rightBtn];
    cell.rightSwipeSettings.transition = MGSwipeTransitionDrag;

    
    cell.selectionStyle = UITableViewCellSelectionStyleNone;
    return cell;
}
//刷新头部总金额
-(void)refreshTotalAmount{
    CGFloat total = 0;
    CGFloat totalgain = 0;
    if(self.currentSelectedType == WALLET_SELECT_ALL){
        //刷新总金额
        for (int index = 0; index < self.walletArrayCopy.count; index ++) {
            total += ((NSNumber *)self.amountarray[index]).doubleValue;
            totalgain += ((NSNumber *)self.gainsarray[index]).doubleValue;
            NSLog(@"%lf",total);
        }
        
    }else if (self.currentSelectedType == WALLET_SELECT_MIS){
        for (int index = 0; index < self.walletArrayCopy.count; index ++) {
            MissionWallet *w = self.walletArrayCopy[index];
            if (w.coinType == MIS) {
                total = ((NSNumber *)self.amountarray[index]).doubleValue;
            }
            totalgain = 0;
        }
    }else{
        //刷新总金额
        for (int index = 0; index < self.walletArrayCopy.count; index ++) {
            MissionWallet *w = self.walletArrayCopy[index];
            if (w.coinType == MIS) {
                
            }else{
                total += ((NSNumber *)self.amountarray[index]).doubleValue;
                totalgain += ((NSNumber *)self.gainsarray[index]).doubleValue;
            }
            
        }
    }
    NSString *balanceValue = @"0.00";
    NSString *gainvalue = @"0.00";
    if ([self.currentCurrencySelected isEqualToString:@"rmb"]) {
        balanceValue = [NSString stringWithFormat:@"¥%.2f", total * (self.RMBDollarCurrency / 100.0)];
        gainvalue = [NSString stringWithFormat:@"¥%@%.2f",totalgain>=0?@"+":@"", totalgain/100.0 * (self.RMBDollarCurrency / 100.0)];
    }else{
        balanceValue = [NSString stringWithFormat:@"$%.2f", total];
        gainvalue = [NSString stringWithFormat:@"$%@%.2f",totalgain>=0?@"+":@"", totalgain/100.0];
    }
    if (total == 0) {//防止total为0时统计错误
        totalgain = 0;
        total = 1;
    }
    CGFloat rate = totalgain / (1.0 * total);
    NSString *ratestr = [NSString stringWithFormat:@"%@%.2f%%",rate>=0?@"+":@"",rate];
    self.headcontentstr = nil;
    self.headcontentstr = [NSString stringWithFormat:@"%@#%@     %@",balanceValue,gainvalue,ratestr];
    MJWeakSelf
    dispatch_async_on_main_queue(^{
        if (weakSelf.headInfoView.balanceBtn.tag > 2000 || weakSelf.headInfoView.gainsBtn.tag > 2000) {
            if ([weakSelf.headcontentstr containsString:@"$"]) {
                [weakSelf.headInfoView.balanceBtn setTitle:@"$****" forState:UIControlStateNormal];
                [weakSelf.headInfoView.gainsBtn setTitle:[NSString stringWithFormat:@"%@ $****",NSLocalizedString(@"24h收益", nil)] forState:UIControlStateNormal];
            }else{
                [weakSelf.headInfoView.balanceBtn setTitle:@"¥****" forState:UIControlStateNormal];
                [weakSelf.headInfoView.gainsBtn setTitle:[NSString stringWithFormat:@"%@ ¥****",NSLocalizedString(@"24h收益", nil)] forState:UIControlStateNormal];
            }
            
        }else{
            [weakSelf.headInfoView.balanceBtn setTitle:balanceValue forState:UIControlStateNormal];
            [weakSelf.headInfoView.gainsBtn setTitle:[NSString stringWithFormat:@"%@ %@     %@",NSLocalizedString(@"24h收益", nil), gainvalue,ratestr] forState:UIControlStateNormal];
        }
    });

}


-(void)InitTimerRequest{
    //获得队列
    dispatch_queue_t queue = dispatch_get_global_queue(0, 0);
    self.time = nil;
    //创建一个定时器
    self.time = dispatch_source_create(DISPATCH_SOURCE_TYPE_TIMER, 0, 0, queue);
    //设置开始时间
    dispatch_time_t start = dispatch_time(DISPATCH_TIME_NOW, (int64_t)(0.0 * NSEC_PER_SEC));
    //设置时间间隔
    uint64_t interval = (uint64_t)(self.TimeInterval* NSEC_PER_SEC);
    //设置定时器
    dispatch_source_set_timer(self.time, start, interval, 0);
    //设置回调
    MJWeakSelf
    dispatch_source_set_event_handler(self.time, ^{
        NSInteger index = 0;
        @autoreleasepool {
            dispatch_group_t group = dispatch_group_create();
            for (MissionWallet *wallet in weakSelf.walletArray) {
                [weakSelf requestBalance:wallet index:index Group:group];
                index ++;
            }
            dispatch_group_notify(group, dispatch_get_main_queue(), ^{
                //界面刷新
                NSLog(@"任务均完成，刷新界面");
                dispatch_async_on_main_queue(^{
                    [weakSelf.tableView reloadData];
                });
            });
            
            [weakSelf refreshTotalAmount];
        }
       
    });
    //由于定时器默认是暂停的所以我们启动一下
    //启动定时器
    dispatch_resume(self.time);
}
-(void)requestBalance:(MissionWallet *)wallet index:(NSInteger)index Group:(dispatch_group_t)group{
    MJWeakSelf
    if (wallet == nil ) {
        return;
    }
    
    if (wallet.coinType == BTC || wallet.coinType == BTC_TESTNET) {
        NSString *addr;
        if (wallet.changeAddressArray != nil && wallet.changeAddressArray.count > 0) {
            addr = [wallet.changeAddressStr stringByReplacingOccurrencesOfString:@"," withString:@"|"];
        }else{
            addr = wallet.address;
        }
        dispatch_group_enter(group);//
        dispatch_group_async(group,dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
            [NetManager GetBTCTxFromBlockChainAddress:addr PageSize:20 Offset:0 completionHandler:^(id responseObj, NSError *error) {
                dispatch_group_leave(group);//
                @autoreleasepool {
                    if (error) {
                        
                    }else{
                        if (responseObj) {
                            BTCBlockChainListModel *model = [BTCBlockChainListModel parse:responseObj];
                            NSInteger result = 0;
                            for (NSInteger index = 0; index < model.txs.count && index < model.txs.count; index++) {
                                @autoreleasepool {
                                    Tx *tx = model.txs[index];
                                    if (tx.block_height <= 0 && tx.result<0 && index < weakSelf.walletBalance.count) {//转出未确认
                                        result += tx.result;
                                    }
                                }
                            }
                            if(index < weakSelf.tempwalletBalance.count){
                                weakSelf.tempwalletBalance[index] = [NSNumber numberWithDouble:(-result* 1.0/pow(10, 8))];
//                                NSLog(@"wall \n  %@ index %ld addr %@",weakSelf.walletBalance[index],index,addr);
//                                if (index == 9 || index == 10) {
//                                    NSLog(@"\n\\n**************************\n\n\n");
//                                }
                            }
                        }
                    }
                }

            }];
        });
        dispatch_group_enter(group);//
        dispatch_group_async(group, dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
            [NetManager GetBTCUTXOFromBlockChainAddress:addr MinumConfirmations:0 completionHandler:^(id responseObj, NSError *error) {
                dispatch_group_leave(group);//
                @autoreleasepool {
                    if (!error) {
                        if (!responseObj) {
                            return ;
                        }
                        NSArray *utxoarr = [BTCBlockChainUTXOModel parse:responseObj[@"unspent_outputs"]];
                        double amount = 0;
                        
                        for (BTCBlockChainUTXOModel *model in utxoarr) {
                            if(model.tx_output_n == 0 && model.confirmations <1){//转入未确认
                                amount += model.value * 1.0/pow(10, 8);
                            }else if(model.tx_output_n == 0 && model.confirmations >=1){//转入 确认>1
                                amount += model.value * 1.0/pow(10, 8);
                            }else if(model.tx_output_n > 0 && model.confirmations <1){//转出未确认
                                //                            ifneedrefresh = NO;
                                amount += model.value * 1.0/pow(10, 8);
                            }else if(model.tx_output_n > 0 && model.confirmations >=1){//转出 确认>=1
                                amount += model.value * 1.0/pow(10, 8);
                            }
                        }
                        
                        if (index<weakSelf.walletBalance.count) {
                            weakSelf.walletBalance[index] = [NSNumber numberWithDouble:amount];

                        }
                        NSLog(@"wall \n  %@ index %ld addr %@",weakSelf.walletBalance[index],index,addr);
                        if (index >1) {
                            NSLog(@"\n\\n**************************\n\n\n");
                        }
                    }else{

                    }
                }

            }];
        });
    
    }else if (wallet.coinType == ETH){
        dispatch_group_enter(group);//
        dispatch_group_async(group, dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
            [CreateAll GetBalanceETHForWallet:wallet callback:^(BigNumber *balance) {
                dispatch_group_leave(group);
                @autoreleasepool {
                    if (index<weakSelf.walletBalance.count) {
                        weakSelf.walletBalance[index] = [NSNumber numberWithUnsignedInteger:balance.unsignedIntegerValue];
                        NSLog(@"wall \n  %@",weakSelf.walletBalance[index]);
                    }
                }
            }];
        });
    }else if(wallet.coinType == MIS){
        dispatch_group_enter(group);//
        dispatch_group_async(group, dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
            [weakSelf getAccountCointype:MIS Success:^(id response) {
                dispatch_group_leave(group);//
                @autoreleasepool {
                    if (response) {
                        NSString *balancestr = [(NSDictionary *)response objectForKey:@"core_liquid_balance"];
                        NSString *valuestring = [balancestr componentsSeparatedByString:@" "].firstObject;
                        CGFloat balance = valuestring.doubleValue;
//                        NSLog(@"mis blance = %.4f",balance);
                        if (index<weakSelf.walletBalance.count) {
                            weakSelf.walletBalance[index] = [NSNumber numberWithDouble:balance];

                        }
                    }
                }


            }];
        });
    }else if(wallet.coinType == EOS){
        if (![wallet.walletName isEqualToString:@"EOS_"]) {
            dispatch_group_enter(group);//
            dispatch_group_async(group, dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
                    NSString *name = [wallet.walletName componentsSeparatedByString:@"_"].lastObject;
                    [weakSelf getEOSAccount:name Success:^(id response) {
                        dispatch_group_leave(group);
                        @autoreleasepool {
                            if (response) {
                                NSString *balancestr = [(NSDictionary *)response objectForKey:@"core_liquid_balance"];
                                NSString *valuestring = [balancestr componentsSeparatedByString:@" "].firstObject;
                                CGFloat balance = valuestring.doubleValue;
                                NSLog(@"eos blance = %.4f",balance);
                                if (index<weakSelf.walletBalance.count) {
                                    weakSelf.walletBalance[index] = [NSNumber numberWithDouble:balance];
                                }
                            }
                        }
                    }];

            });
        }
    }else if(wallet.coinType == USDT){
        //usdt
        if (index<weakSelf.walletBalance.count) {
            weakSelf.walletBalance[index] = @0;
        }
    }
   
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{

        //获取收益
        [NetManager GetProfitCompletionHandler:^(id responseObj, NSError *error) {
            if (!error) {
                /*{"code":0,"message":"成功","result":{"rmbRate":685.21002197265625,"btcToDollar":6388.67,"ethToDollar":209.9}}*/
                @autoreleasepool {
                    __weak NSDictionary *dic;
                    if ([responseObj containsObjectForKey:@"data"]) {
                        dic = responseObj[@"data"];
                        if (![dic isEqual:[NSNull null]]) {
                            weakSelf.marketProfitModel = nil;
                            weakSelf.marketProfitModel = [MarketProfitModel parse:dic];
                            NSLog(@"%lf",weakSelf.marketProfitModel.btcChangeRate);
                        }
                    }
                }
            }else{
                [weakSelf.view showAlert:[NSString stringWithFormat:@"Error:%ld",error.code] DetailMsg:error.localizedDescription];
            }
        }];

        [NetManager GetMissionRateCompletionHandler:^(id responseObj, NSError *error) {
            if (!error) {
                /*{"code":0,"message":"成功","result":{"rmbRate":685.21002197265625,"btcToDollar":6388.67,"ethToDollar":209.9}}*/
                /*
                 "usdtocnyRate": "1",
                 "eostousdRate": "12",
                 "btctousdRate":"6536.05",
                 "ethtousdRate":"142",
                 "mistousdRate":"142"
                 */
                __weak NSDictionary *dic;
                if ([responseObj containsObjectForKey:@"data"]) {
                    dic = responseObj[@"data"];
                    if ([dic isEqual:[NSNull null]]) {
                        //备用汇率
                        weakSelf.ETHCurrency = [[NSUserDefaults standardUserDefaults] floatForKey:@"ETHCurrency"];
                        weakSelf.BTCCurrency = [[NSUserDefaults standardUserDefaults] floatForKey:@"BTCCurrency"];
                        weakSelf.EOSCurrency = [[NSUserDefaults standardUserDefaults] floatForKey:@"EOSCurrency"];
                        weakSelf.MISCurrency = [[NSUserDefaults standardUserDefaults] floatForKey:@"MISCurrency"];
                        //RMB汇率取上次的
                        weakSelf.RMBDollarCurrency = [[NSUserDefaults standardUserDefaults] floatForKey:@"RMBDollarCurrency"];
                        return ;
                    }
                    if ([dic containsObjectForKey:@"usdtocnyRate"]) {
                        weakSelf.RMBDollarCurrency = ((NSString *)VALIDATE_STRING([dic objectForKey:@"usdtocnyRate"])).doubleValue;
                        [[NSUserDefaults standardUserDefaults] setFloat:weakSelf.RMBDollarCurrency forKey:@"RMBDollarCurrency"];
                    }
                    if ([dic containsObjectForKey:@"eostousdRate"]) {
                        weakSelf.EOSCurrency = ((NSString *)VALIDATE_STRING([dic objectForKey:@"eostousdRate"])).doubleValue;
                        [[NSUserDefaults standardUserDefaults] setFloat:weakSelf.EOSCurrency forKey:@"EOSCurrency"];
                    }
                    if ([dic containsObjectForKey:@"btctousdRate"]) {
                        weakSelf.BTCCurrency = ((NSString *)VALIDATE_STRING([dic objectForKey:@"btctousdRate"])).doubleValue;
                        [[NSUserDefaults standardUserDefaults] setFloat:weakSelf.BTCCurrency forKey:@"BTCCurrency"];
                    }
                    if ([dic containsObjectForKey:@"ethtousdRate"]) {
                        weakSelf.ETHCurrency = ((NSString *)VALIDATE_STRING([dic objectForKey:@"ethtousdRate"])).doubleValue;
                        [[NSUserDefaults standardUserDefaults] setFloat:weakSelf.ETHCurrency forKey:@"ETHCurrency"];
                    }
                    if ([dic containsObjectForKey:@"mistousdRate"]) {
                        weakSelf.MISCurrency = ((NSString *)VALIDATE_STRING([dic objectForKey:@"mistousdRate"])).doubleValue;
                        [[NSUserDefaults standardUserDefaults] setFloat:weakSelf.MISCurrency forKey:@"MISCurrency"];
                    }
                    [[NSUserDefaults standardUserDefaults] synchronize];
                }

            }else{
                //备用汇率
                weakSelf.ETHCurrency = [[NSUserDefaults standardUserDefaults] floatForKey:@"ETHCurrency"];
                weakSelf.BTCCurrency = [[NSUserDefaults standardUserDefaults] floatForKey:@"BTCCurrency"];
                weakSelf.EOSCurrency = [[NSUserDefaults standardUserDefaults] floatForKey:@"EOSCurrency"];
                weakSelf.MISCurrency = [[NSUserDefaults standardUserDefaults] floatForKey:@"MISCurrency"];
                //RMB汇率取上次的
                weakSelf.RMBDollarCurrency = [[NSUserDefaults standardUserDefaults] floatForKey:@"RMBDollarCurrency"];
            }
        }];
    });
}
//切换选择
-(void)selectTypeAction:(UIButton *)btn{
    [self.gainsarray removeAllObjects];
    self.gainsarray = nil;
    self.gainsarray = [[NSMutableArray arrayWithObjects:@0,@0,@0,@0,@0,@0,@0,@0,@0,@0,@0,@0,@0,@0,@0, nil] mutableCopy];
    [self.amountarray removeAllObjects];
    self.amountarray = nil;
    self.amountarray = [[NSMutableArray arrayWithObjects:@0,@0,@0,@0,@0,@0,@0,@0,@0,@0,@0,@0,@0,@0,@0, nil] mutableCopy];
    [self.walletBalance removeAllObjects];
    self.walletBalance = nil;
    self.walletBalance = [[NSMutableArray arrayWithObjects:@0,@0,@0,@0,@0,@0,@0,@0,@0,@0,@0,@0,@0,@0,@0, nil] mutableCopy];
    [self.tempwalletBalance removeAllObjects];
    self.tempwalletBalance = nil;
    self.tempwalletBalance = [[NSMutableArray arrayWithObjects:@0,@0,@0,@0,@0,@0,@0,@0,@0,@0,@0,@0,@0,@0,@0, nil] mutableCopy];
    
    [self.walletArray removeAllObjects];
//    [self.tableView reloadData];
    if ([[NSUserDefaults standardUserDefaults] boolForKey:@"ifHasAccount"] == YES) {
        dispatch_cancel(self.time);
    }
    [_buttonView setBtnSelected:btn];
    self.currentSelectedType = (WALLET_SELECT_TYPE)btn.tag;
    self.walletArray = [self.walletArrayCopy mutableCopy];
    NSMutableArray <MissionWallet *>*temparr;
    temparr = [self.walletArray mutableCopy];
    
    if (self.currentSelectedType == WALLET_SELECT_ALL) {
        self.walletArray  = [self.walletArrayCopy mutableCopy];
        [self.tableView reloadData];
    }else if (self.currentSelectedType == WALLET_SELECT_MIS){
        for (MissionWallet *wallet in temparr) {
            if (wallet.coinType != MIS) {
                [self.walletArray removeObject:wallet];
            }
        }
        [self.tableView reloadData];
    }else if(self.currentSelectedType == WALLET_SELECT_OTHERS){
        for (MissionWallet *wallet in temparr) {
            if (wallet.coinType == MIS || wallet.coinType == DAPP) {
                [self.walletArray removeObject:wallet];
            }
        }
        [self.tableView reloadData];
    }
    [self InitTimerRequest];
}

#pragma lazy
-(HelpView *)help{
    if (!_help) {
        _help = [HelpView new];
        _help.backBtn.tag = 7000;
        [_help.backBtn addTarget:self action:@selector(hideHelpView:) forControlEvents:UIControlEventTouchUpInside];
        [_help img0];
        [_help img1];
        [_help img2];
        [_help img3];
        _help.alpha = 0;
        [[CustomizedTabBarController sharedCustomizedTabBarController].view addSubview:_help];
        [_help mas_makeConstraints:^(MASConstraintMaker *make) {
            make.edges.equalTo(0);
        }];
    }
    return _help;
}

-(UIView *)footerView{
    if (!_footerView) {
        _footerView = [UIView new];
        _footerView.backgroundColor = [UIColor whiteColor];
        _footerView.frame = CGRectMake(0, ScreenHeight, ScreenWidth, 50);
    }
    return _footerView;
}

-(UIButton *)importBtn{
    if (!_importBtn) {
        _importBtn = [UIButton buttonWithType:UIButtonTypeSystem];
        _importBtn.layer.cornerRadius = 15;
        _importBtn.layer.masksToBounds = YES;
        _importBtn.layer.borderWidth = 0.5;
        _importBtn.layer.borderColor = [UIColor blackColor].CGColor;
        _importBtn.backgroundColor = [UIColor whiteColor];
        _importBtn.tintColor = [UIColor textGrayColor];
        [_importBtn addTarget:self action:@selector(importWallet) forControlEvents:UIControlEventTouchUpInside];
        _importBtn.titleLabel.font = [UIFont systemFontOfSize:12];
        [_importBtn setTitle:NSLocalizedString(@"导入新钱包", nil) forState:UIControlStateNormal];
        [self.footerView addSubview:_importBtn];
        [_importBtn mas_makeConstraints:^(MASConstraintMaker *make) {
            make.centerX.equalTo(0);
            make.centerY.equalTo(0);
            make.width.equalTo(200);
            make.height.equalTo(30);
        }];
//
        
        UIImageView *iv = [UIImageView new];
        iv.image = [UIImage imageNamed:@"tz"];
        [_importBtn addSubview:iv];
        [iv mas_makeConstraints:^(MASConstraintMaker *make) {
            make.centerX.equalTo(-70);
            make.centerY.equalTo(0);
            make.width.height.equalTo(15);
        }];
        
    }
    return _importBtn;
}

-(UITableView *)tableView{
    if (!_tableView) {
        //_tableView = [[UITableView alloc]initWithFrame:CGRectMake(0, 260, ScreenWidth, 100) style:UITableViewStyleGrouped];
        _tableView = [UITableView new];
        _tableView.dataSource = self;
        _tableView.delegate = self;
//        UIView *view = [[UIView alloc] init];
//        _tableView.tableFooterView = view;
        _tableView.tableFooterView = self.footerView;
        _tableView.contentInset = UIEdgeInsetsMake(0, 0, -50, 0);
        [_tableView registerClass:[WalletListCell class] forCellReuseIdentifier:@"WalletListCell"];
        [self.view addSubview:_tableView];
        [_tableView mas_makeConstraints:^(MASConstraintMaker *make) {
            make.top.equalTo(SafeAreaTopHeight + 196);
            make.left.right.equalTo(0);
            make.bottom.equalTo(-49);
        }];

        
        self.listheaderViewArray = [NSMutableArray new];
        for (int i = 0; i < 2; i++) {
            WalletSectionHeaderView *view = [[WalletSectionHeaderView alloc] initWithFrame:CGRectMake(0, 0, ScreenWidth, 10)];
            [self.listheaderViewArray addObject:view];
        }
    }
    return _tableView;
}
-(HeadInfoView *)headInfoView{
    if (!_headInfoView) {
        _headInfoView = [HeadInfoView new];
        _headInfoView.layer.cornerRadius = 5;
        _headInfoView.layer.masksToBounds = YES;
        UIImage *backImage = [[UIImage alloc]createImageWithSize:CGSizeMake(ScreenWidth - 26, 135) gradientColors:@[[UIColor colorWithHexString:@"#4090F7"],[UIColor colorWithHexString:@"#BBA8FF"],[UIColor colorWithHexString:@"#4090F7"]] percentage:@[@(0.3),@(0.7),@(0.3)] gradientType:GradientFromLeftToRight];
        [_headInfoView setBackgroundColor:[UIColor colorWithPatternImage:backImage]];
        [_headInfoView.detailBtn addTarget:self action:@selector(walletBtnAction) forControlEvents:UIControlEventTouchUpInside];
        [self.view addSubview:_headInfoView];
        [_headInfoView mas_makeConstraints:^(MASConstraintMaker *make) {
            make.left.equalTo(13);
            make.right.equalTo(-13);
            make.top.equalTo(SafeAreaTopHeight + 2);
            make.height.equalTo(135);
        }];
    }
    return _headInfoView;
}
-(ControlBtnsView *)buttonView{
    if (!_buttonView) {
        
        _buttonView = [ControlBtnsView new];
        NSInteger miscount = 0;
       
        for (MissionWallet *wallet in self.walletArray) {
            if (wallet.coinType == MIS) {
                miscount ++;
            }
        }
        _buttonView.fontsize = 12;
        
        [_buttonView initButtonsViewWithTitles:@[NSLocalizedString(@"全部", nil), [NSString stringWithFormat:@"MIS(%ld)",miscount], [NSString stringWithFormat:@"%@(%ld)",NSLocalizedString(@"其他", nil),self.walletArray.count - miscount]] Width:ScreenWidth - 120 Height:44];
        _buttonView.lineView.hidden = YES;
        NSInteger index = 0;
        for (UIButton *btn in _buttonView.btnArray) {
            if (index == 0) {
                [_buttonView setBtnSelected:btn];
            }
            btn.tag = index;
            index++;
            [btn addTarget:self action:@selector(selectTypeAction:) forControlEvents:UIControlEventTouchUpInside];
        }
        self.currentSelectedType = 0;
        [self.view addSubview:_buttonView];
        [_buttonView mas_makeConstraints:^(MASConstraintMaker *make) {
            make.top.equalTo(SafeAreaTopHeight + 146);
            make.left.equalTo(0);
            make.right.equalTo(-150);
            make.height.equalTo(44);
        }];
    }
    
    return _buttonView;
}
-(void)dealloc{
    
    [[NSNotificationCenter defaultCenter] removeObserver:self];
}
@end
