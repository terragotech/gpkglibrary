package com.terragoedge.geopkg.read;

/**
 * Created by Ganesan on 06/07/16.
 */
public class GeoPackageRasterReader {

    private long ptr;

    static {
        try {
            System.loadLibrary("qwer");
        } catch (Exception e) {
            e.printStackTrace();
        }
    }

    //private native long setGDALDATA(long ptr, String folderPath);
    private native long createGeoPackageRasterReader();

    private native int openGeoPackage(long ptr, String fileName, String gdalPath);

    private native int convertGeoPackage(long ptr, String fileName, String mbtilesName, String tableName, String tmpP);

    private native String getGeoPackageRasterNameListAsJSON(long ptr);

    private native int initiateGeoPackageToMBTilesConversion(long ptr,
                                                             String tileSourceName,
                                                             int zoomLevels,
                                                             int zlevel,
                                                             int quality,
                                                             int imgFormat,
                                                             String mbtilesName
    );

    private native int cancelGeoPackageToMBTilesConversion(long ptr);

    private native double getGeoPackageToMBTileConversionStatus(long ptr);

    private native int getGeoPackageRasterReaderState(long ptr);

    private native int closeGeoPackage(long ptr);

    private native int destroyGeoPackageRasterReader(long ptr);

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

    //Invoke the GeoPkg to MBTiles conversion, with
    //the option for creating MBTiles in different tile formats
    public int initiateGeoPackageToMBTilesConversion(
            String tileSourceName,
            int zoomLevels,
            int zlevel,
            int quality,
            int imgFormat,
            String mbtilesName) {
        return initiateGeoPackageToMBTilesConversion(
                ptr, tileSourceName,
                zoomLevels, zlevel, quality, imgFormat, mbtilesName);
    }

    //Cancel the on going creation process
    public int cancelGeoPackageToMBTilesConversion() {
        return cancelGeoPackageToMBTilesConversion(ptr);
    }

    //Call to get the MBTiles conversion status
    public double getGeoPackageToMBTileConversionStatus() {
        return getGeoPackageToMBTileConversionStatus(ptr);
    }

    //Call to get the status of the GeoPackageRasterReader
    public int getGeoPackageRasterReaderState() {
        return getGeoPackageRasterReaderState(ptr);
    }

    //Close the Geopackage file resourse
    public int closeGeoPackage() {
        System.out.println("closing object");

        return closeGeoPackage(ptr);
    }

    //Call this to destroyGeoPackage reference
    public int destroyGeoPackageRasterReader() {
        return destroyGeoPackageRasterReader(ptr);
    }
}
