//
//  AppDelegate.m
//  TaiYiToken
//
//  Created by Frued on 2018/8/13.
//  Copyright © 2018年 Frued. All rights reserved.
//

#import "AppDelegate.h"
#import "CustomizedTabBarController.h"
#import "LaunchIntroductionView.h"
#import "NTVLocalized.h"



@interface AppDelegate ()

@end

@implementation AppDelegate


- (BOOL)application:(UIApplication *)application didFinishLaunchingWithOptions:(NSDictionary *)launchOptions {
    //打开crash友好处理
    [NSObject openAllSafeProtectorWithIsDebug:NO block:^(NSException *exception, LSSafeProtectorCrashType crashType) {
        NSLog(@"exception :%@,%lu",exception.userInfo,(unsigned long)crashType);
    }];
    //启动图延迟
   // [NSThread sleepForTimeInterval:2.0];
    [[NTVLocalized sharedInstance] initLanguage];
    NSString *currentSelected = [[NSUserDefaults standardUserDefaults]objectForKey:@"CurrentLanguageSelected"];
    NSString *currency;
    BOOL isEnglish;
    if ([currentSelected isEqualToString:@"english"]) {
        isEnglish = YES;
        [[NSUserDefaults standardUserDefaults] setObject:@"english" forKey:@"CurrentLanguageSelected"];
        currency = @"dollar";
        [[NSUserDefaults standardUserDefaults] synchronize];
        [[NTVLocalized sharedInstance] setLanguage:@"en"];//zh-Hans
    }else if ([currentSelected isEqualToString:@"chinese"]){
        isEnglish = NO;
        [[NSUserDefaults standardUserDefaults] setObject:@"chinese" forKey:@"CurrentLanguageSelected"];
        currency = @"rmb";
        [[NSUserDefaults standardUserDefaults] synchronize];
        [[NTVLocalized sharedInstance] setLanguage:@"zh-Hans"];//zh-Hans
    }else{//没设置过语言 按系统的语言
        NSString *currentLanguage = [[[[NSBundle mainBundle] preferredLocalizations] objectAtIndex:0] copy];
        if ([currentLanguage isEqualToString:@"en"]) {
            isEnglish = YES;
            [[NSUserDefaults standardUserDefaults] setObject:@"english" forKey:@"CurrentLanguageSelected"];
            currency = @"dollar";
            [[NSUserDefaults standardUserDefaults] synchronize];
            [[NTVLocalized sharedInstance] setLanguage:@"en"];//zh-Hans
        }else{
            isEnglish = NO;
            [[NSUserDefaults standardUserDefaults] setObject:@"chinese" forKey:@"CurrentLanguageSelected"];
            currency = @"rmb";
            [[NSUserDefaults standardUserDefaults] synchronize];
            [[NTVLocalized sharedInstance] setLanguage:@"zh-Hans"];//zh-Hans
        }
    }
    
    NSString *currentCurrency = [[NSUserDefaults standardUserDefaults] objectForKey:@"CurrentCurrencySelected"];
    if ([currentCurrency isEqualToString:@"dollar"]) {
        [[NSUserDefaults standardUserDefaults] setObject:@"dollar" forKey:@"CurrentCurrencySelected"];
    }else if([currentCurrency isEqualToString:@"rmb"]){
        [[NSUserDefaults standardUserDefaults] setObject:@"rmb" forKey:@"CurrentCurrencySelected"];
    }else{
       [[NSUserDefaults standardUserDefaults] setObject:currency forKey:@"CurrentCurrencySelected"];
    }
   
    //YES 跌红涨绿 NO 涨红跌绿
    BOOL colorConfig = [[NSUserDefaults standardUserDefaults] boolForKey:@"RiseColorConfig"];
    if(colorConfig != YES){
        [[NSUserDefaults standardUserDefaults] setBool:YES forKey:@"RiseColorConfig"];
    }else{
        [[NSUserDefaults standardUserDefaults] setBool:NO forKey:@"RiseColorConfig"];
    }
    
    NSString *mysymbol = [[NSUserDefaults standardUserDefaults] objectForKey:@"MySymbol"];
    if ([mysymbol isEqual:[NSNull null]] || mysymbol == nil) {
        mysymbol = @"BTC,ETH,EOS,";
        [[NSUserDefaults standardUserDefaults] setObject:mysymbol forKey:@"MySymbol"];
        [[NSUserDefaults standardUserDefaults] synchronize];
    }
    
    [NetManager SysInitCompletionHandler:^(id responseObj, NSError *error) {
        if (!error) {
            if ([[NSString stringWithFormat:@"%@",responseObj[@"resultCode"]] isEqualToString:@"20000"]) {
                NSDictionary *dic;
                dic = responseObj[@"data"];
                SystemInitModel *model = [SystemInitModel parse:dic];
                if(model){
                    [CreateAll SaveSystemData:model];
                }
            }
        }else{
            
        }
    }];
    
    CustomizedTabBarController *csVC = [CustomizedTabBarController sharedCustomizedTabBarController];
    self.window.rootViewController = csVC;
    [self.window makeKeyAndVisible];
    NSArray *arr0 = @[@"201809e1",@"201809e2",@"201809e3"];
    NSArray *arr1 = @[@"201809y1",@"201809y2",@"201809y3"];
    NSString *currentLanguage = [[[[NSBundle mainBundle] preferredLocalizations] objectAtIndex:0] copy];
    
    LaunchIntroductionView *launch = [LaunchIntroductionView sharedWithImages:[currentLanguage isEqualToString:@"en"]?arr0:arr1];
    launch.currentColor = [UIColor backBlueColorA];
    launch.nomalColor = [UIColor textLightGrayColor];
    
   
    //查找之后发现苹果在ios7之后提供了一个新的通知类型：UIApplicationUserDidTakeScreenshotNotification，这个通知会告知注册了此通知的对象已经发生了截屏事件，然后我们就可以在这个事件中实现自己的逻辑。
    //开发者需要显式的调用此函数，日志系统才能工作
    [UMCommonLogManager setUpUMCommonLogManager];
    [UMConfigure setLogEnabled:YES];//设置打开日志
    [UMConfigure setEncryptEnabled:YES];//打开加密传输
    [UMConfigure initWithAppkey:@"5c00a1daf1f556c050000033" channel:@"App Store"];
    return YES;
}
    


- (void)applicationWillResignActive:(UIApplication *)application {
   
}


- (void)applicationDidEnterBackground:(UIApplication *)application {
    
}


- (void)applicationWillEnterForeground:(UIApplication *)application {
   
}


- (void)applicationDidBecomeActive:(UIApplication *)application {
  
}


- (void)applicationWillTerminate:(UIApplication *)application {
 
}


@end
