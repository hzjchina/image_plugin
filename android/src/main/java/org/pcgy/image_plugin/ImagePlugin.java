package org.pcgy.image_plugin;

import android.app.Activity;
import android.content.Intent;
import android.os.Build;

import androidx.annotation.NonNull;

import android.os.Handler;
import android.os.Looper;
import android.provider.MediaStore;

import org.pcgy.utils.PathUtil;

import java.util.List;
import java.util.concurrent.ArrayBlockingQueue;
import java.util.concurrent.ThreadPoolExecutor;
import java.util.concurrent.TimeUnit;

import io.flutter.embedding.engine.plugins.FlutterPlugin;
import io.flutter.embedding.engine.plugins.activity.ActivityAware;
import io.flutter.embedding.engine.plugins.activity.ActivityPluginBinding;
import io.flutter.plugin.common.MethodCall;
import io.flutter.plugin.common.MethodChannel;
import io.flutter.plugin.common.MethodChannel.MethodCallHandler;
import io.flutter.plugin.common.MethodChannel.Result;
import io.flutter.plugin.common.PluginRegistry;


public class ImagePlugin implements FlutterPlugin, MethodCallHandler, ActivityAware, PluginRegistry.ActivityResultListener {
  private static final int IMAGE_PICK_REQUEST_CODE = 0x0000F3580;
  private MethodChannel channel;
  private Activity mActivity;
  private Result resultCallBack = null;
  private PathUtil pathUtil = null;
  private static final ThreadPoolExecutor threadPool;

  private static final Handler handler = new Handler(Looper.getMainLooper());
  static {
    handler.hasMessages(0);
    threadPool = new ThreadPoolExecutor(10,20,200, TimeUnit.MINUTES,new ArrayBlockingQueue(10));
  }

  private void initActivity(Activity activity,ActivityPluginBinding binding) {
    mActivity = activity;
    binding.addActivityResultListener(this);
    pathUtil = new PathUtil(mActivity);
  }

  @Override
  public void onAttachedToActivity(@NonNull ActivityPluginBinding binding) {
    initActivity(binding.getActivity(),binding);
  }

  @Override
  public void onDetachedFromActivityForConfigChanges() {
    mActivity = null;
    pathUtil = null;
  }

  @Override
  public void onReattachedToActivityForConfigChanges(@NonNull ActivityPluginBinding binding) {
    initActivity(binding.getActivity(),binding);
  }

  @Override
  public void onDetachedFromActivity() {
    mActivity = null;
  }

  @Override
  public void onAttachedToEngine(@NonNull FlutterPluginBinding flutterPluginBinding) {
    channel = new MethodChannel(flutterPluginBinding.getBinaryMessenger(), "image_plugin");
    channel.setMethodCallHandler(this);
  }

  @Override
  public void onMethodCall(@NonNull MethodCall call, @NonNull Result result) {
    resultCallBack = result;
    if (call.method.equals("getPlatformVersion")) {
      result.success("Android " + android.os.Build.VERSION.RELEASE);
    }else if(call.method.equals("pickImages")){
      int maxImages = call.argument("maxImages");
      pickImages(maxImages);
    } else {
      result.notImplemented();
    }
  }

  @Override
  public void onDetachedFromEngine(@NonNull FlutterPluginBinding binding) {
    channel.setMethodCallHandler(null);
  }

  private void pickImages(final int number){
    threadPool.execute(new Runnable() {
      @Override
      public void run() {
        Intent pickSingleMediaIntent;
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.TIRAMISU) {
          pickSingleMediaIntent = new Intent(MediaStore.ACTION_PICK_IMAGES);
          pickSingleMediaIntent.setType("image/*");
          if(number > 1){
            pickSingleMediaIntent.putExtra(MediaStore.EXTRA_PICK_IMAGES_MAX, number);
          }
        } else {
          pickSingleMediaIntent = new Intent(Intent.ACTION_OPEN_DOCUMENT);
          pickSingleMediaIntent.setType("image/*");
          pickSingleMediaIntent.putExtra(Intent.EXTRA_ALLOW_MULTIPLE,number > 1);
//          pickSingleMediaIntent.addCategory(Intent.CATEGORY_OPENABLE);
//          pickSingleMediaIntent.setType("image/jpeg");
//          pickSingleMediaIntent.setType("image/png");
        }
        if (mActivity != null) {
          mActivity.startActivityForResult(pickSingleMediaIntent, IMAGE_PICK_REQUEST_CODE);
        }
      }
    });

  }

  @Override
  public boolean onActivityResult(int requestCode, int resultCode, Intent data) {
    if(requestCode == IMAGE_PICK_REQUEST_CODE){
     final List<String> paths = pathUtil.handleChooseMultiImageResult(resultCode,data);
      handler.post(new Runnable() {
        @Override
        public void run() {
          resultCallBack.success(paths);
        }
      });
      return true;
    }
    return false;
  }
}
