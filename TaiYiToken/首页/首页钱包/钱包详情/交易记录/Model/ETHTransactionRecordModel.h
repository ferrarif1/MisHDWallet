//
//  ETHTransactionRecordModel.h
//  TaiYiToken
//
//  Created by admin on 2018/9/17.
//  Copyright © 2018年 admin. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface ETHTransactionRecordModel : NSObject
@property (nonatomic, assign) TranResultSelectType selectType;
@property (nonatomic, strong) TransactionInfo *info;
@end
