//
//  UserInfoVC.m
//  TaiYiToken
//
//  Created by Frued on 2018/8/21.
//  Copyright © 2018年 Frued. All rights reserved.
//

#import "UserInfoVC.h"
#import "UserInfoHeadView.h"
#import "ImageTextCell.h"
#import "AccountConfigVC.h"
#import "JavascriptWebViewController.h"
#import "LoginVC.h"
#import "UserInfoModel.h"
#import "IdentityVerifyVC.h"
#import "SelectCurrencyTypeVC.h"
#import "AboutUsVC.h"
#import "WalletManagerVC.h"
#import "CustomizedTabBarController.h"
#import "WebVc.h"
#import "HuobiAuthVC.h"
#import "MisHuobiExchangeVC.h"
@interface UserInfoVC ()<UITableViewDelegate,UITableViewDataSource>
@property(nonatomic,strong)UserInfoHeadView *headView;
@property(nonatomic)UITableView *tableView;
@property(nonatomic)UILabel *titleLabel;
@property(nonatomic,strong)NSArray *titleArray1;
@property(nonatomic,strong)NSArray *imageNameArray1;
@property(nonatomic,strong)NSArray *titleArray2;
@property(nonatomic,strong)NSArray *imageNameArray2;
@property(nonatomic,strong)JavascriptWebViewController *jvc;
@property(nonatomic,strong)UserInfoModel *usermodel;
@end

@implementation UserInfoVC
-(void)viewWillAppear:(BOOL)animated{
    [super viewWillAppear:YES];
    self.tabBarController.tabBar.hidden = NO;
    [MobClick beginLogPageView:@"UserInfoVC"];
    self.navigationController.navigationBar.hidden = NO;
    self.navigationController.navigationBar.barStyle = UIStatusBarStyleDefault;
    self.navigationController.hidesBottomBarWhenPushed = NO;
    NSString *username = @"";
    if ([CreateAll isLogin]) {
        username = [CreateAll GetCurrentUserName]?[CreateAll GetCurrentUserName]:@"";
        [self RequestCurrentUser];
    }else{
        username = NSLocalizedString(@"未登录", nil);
    }
    [_headView.usernamebtn setTitle:username forState:UIControlStateNormal];
    if ([[NSUserDefaults standardUserDefaults] boolForKey:@"ifHasAccount"] == YES || (self.usermodel.idCardNo && self.usermodel.realName)) {
        self.titleArray1 =  @[NSLocalizedString(@"钱包管理", nil),NSLocalizedString(@"实名认证", nil), NSLocalizedString(@"账户设置", nil),NSLocalizedString(@"多语言", nil),NSLocalizedString(@"货币单位", nil),NSLocalizedString(@"火币交易", nil)];
        self.titleArray2 = @[NSLocalizedString(@"帮助中心", nil),NSLocalizedString(@"关于我们", nil)];
        self.imageNameArray1 = @[@"own_record",@"own_record-jj",@"own_set",@"own_push",@"own_wallet-ss",@"own_contact"];
        self.imageNameArray2 = @[@"own_help",@"own_contact"];
        
    }else{
        self.titleArray1 =  @[NSLocalizedString(@"钱包管理", nil),NSLocalizedString(@"账户设置", nil),NSLocalizedString(@"多语言", nil),NSLocalizedString(@"货币单位", nil)];
        self.titleArray2 = @[NSLocalizedString(@"帮助中心", nil),NSLocalizedString(@"关于我们", nil)];
        self.imageNameArray1 = @[@"own_record",@"own_set",@"own_push",@"own_wallet-ss"];
        self.imageNameArray2 = @[@"own_help",@"own_contact"];
    }
    [self.tableView reloadData];
    

}

-(void)viewDidDisappear:(BOOL)animated{
    [super viewDidDisappear:YES];
    [MobClick endLogPageView:@"UserInfoVC"];
}


