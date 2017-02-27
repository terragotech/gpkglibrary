package com.reactlibrary.utils;

import android.location.Location;

import com.reactlibrary.json.LatLng;
import com.reactlibrary.json.Properties;

import java.io.File;
import java.io.FileOutputStream;
import java.io.InputStream;
import java.io.OutputStream;
import java.util.ArrayList;
import java.util.List;

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

    public static File getFileFromFolder(File folder, String fileName){
        File[] files = folder.listFiles();
        if(files != null) {
            for (File file1 : files) {
                if(file1.isDirectory()){
                    File[] folderFiles = file1.listFiles();
                    for(File file2 : folderFiles){
                        if(file2.getName().equals(fileName)){
                            return file2;
                        }
                    }
                }else{
                    if(file1.getName().equals(fileName)){
                        return file1;
                    }
                }
            }
        }
        return null;
    }

    /**
     * get file from inputstream
     * @param input
     * @param outputFile
     * @return
     */
    public static File writeFileInputStream(InputStream input, File outputFile){
        try {
            OutputStream out = new FileOutputStream(outputFile);
            byte[] buf = new byte[1024];
            int len;
            while((len=input.read(buf))>0){
                out.write(buf,0,len);
            }
            out.close();
            input.close();
        } catch (Exception e) {
            e.printStackTrace();
        }
        return outputFile;
    }

    public static List<LatLng> getLatlngListFromObj(List polygonObj){
        List<LatLng> latLngs = new ArrayList<>();
        for (Object o : polygonObj) {
            List list = (List) o;
            latLngs.add(new LatLng(((double) list.get(1)), (double) list.get(0)));
        }
        return latLngs;
    }
    public static double getDistanceList(List<LatLng> latLngs,Properties properties){
        int size = latLngs.size();
        List<String> list = new ArrayList<>();
        double totalDistance = 0.0;
        for(int i=0;i<size;i++){
            LatLng latLng1 = latLngs.get(i);
            double currentLat = latLng1.getLat();
            double currentLng = latLng1.getLng();
            if(i != 0){
                double prevLat = latLngs.get(i - 1).getLat();
                double preLng = latLngs.get(i - 1).getLng();
                double distance = calculateDistance(currentLat, currentLng, prevLat, preLng);
                distance = 3.281 * distance;
                totalDistance = totalDistance+distance;
                list.add(String.valueOf(distance));
            }
        }
        properties.setDistance(list);
        return totalDistance;
    }
    public static double calculateArea(boolean isPolygon, Properties properties, double totalDistance, List<LatLng> latLngs) {
        double area = 0;
        if (isPolygon) {
            area = getAreaOfPolygon(latLngs);
            properties.setArea(String.valueOf(area));
            properties.setPerimeter(String.valueOf(totalDistance));
        } else {
            properties.setTotalDistance(String.valueOf(totalDistance));
        }
        return area;
    }
    /**
     * It's returns disctance in meter between two latlngs
     *
     * @param currentLat
     * @param currentLng
     * @param prevLat
     * @param preLng
     * @return
     */
    public static float calculateDistance(double currentLat, double currentLng, double prevLat, double preLng) {
        Location fromLocation = new Location("fromLoc");
        Location toLocation = new Location("toLoc");
        fromLocation.setLatitude(currentLat);
        fromLocation.setLongitude(currentLng);
        toLocation.setLatitude(prevLat);
        toLocation.setLongitude(preLng);
        return fromLocation.distanceTo(toLocation);
    }
    public static double getAreaOfPolygon(List<LatLng> latLngs){
        double area = 0;
        double kEarthRadius = 6378137;
        int size = latLngs.size();
        if (size > 2) {
            for (int i = 0; i < size - 1; i++) {
                LatLng p1 = latLngs.get(i);
                LatLng p2 = latLngs.get(i + 1);
                area += degreesToRadians(p2.getLat() - p1.getLng()) * (2 + Math.sin(degreesToRadians(p1.getLat())) + Math.sin(degreesToRadians(p2.getLat())));
            }
            area = area * kEarthRadius * kEarthRadius / 2;
        }
        if(area < 0){
            area = area * (-1);
        }
        return area;
    }
    private static double degreesToRadians(double radius) {
        double PI = 3.14159265358979323846264338327950288;
        return radius * PI / 180;
    }
}
