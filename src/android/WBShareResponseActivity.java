package com.hhland.cordova.weibo;

import android.app.Activity;
import android.content.Intent;
import android.os.Bundle;

import com.sina.weibo.sdk.api.share.BaseResponse;
import com.sina.weibo.sdk.api.share.IWeiboHandler;
import com.sina.weibo.sdk.constant.WBConstants;

import com.hhland.cordova.weibo.WeiboSharePlugin;

public class WBShareResponseActivity extends Activity implements IWeiboHandler.Response{
	
	@Override
	protected void onCreate(Bundle savedInstanceState) {
		super.onCreate(savedInstanceState);
		WeiboSharePlugin.api.handleWeiboResponse(getIntent(), this);
	}
	
	@Override
	public void onResponse(BaseResponse baseResp) {
		switch (baseResp.errCode) {
		case WBConstants.ErrorCode.ERR_OK:
			WeiboSharePlugin.currentWBCallbackContext.success(WeiboSharePlugin.WEBIO_SUCCESS);
			break;
		case WBConstants.ErrorCode.ERR_CANCEL:
			WeiboSharePlugin.currentWBCallbackContext.error(WeiboSharePlugin.WEBIO_ERR_CANCEL_BY_USER);
			break;
		case WBConstants.ErrorCode.ERR_FAIL:
			WeiboSharePlugin.currentWBCallbackContext.error(WeiboSharePlugin.WEBIO_ERR_SEND_FAIL);
			break;
		}
		this.finish();
	}

	@Override
	public void onNewIntent(Intent intent) {
		super.onNewIntent(intent);
		WeiboSharePlugin.api.handleWeiboResponse(intent, this);
	}
}
