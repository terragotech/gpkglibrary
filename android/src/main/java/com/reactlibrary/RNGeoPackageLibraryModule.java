package com.reactlibrary;


import com.facebook.react.bridge.Arguments;
import com.facebook.react.bridge.Promise;
import com.facebook.react.bridge.ReactApplicationContext;
import com.facebook.react.bridge.ReactContextBaseJavaModule;
import com.facebook.react.bridge.ReactMethod;
import com.facebook.react.bridge.Callback;
import com.facebook.react.bridge.ReadableArray;
import com.facebook.react.bridge.ReadableMap;
import com.facebook.react.bridge.WritableArray;
import com.facebook.react.bridge.WritableMap;
import com.reactlibrary.enums.NotesType;
import com.reactlibrary.gpkgexport.GpkgExportService;
import com.reactlibrary.gpkgimport.GpkgImportService;
import com.reactlibrary.gpkgimport.PDFAttachmentExtractor;
import com.reactlibrary.utils.FileUtils;
import com.reactlibrary.utils.Utils;

import java.io.File;
import java.util.ArrayList;
import java.util.List;

import mil.nga.geopackage.GeoPackage;
import mil.nga.geopackage.GeoPackageManager;
import mil.nga.geopackage.core.srs.SpatialReferenceSystem;
import mil.nga.geopackage.factory.GeoPackageFactory;
import mil.nga.geopackage.features.user.FeatureColumn;
import mil.nga.geopackage.features.user.FeatureDao;
import mil.nga.geopackage.features.user.FeatureRow;
import mil.nga.geopackage.features.user.FeatureTable;


public class RNGeoPackageLibraryModule extends ReactContextBaseJavaModule {

  public static ReactApplicationContext reactContext = null;
  private GeoPackage geoPackage = null;
  private SpatialReferenceSystem srs = null;
  private FeatureTable currentFeatureTable;
  private GpkgImportService gpkgImportService = null;
  private GpkgExportService gpkgExportService = null;
  private String filePath = "";
  public static String importGuid = "";

  public RNGeoPackageLibraryModule(ReactApplicationContext reactContext) {
    super(reactContext);
    this.reactContext = reactContext;
    gpkgImportService = new GpkgImportService(reactContext);
    gpkgExportService = new GpkgExportService(reactContext,geoPackage);
  }

  @Override
  public String getName() {
    return "RNGeoPackageLibrary";
  }

  @ReactMethod
  public void initGeoPackageatPath(String dbPath,String dbName,Promise promise){
    try {
      srs = new SpatialReferenceSystem();
      srs.setId(4326);
      File dbFolder = new File(dbPath);
      GeoPackageManager geoPackageManager = GeoPackageFactory.getManager(reactContext);
      File dbFile = new File(dbPath+File.separator+dbName+".gpkg");
      if(dbFile.exists()){// delete db if already exist
        dbFile.delete();
      }
      geoPackageManager.createAtPath(dbName,dbFolder);// create db
      geoPackage = geoPackageManager.open(dbName);
    }catch (Exception e){
      e.printStackTrace();
    }
    promise.resolve("true");
  }

  @ReactMethod
  public void LibrarySampleCall(String testString, Callback completionCallback) {
    completionCallback.invoke(testString);
  }
  @ReactMethod
  public void createFeatureclass(ReadableMap readableMap,int geometryType,Promise promise){
    if (geoPackage != null) {
      gpkgExportService.createDefaultFeatureClass();
      List<FeatureColumn> lstFeatureColumns = new ArrayList<>();
      lstFeatureColumns.add(FeatureColumn.createPrimaryKeyColumn(0, "fid"));
      gpkgExportService.addGeometryColumn(geometryType,lstFeatureColumns);
      ReadableArray columnsArray = readableMap.getArray("Columns");
      String tableName = readableMap.getString("FeatureName");
      if(columnsArray != null){
        int size = columnsArray.size();
        for(int i=0;i<size;i++){
          ReadableMap readableMap1 = columnsArray.getMap(i);
          gpkgExportService.addField(readableMap1.getString("columnName"), lstFeatureColumns);
        }
      }
      currentFeatureTable = new FeatureTable(tableName, lstFeatureColumns);
      geoPackage.createFeatureTable(currentFeatureTable);
    }
    promise.resolve("true");
  }

