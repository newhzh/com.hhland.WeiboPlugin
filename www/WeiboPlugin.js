/**
 * Created by hzh on 16/1/21.
 */
var exec = require('cordova/exec');

var WeiboPlugin=function(){};

WeiboPlugin.prototype.getAppKey=function(onSuccess,onError){
    exec(onSuccess,onError,'WeiboPlugin','getAppKey',[]);
};

WeiboPlugin.prototype.wbShare=function(onSuccess,onError,params){
    exec(onSuccess,onError,'WeiboPlugin','share',params);
};

WeiboPlugin.prototype.checkWeiboInstalled= function (onSuccess,onError) {
    exec(onSuccess,onError,'WeiboPlugin','haswb',[]);
};

module.exports=new WeiboPlugin();