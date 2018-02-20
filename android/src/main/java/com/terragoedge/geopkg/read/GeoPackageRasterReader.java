package com.terragoedge.geopkg.read;

/**
 * Created by Ganesan on 06/07/16.
 */
public class GeoPackageRasterReader {

    private long ptr;

    static {
        try {
            System.loadLibrary("geopkgraster");
        } catch (Exception e) {
            e.printStackTrace();
        }
    }

    //private native long setGDALDATA(long ptr, String folderPath);
    private native long createGeoPackageRasterReader();

    private native int openGeoPackage(long ptr, String fileName, String gdalPath);

    private native int convertGeoPackage(long ptr, String fileName, String mbtilesName, String tableName, String tmpP);

    private native String getGeoPackageRasterNameListAsJSON(long ptr);

    private native int closeGeoPackage(long ptr);

    public GeoPackageRasterReader() {
        System.out.println("Creating new Object");

        ptr = createGeoPackageRasterReader();
    }

    /*
    public long setGDALDATA(String folderPath){
        return setGDALDATA(ptr,folderPath);
    }*/
    //Open a GeoPackage File from the specified location
    public int openGeoPackage(String fileName, String gdalPath) {
        return openGeoPackage(ptr, fileName, gdalPath);
    }

    public int convertGeoPackage(String fileName, String mbtileName, String tableName, String tmpPath) {
        return convertGeoPackage(ptr, fileName, mbtileName, tableName, tmpPath);
    }

    //Get a list of Raster name in a JSON format
    public String getGeoPackageRasterNameListAsJSON() {
        return getGeoPackageRasterNameListAsJSON(ptr);
    }

    //Close the Geopackage file resourse
    public int closeGeoPackage() {
        return closeGeoPackage(ptr);
    }

}
