//
//  VerifyMnemonicVC.m
//  TaiYiToken
//
//  Created by Frued on 2018/8/20.
//  Copyright © 2018年 Frued. All rights reserved.
//

#import "VerifyMnemonicVC.h"
#import "CFFlowButtonView.h"
//#import "PBKDF2.h"
#import "CreateAll.h"

@interface VerifyMnemonicVC ()
@property(nonatomic,strong) UIButton *backBtn;
@property(nonatomic)NSMutableArray *mnemonicArray;
@property(nonatomic,strong)CFFlowButtonView *optionButtonView;//
@property(nonatomic,strong)CFFlowButtonView *selectedButtonView;
@property(nonatomic)NSMutableDictionary  *optionbuttonListSelect;//下方选择,只用于初始化
@property(nonatomic,strong) UIButton *nextBtn;
@property(nonatomic,strong)UILabel *headlabel;
@property(nonatomic,strong)MissionWallet *eoswallet;
@end

@implementation VerifyMnemonicVC
-(void)viewWillAppear:(BOOL)animated{
    [super viewWillAppear:YES];
    self.tabBarController.tabBar.hidden = YES;
    self.navigationController.navigationBar.hidden = YES;
    self.navigationController.hidesBottomBarWhenPushed = YES;
    [MobClick beginLogPageView:@"VerifyMnemonicVC"];
}
-(void)viewWillDisappear:(BOOL)animated{
    [super viewWillDisappear:YES];
    self.tabBarController.tabBar.hidden = NO;
    self.navigationController.navigationBar.hidden = NO;
    self.navigationController.hidesBottomBarWhenPushed = NO;
    [MobClick endLogPageView:@"VerifyMnemonicVC"];
}
- (void)popAction{
    [self.navigationController popViewControllerAnimated:YES];
}
- (void)viewDidLoad {
    [super viewDidLoad];
    self.view.backgroundColor = [UIColor whiteColor];
    self.mnemonicArray = [NSMutableArray new];
    self.optionbuttonListSelect = [NSMutableDictionary new];
    //将助记词字符串分割为单词,因使用dic初始化optionView时通过枚举已经打乱了顺序 故无需专门打破顺序
    self.mnemonicArray = [[self.mnemonic componentsSeparatedByString:@" "] mutableCopy];

    _backBtn = [UIButton buttonWithType:UIButtonTypeCustom];
    _backBtn.backgroundColor = [UIColor clearColor];
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
    
    _nextBtn = [UIButton buttonWithType:UIButtonTypeCustom];
    _nextBtn.backgroundColor = [UIColor textBlueColor];
    [_nextBtn gradientButtonWithSize:CGSizeMake(ScreenWidth, 49) colorArray:@[RGB(150, 160, 240),RGB(170, 170, 240)] percentageArray:@[@(0.3),@(1)] gradientType:GradientFromLeftTopToRightBottom];
    [_nextBtn setTitle:NSLocalizedString(@"完成", nil) forState:UIControlStateNormal];
    [_nextBtn addTarget:self action:@selector(nextAction) forControlEvents:UIControlEventTouchUpInside];
    [self.view addSubview:_nextBtn];
    _nextBtn.userInteractionEnabled = YES;
    [_nextBtn mas_makeConstraints:^(MASConstraintMaker *make) {
        make.bottom.equalTo(-SafeAreaBottomHeight);
        make.height.equalTo(49);
        make.left.equalTo(0);
        make.right.equalTo(0);
    }];
    
    
    _headlabel = [[UILabel alloc] init];
    _headlabel.textColor = [UIColor blackColor];
    _headlabel.font = [UIFont systemFontOfSize:16];
    _headlabel.text = NSLocalizedString(@"确认助记词", nil);
    _headlabel.textAlignment = NSTextAlignmentLeft;
    _headlabel.numberOfLines = 1;
    [self.view addSubview:_headlabel];
    [_headlabel mas_makeConstraints:^(MASConstraintMaker *make) {
        make.left.equalTo(50);
        make.top.equalTo(SafeAreaTopHeight - 34);
        make.right.equalTo(-16);
        make.height.equalTo(25);
    }];

    UILabel *remindlabel = [[UILabel alloc] init];
    remindlabel.textColor = [UIColor textGrayColor];
    remindlabel.font = [UIFont systemFontOfSize:13];
    remindlabel.text = NSLocalizedString(@"请按顺序点击助记词，以确认您正确备份", nil);
    remindlabel.textAlignment = NSTextAlignmentLeft;
    remindlabel.numberOfLines = 0;
    [self.view addSubview:remindlabel];
    [remindlabel mas_makeConstraints:^(MASConstraintMaker *make) {
        make.left.equalTo(10);
        make.top.equalTo(SafeAreaTopHeight);
        make.right.equalTo(-10);
        make.height.equalTo(50);
    }];
    //
    [self initOptionsView];
    
}
-(void)nextAction{

    if (self.selectedButtonView.buttonList == nil||self.selectedButtonView.buttonList.count < 12) {
        [self.view showMsg:NSLocalizedString(@"请按顺序选择所有单词！", nil)];
        return;
    }
   
    for (NSInteger i = 0; i < self.mnemonicArray.count; i++) {
        UIButton *btn = self.selectedButtonView.buttonList[i];
        if (![btn.titleLabel.text isEqualToString:self.mnemonicArray[i]]) {
            [self.view showMsg:NSLocalizedString(@"顺序错误，请重新选择！", nil)];
            return;
        }
    }

    [self.view showMsg:NSLocalizedString(@"正在创建钱包...", nil)];
    [self.view showHUD];
    [self CreateWallet];

}

