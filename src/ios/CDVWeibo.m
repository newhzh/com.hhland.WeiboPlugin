//
//  CDVWeibo.m
//  WeiboPlugin
//
//  Created by 胡志华 on 16/1/21.
//  Copyright © 2016年 hhland. All rights reserved.
//

#import "CDVWeibo.h"

@implementation CDVWeibo

static int const WEBIO_THUMB_SIZE=320;

NSString *WEBIO_APP_ID = @"weibo_app_id";
NSString *WEBIO_REDIRECT_URI = @"redirecturi";
NSString *WEBIO_DEFUALT_REDIRECT_URI = @"https://api.weibo.com/oauth2/default.html";

NSString *WEBIO_ERR_CANCEL_BY_USER = @"cancel by user";
NSString *WEBIO_ERR_SHARE_INSDK_FAIL = @"share in sdk failed";
NSString *WEBIO_ERR_SEND_FAIL = @"send failed";
NSString *WEBIO_ERR_UNSPPORTTED = @"Weibo unspport";
NSString *WEBIO_ERR_AUTH_ERROR = @"Weibo auth error";
NSString *WEBIO_ERR_UNKNOW_ERROR = @"Weibo unknow error";
NSString *WEBIO_ERR_USER_CANCEL_INSTALL = @"user cancel install weibo";
NSString *WEBIO_ERR_NOT_INSTALLED =@"Weibo not installed";
NSString *WEBIO_ERR_INVALID_OPTIONS =@"Weibo invalid options";
NSString *WEBIO_SUCCESS = @"0";

- (void)pluginInitialize{
    NSString *appId = [[self.commandDelegate settings] objectForKey:WEBIO_APP_ID];
    NSString *uri =[[self.commandDelegate settings] objectForKey:WEBIO_REDIRECT_URI];
    if (uri==nil) {
        self.redirectURI=WEBIO_REDIRECT_URI;
    }else{
        self.redirectURI=uri;
    }
    BOOL regSuccess = [WeiboSDK registerApp:appId];
    
    NSLog(@"weibo_appid:%@",appId);
    NSLog(@"weibo_reg result:%@",regSuccess?@"微博注册成功":@"微博注册失败");
}

-(void)haswb:(CDVInvokedUrlCommand *)cmd{
    BOOL installed=[WeiboSDK isWeiboAppInstalled];
    CDVPluginResult *result=nil;
    if (installed) {
        result=[CDVPluginResult resultWithStatus:CDVCommandStatus_OK];
    }else{
        result=[CDVPluginResult resultWithStatus:CDVCommandStatus_ERROR];
    }
    [self.commandDelegate sendPluginResult:result callbackId:cmd.callbackId];
}

-(void)share:(CDVInvokedUrlCommand *)cmd{
    CDVPluginResult *result=nil;
    
    //判断手机是否安装微博客户端
    if (![WeiboSDK isWeiboAppInstalled]) {
        result=[CDVPluginResult resultWithStatus:CDVCommandStatus_ERROR messageAsString:WEBIO_ERR_NOT_INSTALLED];
        [self.commandDelegate sendPluginResult:result callbackId:cmd.callbackId];
        return;
    }
    
    //判断参数是否合法
    NSArray *params=cmd.arguments;
    if (!params) {
        result=[CDVPluginResult resultWithStatus:CDVCommandStatus_ERROR messageAsString:WEBIO_ERR_INVALID_OPTIONS];
        [self.commandDelegate sendPluginResult:result callbackId:cmd.callbackId];
        return;
    }
    
    self.currentCallbackId=cmd.callbackId;
    
//    WBAuthorizeRequest *authRequest = [WBAuthorizeRequest request];
//    authRequest.redirectURI = self.redirectURI;
//    authRequest.scope = @"all";
    
    WBSendMessageToWeiboRequest *req=[WBSendMessageToWeiboRequest requestWithMessage:[self getShareMessage:params]];
    req.userInfo = @{@"ShareMessageFrom": @"WeiboPlugin",
                         @"Other_Info_1": [NSNumber numberWithInt:100],
                         @"Other_Info_2": @[@"obj1", @"obj2"],
                         @"Other_Info_3": @{@"key1": @"obj1", @"key2": @"obj2"}};
    BOOL sendSuccess=[WeiboSDK sendRequest:req];
    if (!sendSuccess) {
        result=[CDVPluginResult resultWithStatus:CDVCommandStatus_ERROR messageAsString:WEBIO_ERR_SEND_FAIL];
        [self.commandDelegate sendPluginResult:result callbackId:cmd.callbackId];
        self.currentCallbackId = nil;
    }else{
        result=[CDVPluginResult resultWithStatus:CDVCommandStatus_OK messageAsString:WEBIO_SUCCESS];
        [self.commandDelegate sendPluginResult:result callbackId:cmd.callbackId];
    }
}

