//
//  CDVWeibo.h
//  WeiboPlugin
//
//  Created by 胡志华 on 16/1/21.
//  Copyright © 2016年 hhland. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <Cordova/CDVPlugin.h>
#import "WeiboSDK.h"

@interface CDVWeibo : CDVPlugin<WeiboSDKDelegate>

@property (nonatomic,strong) NSString *currentCallbackId;
@property (nonatomic,strong) NSString *redirectURI;

- (void)haswb:(CDVInvokedUrlCommand *) cmd;
- (void)share:(CDVInvokedUrlCommand *) cmd;


@end