-(void)CreateWallet{
    
    //512位种子 长度为128字符 64Byte
    NSString *seed = [CreateAll CreateSeedByMnemonic:self.mnemonic Password:self.password];
    
    // MIS & EOS *****************
    //临时存
    [[NSUserDefaults standardUserDefaults] setObject:seed forKey:@"temp_seed"];
    [[NSUserDefaults standardUserDefaults] setObject:self.password forKey:@"temp_password"];
    [[NSUserDefaults standardUserDefaults] setObject:@"" forKey:@"temp_hint"];
    [[NSUserDefaults standardUserDefaults] synchronize];
    [self CreateMISWalletSeed:seed PassWord:self.password PassHint:@""];
   

}
//***********************   mis  ************************//
//创建mis钱包
-(MissionWallet *)CreateEOSWalletPri:(NSString *)pri Pub:(NSString *)pub PassWord:(NSString *)pass PassHint:(NSString *)hint CoinType:(CoinType)type{
    NSString *username = [CreateAll GetCurrentUserName];
    if (!username) {
        return nil;
    }
    MissionWallet *wallet = [MissionWallet new];
    wallet.coinType = type;
    wallet.importType = LOCAL_CREATED_WALLET;
    wallet.walletType = LOCAL_WALLET;
    wallet.index = 0;
    wallet.passwordHint = hint;
    wallet.privateKey = pri;
    wallet.publicKey = pub;
    wallet.walletName = type == MIS?[NSString stringWithFormat:@"%@_%@",@"MIS",username]:@"EOS_";
    wallet.address = type == MIS?username : @"";
    [wallet dataCheck];
    return wallet;
}
//注册mis账户
-(void)RegisterMisWallet:( MissionWallet *)misWallet Password:(NSString *)password{
    CurrentNodes *nodes = [CreateAll GetCurrentNodes];
    if (!nodes) {
        [self.view showMsg:NSLocalizedString(@"Mis节点没得到", nil)];
        return;
    }
    NSString *misnodeurl = nodes.nodeMis;
    NSString *accountname = [misWallet.walletName componentsSeparatedByString:@"_"].lastObject;
    MJWeakSelf
    [NetManager CreateAccountWithAccountName:accountname publickey:misWallet.publicKey nodeUrl:misnodeurl completionHandler:^(id responseObj, NSError *error) {
        if (!error) {
            if (![[NSString stringWithFormat:@"%@",responseObj[@"resultCode"]] isEqualToString:@"20000"]) {
                if ([responseObj[@"resultMsg"] containsString:@"code:3050001"]) {//code:3050001(Account name already exists)
                    [CreateAll setmisWalletisRegistered];
                    [weakSelf.view showAlert:@"" DetailMsg:responseObj[@"resultMsg"]];
                    return;
                }
                [weakSelf.view showAlert:@"" DetailMsg:responseObj[@"resultMsg"]];
                return ;
            }
            [CreateAll SaveWallet:misWallet Name:misWallet.walletName WalletType:LOCAL_WALLET Password:password];
            [CreateAll setmisWalletisRegistered];
            
            [CreateAll SaveWallet:self.eoswallet Name:self.eoswallet.walletName WalletType:LOCAL_WALLET Password:password];
            [[NSUserDefaults standardUserDefaults] setObject:self.eoswallet.walletName forKey:@"LocalEOSWalletName"];
            [[NSUserDefaults standardUserDefaults] synchronize];
            
            NSString *seed = [[NSUserDefaults standardUserDefaults] objectForKey:@"temp_seed"];
            NSString *xprv = [CreateAll CreateExtendPrivateKeyWithSeed:seed];
            CoinType typex = BTC;
            if (ChangeToTESTNET == 0) {
                typex = BTC;
            }else if (ChangeToTESTNET == 1){
                typex = BTC_TESTNET;
            }
            MissionWallet *walletBTC = [CreateAll CreateWalletByXprv:xprv index:0 CoinType:typex Password:password];
            MissionWallet *walletETH = [CreateAll CreateWalletByXprv:xprv index:0 CoinType:ETH Password:password];
            if (!walletBTC || !walletETH) {
                [weakSelf.view showMsg:NSLocalizedString(@"创建出错！", nil)];
                return;
            }
            
            //根据地址存助记词
            [SAMKeychain setPassword:[AESCrypt encrypt:weakSelf.mnemonic password:weakSelf.password] forService:PRODUCT_BUNDLE_ID account:[NSString stringWithFormat:@"mnemonic%@",weakSelf.eoswallet.address]];
            [SAMKeychain setPassword:[AESCrypt encrypt:weakSelf.mnemonic password:weakSelf.password] forService:PRODUCT_BUNDLE_ID account:[NSString stringWithFormat:@"mnemonic%@",walletBTC.address]];
            [SAMKeychain setPassword:[AESCrypt encrypt:weakSelf.mnemonic password:weakSelf.password] forService:PRODUCT_BUNDLE_ID account:[NSString stringWithFormat:@"mnemonic%@",walletETH.address]];
            //创建并存KeyStore eth
            [CreateAll CreateKeyStoreByMnemonic:weakSelf.mnemonic  WalletAddress:walletETH.address Password:weakSelf.password callback:^(Account *account, NSError *error) {
                if (account == nil) {
                    [weakSelf.view showMsg:NSLocalizedString(@"创建出错！", nil)];
                    return ;
                }else{
                    [[NSUserDefaults standardUserDefaults]  setBool:YES forKey:@"ifHasAccount"];
                    [[NSUserDefaults standardUserDefaults] synchronize];
                    [CreateAll SaveWallet:walletBTC Name:@"BTC" WalletType:LOCAL_WALLET Password:weakSelf.password];
                    [CreateAll SaveWallet:walletETH Name:@"ETH" WalletType:LOCAL_WALLET Password:weakSelf.password];
                    [[NSUserDefaults standardUserDefaults] setInteger:200 forKey:@"isFirstUse"];
                    [[NSUserDefaults standardUserDefaults] synchronize];
                    NSString *str = [NSString stringWithFormat:@"%@:MIS,%@:BTC,%@:ETH",[CreateAll GetCurrentUserName],walletBTC.address,walletETH.address];
                    [NetManager AddAccountLogWithuserName:[CreateAll GetCurrentUserName] AccountInfo:str RecordType:CREATE_LOG_TYPE CompletionHandler:^(id responseObj, NSError *error) {
                        if (!error) {
                            if (![[NSString stringWithFormat:@"%@",responseObj[@"resultCode"]] isEqualToString:@"20000"]) {
                                [weakSelf.view showAlert:@"" DetailMsg:responseObj[@"resultMsg"]];
                                return ;
                            }
                        }else{
                            [weakSelf.view showAlert:[NSString stringWithFormat:@"Error:%ld",error.code] DetailMsg:error.localizedDescription];
                        }
                    }];
                    dispatch_async_on_main_queue(^{
                        [weakSelf.view showMsg:NSLocalizedString(@"创建成功！", nil)];
                    });
                    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(2 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
                         [weakSelf.navigationController popToRootViewControllerAnimated:YES];
                    });
                }
            }];
            
            
            [[NSUserDefaults standardUserDefaults] setObject:@"" forKey:@"temp_seed"];
            [[NSUserDefaults standardUserDefaults] setObject:@"" forKey:@"temp_password"];
            [[NSUserDefaults standardUserDefaults] setObject:@"" forKey:@"temp_hint"];
            [[NSUserDefaults standardUserDefaults] synchronize];
        }else{
           [weakSelf.view showAlert:[NSString stringWithFormat:@"Error:%ld",error.code] DetailMsg:error.localizedDescription];
        }
    }];
    
}

