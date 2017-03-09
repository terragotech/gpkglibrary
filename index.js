
import { NativeModules } from 'react-native';
var React = require('react-native')
var { DeviceEventEmitter, NativeAppEventEmitter, Platform } = React
const { RNGeoPackageLibrary } = NativeModules;

var _libsample = RNGeoPackageLibrary.LibrarySampleCall;
var _initGeoPackage = RNGeoPackageLibrary.initGeoPackageatPath;
var _createFeatureClass = RNGeoPackageLibrary.createFeatureclass;
var _insertFeatureRecord = RNGeoPackageLibrary.insertFeatureclassRecord;
var _closeGeoPackage = RNGeoPackageLibrary.closeGeoPackage;

//import
//var _initImport = RNGeoPackageLibrary.initImportGeoPackageforPath;
var _getgpkgFileDetails = RNGeoPackageLibrary.getgpkgFileDetails
var _importGeoPackage = RNGeoPackageLibrary.importGeoPackage

var GeoPackage = {
  LibrarySampleCall(testString,callback) {
    return _libsample(testString,callback)
      .catch(_error)
  },
  initGeoPackageatPath(directoryPath,fileName, callback){
    return _initGeoPackage(directoryPath,fileName, callback)
      .catch(_error)
  },
  createFeatureclass(featureDict,geomentry, callback){
    return _createFeatureClass(featureDict,geomentry, callback)
      .catch(_error)
  },
  insertFeatureclassRecord(featureRecordDict,geomentry, callback){
    return _insertFeatureRecord(featureRecordDict,geomentry, callback)
      .catch(_error)
  },
  closeGeoPackage(callback){
    return _closeGeoPackage(callback)
      .catch(_error)
  },
  initImportGeoPackageforPath(path, callback){
    return _initImport(path, callback)
      .catch(_error)
  },
  getgpkgFileDetails(path){
    return _getgpkgFileDetails(path)
      .catch(_error)
  },
  importGeoPackage(gpkgargument){
  	 return _importGeoPackage(gpkgargument)
      .catch(_error)
  },
  subscribeNoteImported(callback) {
    var emitter = Platform.OS == 'ios' ? NativeAppEventEmitter : DeviceEventEmitter;
    return emitter.addListener("noteImported", callback);
  },
  subscribeRasterImported(callback) {
    var emitter = Platform.OS == 'ios' ? NativeAppEventEmitter : DeviceEventEmitter;
    return emitter.addListener("rasterImported", callback);
  }
}

export default RNGeoPackageLibrary;