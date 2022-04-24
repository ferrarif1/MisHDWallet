//
//  NSString+URLString.m
//  AdMoProduct
//
//  Created by Frued on 2018/7/27.
//  Copyright © 2018年 Frued. All rights reserved.
//

#import "NSString+URLString.h"

@implementation NSString (URLString)
- (NSURL *)STR_URLString{
    return [NSURL URLWithString:self];
}
@end
