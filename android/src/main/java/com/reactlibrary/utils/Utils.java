package com.reactlibrary.utils;

import android.support.annotation.Nullable;

import com.facebook.react.bridge.ReactContext;
import com.facebook.react.bridge.WritableMap;
import com.facebook.react.modules.core.DeviceEventManagerModule;

import java.util.UUID;

/**
 * Created by ram on 27/02/17.
 */

public class Utils {
    public static final String SEND_NOTE_EVENT = "noteImported";
    public static final String SEND_RASTER_EVENT = "rasterImported";
    public static String randomUUID() {
        return UUID.randomUUID().toString();
    }
    public static void sendEvent(ReactContext reactContext,
                                 String eventName,
                                 @Nullable WritableMap params) {
        reactContext.getJSModule(DeviceEventManagerModule.RCTDeviceEventEmitter.class)
                .emit(eventName, params);
    }
    public static final String RASTER_MBTILE_PATH = "rasters/mbtiles";
    public static final String RASTER_SUPPORTED_FILE_PATH = "rasters/assets/";
}