-(void)RequestCurrentUser{
    MJWeakSelf
    [NetManager GETCurrentLoginUserCompletionHandler:^(id responseObj, NSError *error) {
        if (!error) {
            if (![[NSString stringWithFormat:@"%@",responseObj[@"resultCode"]] isEqualToString:@"20000"]) {
                [weakSelf.view showAlert:[NSString stringWithFormat:@"Error:%ld",error.code] DetailMsg:responseObj[@"resultMsg"]];
                return ;
            }
            NSMutableDictionary *dic;
            dic = responseObj[@"data"];
            if([dic isEqual:[NSNull null]]){
//                [weakSelf.view showMsg:NSLocalizedString(@"获取失败！", nil)];
                return;
            }
            UserInfoModel *model =  [UserInfoModel parse:dic];
            [CreateAll SaveCurrentUser:model];
            weakSelf.usermodel = [CreateAll GetCurrentUser];
            NSString *ifShowRemind = [[NSUserDefaults standardUserDefaults] objectForKey:@"ifShowRemind"];
            if (![ifShowRemind isEqualToString:@"1111"]) {
                if (weakSelf.usermodel.mailStatus == 0 && weakSelf.usermodel.mobileStatus == 0) {
                    static dispatch_once_t onceToken;
                    dispatch_once(&onceToken, ^{
                        dispatch_async_on_main_queue(^{
                            [weakSelf.view showAlert:NSLocalizedString(@"注意!", nil) DetailMsg:NSLocalizedString(@"绑定手机/邮箱，当你忘记密码时才能找回", nil)];
                            [[NSUserDefaults standardUserDefaults] setObject:@"1111" forKey:@"ifShowRemind"];
                            [[NSUserDefaults standardUserDefaults] synchronize];
                        });
                    });
                }
            }
        }else{
            [weakSelf.view showAlert:[NSString stringWithFormat:@"Error:%ld",error.code] DetailMsg:error.localizedDescription];
        }
    }];
}


-(void)initUI{
    NSString *username = @"";
    if ([CreateAll isLogin]) {
        username = [CreateAll GetCurrentUserName]?[CreateAll GetCurrentUserName]:@"";
    }else{
        username = NSLocalizedString(@"未登录", nil);
    }
    _headView = [UserInfoHeadView new];
    [_headView.headbtn setImage:[UIImage imageNamed:@"own_pic"] forState:UIControlStateNormal];
    [_headView.headbtn addTarget:self action:@selector(loginAction) forControlEvents:UIControlEventTouchUpInside];
    [_headView.usernamebtn addTarget:self action:@selector(loginAction) forControlEvents:UIControlEventTouchUpInside];
    [_headView.usernamebtn setTitle:username forState:UIControlStateNormal];
    [self.view addSubview:_headView];
    [_headView mas_makeConstraints:^(MASConstraintMaker *make) {
        make.left.right.equalTo(0);
        make.top.equalTo(0);
        make.height.equalTo(100);
    }];
}


//未登录，点击头像登录
-(void)loginAction{
    if (![CreateAll isLogin]) {
        LoginVC *vc = [LoginVC new];
        vc.showBackBtn = YES;
        [self.navigationController pushViewController:vc animated:YES];
    }
}
- (void)viewDidLoad {
    [super viewDidLoad];
    if ([CreateAll isLogin]) {
        self.usermodel = [CreateAll GetCurrentUser];
    }
    self.view.backgroundColor = RGB(250, 250, 250);
    [self initUI];
    
   // self.titleArray1 = @[NSLocalizedString(@"我的数据", nil),NSLocalizedString(@"信用评分", nil)];
  //  self.titleArray2 = @[NSLocalizedString(@"实名认证", nil),NSLocalizedString(@"交易记录", nil),NSLocalizedString(@"消息推送", nil),NSLocalizedString(@"帮助中心", nil),NSLocalizedString(@"账户设置", nil)];
//    self.imageNameArray1 = @[@"own_contact",@"own_wallet-ss"];
//    self.imageNameArray2 = @[@"own_record-jj",@"own_record",@"own_push",@"own_help",@"own_set"];
}
#pragma mark - Table view data source
- (UIView *)tableView:(UITableView *)tableView viewForHeaderInSection:(NSInteger)section{
    return nil;
}
-(CGFloat)tableView:(UITableView *)tableView heightForHeaderInSection:(NSInteger)section{
    return 5;
}