  @ReactMethod
  public void insertFeatureclassRecord(ReadableMap readableMap,int geometryType,Promise promise){
    try {
      String tableName = readableMap.getString("FeatureName");
      String geometry = readableMap.getString("Location");
      FeatureDao currentFeatureClassFeatureDAO = gpkgExportService.insertDefaultTableValue(tableName, geometryType,srs);
      FeatureRow featureRow = currentFeatureClassFeatureDAO.newRow();
      gpkgExportService.addGeometryValuefromJson(geometry,featureRow,currentFeatureTable,currentFeatureClassFeatureDAO);
      ReadableArray columnsArray = readableMap.getArray("values");
      if(columnsArray != null){
        int size = columnsArray.size();
        for(int i=0;i<size;i++){
          ReadableMap readableMap1 = columnsArray.getMap(i);
          String fieldName = readableMap1.getString("columnName");
          String fieldValue = readableMap1.getString("columnValue");
          gpkgExportService.insertValue(fieldName, fieldValue,featureRow,currentFeatureTable);
        }
      }
      currentFeatureClassFeatureDAO.create(featureRow);
    }catch (Exception e){
      e.printStackTrace();
    }
    promise.resolve("true");
  }

  @ReactMethod
  public void closeGeoPackage(Promise promise){
    if(geoPackage != null){
      geoPackage.close();
    }
    promise.resolve("true");
  }

  /**
   * To get all details from gpkg file import
   * @param filePath
   * @param promise
     */
  @ReactMethod
  public void getgpkgFileDetails(String filePath,Promise promise){
    WritableMap resultMap = Arguments.createMap();
    WritableArray geopackages = Arguments.createArray();
    this.filePath = filePath;
    try{
      File file = new File(filePath);
      String fileName = file.getName();
      String extension = FileUtils.getFileExt(fileName);
      if(extension.equals("pdf")){//if file is pdf
        WritableArray geoPackageNames = Arguments.createArray();
        PDFAttachmentExtractor.extractAttachedFiles(file.getPath(), "output target path need to give", geoPackageNames);
        PDFAttachmentExtractor.extractEmbeddedFiles(file.getPath(), "output target path need to give", geoPackageNames);
        if(geoPackageNames.size() > 0){
          WritableMap geopackage = gpkgImportService.parseGeopackageFile(filePath);
          geopackages.pushMap(geopackage);
        }
        importGuid = Utils.randomUUID();
        resultMap.putString("importGuid",importGuid);
      }else if(extension.equals("gpkg")){//if file is gpkg
        WritableMap geopackage = gpkgImportService.parseGeopackageFile(filePath);
        geopackages.pushMap(geopackage);
      }
    }catch (Exception e){
      e.printStackTrace();
    }
    resultMap.putArray("geopackages",geopackages);
    promise.resolve(resultMap);
  }

  /**
   * process geopackage and convert geopackage data to edge data
   * @param geoPackageContent
     */
  @ReactMethod
  public void importGeoPackage(final ReadableMap geoPackageContent,Promise promise){
    gpkgImportService.openFile(filePath);
    ReadableArray featureClasses = geoPackageContent.getArray("featureClasses");
    int featureClassCount = gpkgImportService.getLayerCount();
    List<String> totalLayers = new ArrayList<>();
    int size = featureClasses.size();
    for (int i = 0; i < featureClassCount; i++) {
      String tableName = gpkgImportService.selectLayerByIndex(i);
      totalLayers.add(tableName);
    }

    if(geoPackageContent.hasKey("rasterTiles")){
      final ReadableArray readableArray = geoPackageContent.getArray("rasterTiles");
      int rasterSize = readableArray.size();
      if(rasterSize > 0){
        Thread thread = new Thread(new Runnable() {
          @Override
          public void run() {
            gpkgImportService.convertRasterFile(readableArray.getString(0), filePath,reactContext);
          }
        });
        thread.start();
      }
    }
    for(int i=0;i<size;i++) {
      ReadableMap featureClass = featureClasses.getMap(i);
      String featureClassName = featureClass.getString("name");
      int index = totalLayers.indexOf(featureClassName);
      int currentRow = 0;
      String tableName = gpkgImportService.selectLayerByIndex(index);
        int noteTypeColumnIndex = gpkgImportService.getNoteTypeColumnIndex();
        gpkgImportService.getSelectedLayerDefinition();
        while (gpkgImportService.hasNextFeatureInSelectedLayer()) {
          currentRow++;
          gpkgImportService.getNextRow();
          String geometry = gpkgImportService.getCurrentFeatureGeom();
          if (noteTypeColumnIndex == -1) {//create form note
            gpkgImportService.getCurrentFeatureFields(tableName, geometry, featureClass);
          } else {//create form note
            String noteType = gpkgImportService.getNoteType(noteTypeColumnIndex);
            if (noteType.equals(NotesType.forms.name()) || noteType.equals(NotesType.multiupload.name())) {
              gpkgImportService.getCurrentFeatureFields(tableName, geometry, featureClass);
            } else {//create non form notes
              gpkgImportService.createNonformNote( geometry, featureClass, noteType);
            }
          }
      }
    }
    gpkgImportService.closeGeoPkg();
    promise.resolve("success");
  }
}