-(WBMessageObject *)getShareMessage:(NSArray *)params{
    //params[0] -- 分享内容的目标 url
    //params[1] -- 标题
    //params[2] -- 描述
    //params[3] -- 图片url
    WBMessageObject *message=[WBMessageObject message];
    WBWebpageObject *webObject = [WBWebpageObject object];
    webObject.objectID =[NSString stringWithFormat:@"%f", [[NSDate date] timeIntervalSince1970]];
    webObject.title=params[1];
    webObject.description=params[2];
    webObject.thumbnailData=UIImageJPEGRepresentation([self getUIImageFromURL:params[3]],1.0);
    webObject.webpageUrl=params[0];
    
    [message setMediaObject:webObject];
    return message;
}

- (UIImage *)getUIImageFromURL:(NSString *)url{
    NSData *data = [NSData dataWithContentsOfURL:[NSURL URLWithString:url]];
    UIImage *image = [UIImage imageWithData:data];
    
    if (image.size.width > WEBIO_THUMB_SIZE || image.size.height > WEBIO_THUMB_SIZE){
        CGFloat width = 0;
        CGFloat height = 0;
        if (image.size.width > image.size.height){
            width = WEBIO_THUMB_SIZE;
            height = width * image.size.height / image.size.width;
        }else{
            height = WEBIO_THUMB_SIZE;
            width = height * image.size.width / image.size.height;
        }
        //裁剪
        UIGraphicsBeginImageContext(CGSizeMake(width, height));
        [image drawInRect:CGRectMake(0, 0, width, height)];
        UIImage *scaledImage = UIGraphicsGetImageFromCurrentImageContext();
        UIGraphicsEndImageContext();
        
        return scaledImage;
    }
    
    return image;
}

#pragma mark - WeiboSDKDelegate
-(void)didReceiveWeiboRequest:(WBBaseRequest *)request{
    //收到一个来自微博客户端程序的请求
    //收到微博的请求后，第三方应用应该按照请求类型进行处理，处理完后必须通过 [WeiboSDK sendResponse:] 将结果回传给微博
}

-(void)didReceiveWeiboResponse:(WBBaseResponse *)response{
    //收到一个来自微博客户端程序的响应
    //收到微博的响应后，第三方应用可以通过响应类型、响应的数据和 WBBaseResponse.userInfo 中的数据完成自己的功能
    if(!self.currentCallbackId){
        return;
    }
    
    CDVPluginResult *result=nil;
    if ([response isKindOfClass:[WBSendMessageToWeiboResponse class]]) {
        switch (response.statusCode) {
            case WeiboSDKResponseStatusCodeSuccess:
                result=[CDVPluginResult resultWithStatus:CDVCommandStatus_OK];
                break;
            case WeiboSDKResponseStatusCodeUserCancel:
                result = [CDVPluginResult resultWithStatus:CDVCommandStatus_ERROR messageAsString:WEBIO_ERR_CANCEL_BY_USER];
                break;
            case WeiboSDKResponseStatusCodeSentFail:
                result = [CDVPluginResult resultWithStatus:CDVCommandStatus_ERROR messageAsString:WEBIO_ERR_SEND_FAIL];
                break;
            case WeiboSDKResponseStatusCodeAuthDeny:
                result = [CDVPluginResult resultWithStatus:CDVCommandStatus_ERROR messageAsString:WEBIO_ERR_AUTH_ERROR];
                break;
            case WeiboSDKResponseStatusCodeUnsupport:
                result = [CDVPluginResult resultWithStatus:CDVCommandStatus_ERROR messageAsString:WEBIO_ERR_UNSPPORTTED];
                break;
            case WeiboSDKResponseStatusCodeShareInSDKFailed:
                result = [CDVPluginResult resultWithStatus:CDVCommandStatus_ERROR messageAsString:WEBIO_ERR_SHARE_INSDK_FAIL];
                break;
            default:
                result = [CDVPluginResult resultWithStatus:CDVCommandStatus_ERROR messageAsString:WEBIO_ERR_UNKNOW_ERROR];
                break;
        }
    }
    
    [self.commandDelegate sendPluginResult:result callbackId:self.currentCallbackId];
    self.currentCallbackId=nil;
    
}


@end