//生成mis公私钥
-(void)CreateMISWalletSeed:(NSString *)seed PassWord:(NSString *)password PassHint:(NSString *)hint{
    // MIS & EOS *****************
    
    NSString *mispri = [CreateAll CreateEOSPrivateKeyBySeed:seed Index:0];
    NSString *pubx = [EosEncode eos_publicKey_with_wif:mispri];
    NSString *pub = [pubx stringByReplacingOccurrencesOfString:@"EOS" withString:@"MIS"];
    MissionWallet *miswallet = [self CreateEOSWalletPri:mispri Pub:pub PassWord:password PassHint:hint CoinType:MIS];
    self.eoswallet = [self CreateEOSWalletPri:mispri Pub:pubx PassWord:password PassHint:hint CoinType:EOS];
   
    if (miswallet) {
       [self RegisterMisWallet:miswallet Password:password];
    }
}
-(NSMutableArray*)DicToArray:(NSMutableDictionary*)dic{
    __block NSMutableArray *array = [NSMutableArray new];
    [dic enumerateKeysAndObjectsUsingBlock:^(id  _Nonnull key, id  _Nonnull obj, BOOL * _Nonnull stop) {
        [array addObject:obj];
    }];
    return array;
}
-(void)selectAction:(UIButton *)button{
    [button setSelected:NO];
    
    if (button.tag == 0) {//0 表示点击下面 1 点击上面
        //删除下面的
        UIButton *btn = [UIButton new];
        for (btn in self.optionButtonView.buttonList) {
            if ([btn.titleLabel.text isEqualToString:button.titleLabel.text]) {
                break;
            }
        }
        
        [self.optionButtonView.buttonList removeObject:btn];
        
        //增加上面的
        NSString *mstr = button.titleLabel.text;
        UIButton *mBtn = [UIButton buttonWithType:UIButtonTypeCustom];
        [mBtn gradientButtonWithSize:CGSizeMake(mstr.length*15, 23) colorArray:@[(id)[UIColor textOrangeColor],(id)[UIColor orangeColor]] percentageArray:@[@(0.2),@(1)] gradientType:GradientFromLeftTopToRightBottom];
        mBtn.tag = 1;
        [mBtn.titleLabel setFont:[UIFont systemFontOfSize:15]];
        
        [mBtn setTitle:mstr forState:UIControlStateNormal];
        [mBtn addTarget:self action:@selector(selectAction:) forControlEvents:UIControlEventTouchUpInside];
        mBtn.userInteractionEnabled = YES;
        [self.selectedButtonView.buttonList addObject:mBtn];
    }else{
        //删除上面的
        UIButton *btn = [UIButton new];
        for (btn in self.selectedButtonView.buttonList) {
            if ([btn.titleLabel.text isEqualToString:button.titleLabel.text]) {
                break;
            }
        }
        [self.selectedButtonView.buttonList removeObject:btn];
        
        //增加下面的
        NSString *mstr = button.titleLabel.text;
        UIButton *mBtn = [UIButton buttonWithType:UIButtonTypeCustom];
        [mBtn.titleLabel setFont:[UIFont systemFontOfSize:15]];
        [mBtn gradientButtonWithSize:CGSizeMake(mstr.length*15, 23) colorArray:@[RGB(160, 180, 240),RGB(170, 170, 240)] percentageArray:@[@(0.3),@(1)] gradientType:GradientFromLeftTopToRightBottom];
        mBtn.tag = 0;
        
        
        [mBtn setTitle:mstr forState:UIControlStateNormal];
        [mBtn addTarget:self action:@selector(selectAction:) forControlEvents:UIControlEventTouchUpInside];
        mBtn.userInteractionEnabled = YES;
        [self.optionButtonView.buttonList addObject:mBtn];
    }
    //重绘
    [self.optionButtonView layoutSubviews];
    [self.selectedButtonView layoutSubviews];
}

