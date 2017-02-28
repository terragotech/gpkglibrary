
import { NativeModules } from 'react-native';
var React = require('react-native')
var { DeviceEventEmitter, NativeAppEventEmitter, Platform } = React
const { RNGeoPackageLibrary } = NativeModules;
var promisify = require("es6-promisify");
var _libsample = promisify(RNGeoPackageLibrary.LibrarySampleCall);
var _initGeoPackage = promisify(RNGeoPackageLibrary.initGeoPackageatPath);
var _createFeatureClass = promisify(RNGeoPackageLibrary.createFeatureclass);
var _insertFeatureRecord = promisify(RNGeoPackageLibrary.insertFeatureclassRecord);
var _closeGeoPackage = promisify(RNGeoPackageLibrary.closeGeoPackage);

//import
//var _initImport = RNGeoPackageLibrary.initImportGeoPackageforPath;
var _gpkgFileDetails = RNGeoPackageLibrary.getgpkgFileDetails
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
  _gpkgFileDetails(path, callback){
    return _gpkgFileDetails(path, callback)
      .catch(_error)
  },
  _importGeoPackage(gpkgargument, callback){
  	 return _importGeoPackage(gpkgargument, callback)
      .catch(_error)
  },
  subscribe(callback) {
    var emitter = Platform.OS == 'ios' ? NativeAppEventEmitter : DeviceEventEmitter;
    return emitter.addListener("noteImported", callback);
  }
}

export default RNGeoPackageLibrary;