-(UIView *)tableView:(UITableView *)tableView viewForFooterInSection:(NSInteger)section{
    return nil;
}

-(CGFloat)tableView:(UITableView *)tableView heightForFooterInSection:(NSInteger)section{
    return 0;
}

-(CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath{
    return 54;
}
- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
    return 2;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    
    return section == 0?self.titleArray1.count : self.titleArray2.count;
   // return self.titleArray1.count;
}

-(void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath{
    //判断是否登录
    NSInteger verstatus = [CreateAll GetUserIDVerifyStatusForCurrentUser];
    
    //账户设置
    if (indexPath.section == 0) {
        if (indexPath.row == 0) {
            if (![CreateAll isLogin]) {
                [self.view showMsg:NSLocalizedString(@"未登录", nil)];
                return;
            }
            if ([[NSUserDefaults standardUserDefaults] boolForKey:@"ifHasAccount"] == NO) {
                CustomizedTabBarController *tabBarController = [CustomizedTabBarController  sharedCustomizedTabBarController];
                [tabBarController didSelectBarItemAtIndex:0];
            }else{
                WalletManagerVC *vc = [WalletManagerVC new];
                [self.navigationController pushViewController:vc animated:YES];
            }
            
        }else if (indexPath.row == 1) {
            //实名认证 / 账户设置
            
            if (verstatus == -1 || ![CreateAll isLogin]) {
                [self.view showMsg:NSLocalizedString(@"未登录", nil)];
                return;
            }
            if (!([[NSUserDefaults standardUserDefaults] boolForKey:@"ifHasAccount"] == YES || (self.usermodel.idCardNo && self.usermodel.realName))) {
                AccountConfigVC *vc = [AccountConfigVC new];
                [self.navigationController pushViewController:vc animated:YES];
               // [self.view showMsg:NSLocalizedString(@"请先创建/导入钱包", nil)];
                return;
            }
            IdentityVerifyVC *vc = [IdentityVerifyVC new];
            [self.navigationController pushViewController:vc animated:YES];
        }
        else if (indexPath.row == 2) {
            //账户设置 / 多语言
            if (![CreateAll isLogin]) {
                [self selectCurrency:lANGUAGE_CONFIG_TYPE];
                return;
            }
            if (!([[NSUserDefaults standardUserDefaults] boolForKey:@"ifHasAccount"] == YES || (self.usermodel.idCardNo && self.usermodel.realName))) {
                [self selectCurrency:lANGUAGE_CONFIG_TYPE];
                return;
            }
            AccountConfigVC *vc = [AccountConfigVC new];
            [self.navigationController pushViewController:vc animated:YES];
        }else if (indexPath.row == 3){
            if (verstatus == -1 || ![CreateAll isLogin]) {
                [self selectCurrency:COIN_CONFIG_TYPE];
                return;
            }
            if (!([[NSUserDefaults standardUserDefaults] boolForKey:@"ifHasAccount"] == YES || (self.usermodel.idCardNo && self.usermodel.realName))) {
                [self selectCurrency:COIN_CONFIG_TYPE];
                return;
            }
            [self selectCurrency:lANGUAGE_CONFIG_TYPE];
        }else if (indexPath.row == 4){
            [self selectCurrency:COIN_CONFIG_TYPE];
        }else if (indexPath.row == 5){
            if ([[CreateAll GetHuobiAPIKey] isEqualToString:@""] || [[CreateAll GetHuobiAPISecret] isEqualToString:@""]) {
                HuobiAuthVC *vc = [HuobiAuthVC new];
                [self.navigationController pushViewController:vc animated:YES];
                
            }else{
                //交易界面
                [self.navigationController pushViewController:[MisHuobiExchangeVC new] animated:YES];
//                [self presentViewController:[MisHuobiExchangeVC new] animated:YES completion:^{
//                    
//                }];
            }
           
        }
    }else if (indexPath.section == 1){
        if (indexPath.row == 0) {
            //帮助中心
//            英文： http://misnetwork.io.s3-website-us-west-1.amazonaws.com/dev/help/
//            中文：http://misnetwork.io.s3-website-us-west-1.amazonaws.com/dev/zh/help/
            NSString *current = [[NSUserDefaults standardUserDefaults] objectForKey:@"CurrentLanguageSelected"];
            WebVC *webvc = [WebVC new];
            [self.navigationController pushViewController:webvc animated:YES];
            if ([current isEqualToString:@"chinese"]) {
                webvc.urlstring = @"http://misnetwork.io.s3-website-us-west-1.amazonaws.com/dev/zh/help/";
            }else{
                webvc.urlstring = @"http://misnetwork.io.s3-website-us-west-1.amazonaws.com/dev/help/";
            }
            
            
        }else if (indexPath.row == 1){
            AboutUsVC *abvc = [AboutUsVC new];
            [self.navigationController pushViewController:abvc animated:YES];
        }
    }
   
}


- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    ImageTextCell *cell = [tableView dequeueReusableCellWithIdentifier:@"ImageTextCell" forIndexPath:indexPath];
    if ([[NSUserDefaults standardUserDefaults] boolForKey:@"ifHasAccount"] == YES) {
        if (indexPath.section == 0 && indexPath.row == 1) {
            UserInfoModel *user = [CreateAll GetCurrentUser];
            if (user.idCardNo != nil && user.idCardNo.length > 1 && user.realName != nil && user.realName.length > 1) {
                 [cell.detaillb setText:NSLocalizedString(@"", nil)];
            }else{
                 [cell.detaillb setText:NSLocalizedString(@"完善资料，奖励MIS币", nil)];
            }
        }
    }else{
        [cell.detailTextLabel setText:@""];
    }
    if (indexPath.section == 0) {
        [cell.imageView setImage:[UIImage imageNamed:self.imageNameArray1[indexPath.row]]];
        [cell.textlb setText:self.titleArray1[indexPath.row]];
    }else{
        [cell.imageView setImage:[UIImage imageNamed:self.imageNameArray2[indexPath.row]]];
        [cell.textlb setText:self.titleArray2[indexPath.row]];
    }
    cell.selectionStyle = UITableViewCellSelectionStyleNone;
    return cell;
}
-(void)tableView:(UITableView *)tableView willDisplayCell:(UITableViewCell *)cell forRowAtIndexPath:(NSIndexPath *)indexPath{
    cell.separatorInset = UIEdgeInsetsZero;
    cell.layoutMargins  = UIEdgeInsetsZero;
    cell.preservesSuperviewLayoutMargins = NO;
}
-(void)selectCurrency:(CONFIG_TYPE)configType{
    SelectCurrencyTypeVC *svc = [SelectCurrencyTypeVC new];
    svc.configType = configType;
    [self.navigationController pushViewController:svc animated:YES];
}
#pragma lazy
-(UITableView *)tableView{
    if (!_tableView) {
        _tableView = [[UITableView alloc]initWithFrame:CGRectZero style:UITableViewStyleGrouped];
        _tableView.dataSource = self;
        _tableView.delegate = self;
        _tableView.backgroundColor = RGB(250, 250, 250);
        UIView *view = [[UIView alloc] init];
        _tableView.tableFooterView = view;
        [_tableView registerClass:[ImageTextCell class] forCellReuseIdentifier:@"ImageTextCell"];
        [self.view addSubview:_tableView];
        [_tableView mas_makeConstraints:^(MASConstraintMaker *make) {
            make.top.equalTo(100);
            make.left.right.equalTo(0);
            make.bottom.equalTo(0);
        }];
    }
    return _tableView;
}
- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}


@end