-(void)initOptionsView{
    for (NSInteger i = 0; i<self.mnemonicArray.count; i++) {
        NSString *mstr = self.mnemonicArray[i];
        UIButton *mBtn = [UIButton buttonWithType:UIButtonTypeCustom];
        mBtn.tag = 0;
        mBtn.frame = CGRectMake(0, 0, mstr.length*15, 23);
        [mBtn.titleLabel setFont:[UIFont systemFontOfSize:15]];
        [mBtn gradientButtonWithSize:CGSizeMake(mstr.length*15, 23) colorArray:@[RGB(150, 160, 240),RGB(170, 170, 240)] percentageArray:@[@(0.3),@(1)] gradientType:GradientFromLeftTopToRightBottom];
        [mBtn setTitle:mstr forState:UIControlStateNormal];
        [mBtn addTarget:self action:@selector(selectAction:) forControlEvents:UIControlEventTouchUpInside];
        mBtn.userInteractionEnabled = YES;
        [self.optionbuttonListSelect setObject:mBtn forKey:mstr];
    }
    
    [self optionButtonView];
    [self selectedButtonView];
    
}
-(CFFlowButtonView *)selectedButtonView{
    if (_selectedButtonView == nil) {
        
        UIView *shadowView = [UIView new];
        shadowView.layer.shadowColor = [UIColor grayColor].CGColor;
        shadowView.layer.shadowOffset = CGSizeMake(0, 0);
        shadowView.layer.shadowOpacity = 1;
        shadowView.layer.shadowRadius = 3.0;
        shadowView.layer.cornerRadius = 3.0;
        shadowView.clipsToBounds = NO;
        [self.view addSubview:shadowView];
        [shadowView mas_makeConstraints:^(MASConstraintMaker *make) {
            make.left.equalTo(10);
            make.right.equalTo(-10);
            make.top.equalTo(SafeAreaTopHeight + 46);
            make.height.equalTo(150);
        }];
        
        _selectedButtonView = [[CFFlowButtonView alloc] initWithButtonList:nil];
        _selectedButtonView.backgroundColor = [UIColor whiteColor];

        [shadowView addSubview:_selectedButtonView];
        [_selectedButtonView mas_makeConstraints:^(MASConstraintMaker *make) {
            make.edges.equalTo(0);
        }];
    }
    return _selectedButtonView;
}

-(CFFlowButtonView *)optionButtonView{
    if (_optionButtonView == nil) {
        _optionButtonView = [[CFFlowButtonView alloc] initWithButtonList:self.optionbuttonListSelect];
        
        [self.view addSubview:_optionButtonView];
        [_optionButtonView mas_makeConstraints:^(MASConstraintMaker *make) {
            make.left.equalTo(10);
            make.right.equalTo(-10);
            make.top.equalTo(SafeAreaTopHeight + 226);
            make.height.equalTo(150);
        }];
    }
    return _optionButtonView;
}
- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

@end
