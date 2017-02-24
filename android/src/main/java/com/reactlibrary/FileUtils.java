package com.reactlibrary;

/**
 * Created by ram on 24/02/17.
 */

public class FileUtils {
    public static String getFileExt(String fileName) {
        return fileName.substring(fileName.lastIndexOf(".") + 1, fileName.length());
    }
    /**
     * Get fileName from the Absolute Path
     *
     * @param path parameter1
     * @return Returns the filename from the absolute path.
     */
    public static String getResourceNameNoExt(String path) {
        int startAt = path.lastIndexOf("/") + 1;
        int endAt = path.lastIndexOf(".");
        if (startAt < endAt) {
            return path.substring(startAt, endAt);
        }
        return "";
    }
}
