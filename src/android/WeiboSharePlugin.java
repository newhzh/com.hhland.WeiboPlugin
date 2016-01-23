package com.hhland.cordova.weibo;

import java.io.ByteArrayOutputStream;
import java.io.IOException;
import java.io.InputStream;
import java.net.MalformedURLException;
import java.net.URL;

import org.apache.cordova.CallbackContext;
import org.apache.cordova.CordovaArgs;
import org.apache.cordova.CordovaInterface;
import org.apache.cordova.CordovaPlugin;
import org.apache.cordova.CordovaWebView;
import org.apache.cordova.PluginResult;

import org.json.JSONArray;
import org.json.JSONException;
import org.json.JSONObject;

import com.sina.weibo.sdk.api.ImageObject;
import com.sina.weibo.sdk.api.MusicObject;
import com.sina.weibo.sdk.api.TextObject;
import com.sina.weibo.sdk.api.VideoObject;
import com.sina.weibo.sdk.api.VoiceObject;
import com.sina.weibo.sdk.api.WebpageObject;
import com.sina.weibo.sdk.api.WeiboMessage;
import com.sina.weibo.sdk.api.WeiboMultiMessage;
import com.sina.weibo.sdk.api.share.BaseResponse;
import com.sina.weibo.sdk.api.share.IWeiboHandler;
import com.sina.weibo.sdk.api.share.IWeiboShareAPI;
import com.sina.weibo.sdk.api.share.SendMessageToWeiboRequest;
import com.sina.weibo.sdk.api.share.SendMultiMessageToWeiboRequest;
import com.sina.weibo.sdk.api.share.WeiboShareSDK;
import com.sina.weibo.sdk.auth.AuthInfo;
import com.sina.weibo.sdk.auth.Oauth2AccessToken;
import com.sina.weibo.sdk.auth.WeiboAuthListener;
import com.sina.weibo.sdk.constant.WBConstants;
import com.sina.weibo.sdk.exception.WeiboException;
import com.sina.weibo.sdk.utils.LogUtil;
import com.sina.weibo.sdk.utils.Utility;

import android.graphics.Bitmap;
import android.graphics.BitmapFactory;

public class WeiboSharePlugin extends CordovaPlugin{
	
	private static final String WEBIO_APP_ID = "weibo_app_id";
    private static final String WEBIO_REDIRECT_URL = "redirecturi";
    private static final String DEFAULT_URL = "https://api.weibo.com/oauth2/default.html";
    
    public static final String WEBIO_SUCCESS = "0";
    public static final String WEBIO_ERR_NOT_INSTALLED ="1";
    public static final String WEBIO_ERR_CANCEL_BY_USER = "2";
    public static final String WEBIO_ERR_SHARE_INSDK_FAIL = "3";
    public static final String WEBIO_ERR_SEND_FAIL = "4";
    public static final String WEBIO_ERR_UNSPPORTTED = "5";
    public static final String WEBIO_ERR_AUTH_ERROR = "6";
    public static final String WEBIO_ERR_UNKNOW_ERROR = "7";
    public static final String WEBIO_ERR_USER_CANCEL_INSTALL = "8";
    public static final String WEBIO_ERR_INVALID_OPTIONS ="9";
    public static final String WEBIO_ERR_GET_IMAGE_FAIL ="10";
    
    protected String appKey;
    protected String redirectUrl;
    
    /** 微博微博分享接口实例 */
    public static IWeiboShareAPI  api = null;
    public static CallbackContext currentWBCallbackContext;
    
    @Override
    public void initialize(CordovaInterface cordova, CordovaWebView webView){
    	this.appKey=preferences.getString(WEBIO_APP_ID, "");
    	this.redirectUrl=preferences.getString(WEBIO_REDIRECT_URL, DEFAULT_URL);
    	this.api=WeiboShareSDK.createWeiboAPI(webView.getContext(), this.appKey);
    	//注册app到微博
    	this.api.registerApp();
    }

    @Override
	public boolean execute(String action, JSONArray args, CallbackContext callbackContext) throws JSONException {
        if(action.equals("share")){
        	this.share(args, callbackContext);
			return true;
        }else if(action.equals("getAppKey")){
        	callbackContext.success("got it:"+this.appKey);
        	return true;
        }else if(action.equals("haswb")){
        	this.isInstalled(callbackContext);
        	return true;
        }
        return false;
    }
    
    private void share(JSONArray params, CallbackContext callbackContext) throws JSONException{
    	//参数：
    	//params[0] -- 分享内容的目标 url
		//params[1] -- 标题
		//params[2] -- 描述
		//params[3] -- 图片url
    	if (!api.isWeiboAppInstalled()) {
            callbackContext.error(WEBIO_ERR_NOT_INSTALLED);
            return;
		}
		if (params == null) {
            callbackContext.error(WEBIO_ERR_INVALID_OPTIONS);
            return;
        }
		String webUrl=params.getString(0);
		String title=params.getString(1);
		String description=params.getString(2);
		String imgUrl=params.getString(3);
		
		TextObject obj = new TextObject();
		obj.identify = Utility.generateGUID();
		obj.text=title+webUrl;
		
		try{
			//Bitmap bmp = BitmapFactory.decodeStream(new URL(imgUrl).openStream());
			//obj.setThumbImage(bmp);
			InputStream sm = new URL(imgUrl).openStream();
			byte[] dataImage=getImageBytes(sm);
			obj.thumbData = dataImage;
		}catch(Exception e){
			callbackContext.error(WEBIO_ERR_GET_IMAGE_FAIL);
			return;
		}
		obj.description=description;
		obj.actionUrl=webUrl;
		
		WeiboMessage msg = new WeiboMessage();
		msg.mediaObject=obj;
		
		SendMessageToWeiboRequest req = new SendMessageToWeiboRequest();
		req.transaction=String.valueOf(System.currentTimeMillis());
		req.message=msg;
		
		try {
            boolean success = api.sendRequest(this.cordova.getActivity(),req);
            if (!success) {
                callbackContext.error(WEBIO_ERR_SEND_FAIL);
                return;
            }else{
            	callbackContext.success(WEBIO_SUCCESS);
            }
        } catch (Exception e) {
            callbackContext.error(WEBIO_ERR_SEND_FAIL);
            return;
        }

        currentWBCallbackContext = callbackContext;
    }
    
    private void isInstalled(CallbackContext callbackContext){
    	if (!api.isWeiboAppInstalled()) {
			 callbackContext.error(WEBIO_ERR_NOT_INSTALLED);
		 }else{
			 callbackContext.success(WEBIO_SUCCESS);
		 }
		 currentWBCallbackContext = callbackContext;
    }
    
    private byte[] getImageBytes(InputStream sm) throws IOException{
    	ByteArrayOutputStream buffer = new ByteArrayOutputStream();
    	int nRead;
    	byte[] data = new byte[16384];
    	while ((nRead = sm.read(data, 0, data.length)) != -1) {
    	  buffer.write(data, 0, nRead);
    	}
    	buffer.flush();
    	return buffer.toByteArray();
    }
    
}
