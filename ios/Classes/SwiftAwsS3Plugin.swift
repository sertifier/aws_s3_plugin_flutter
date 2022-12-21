import Flutter
import UIKit
import AWSCognito
import AWSS3
import Foundation

enum ChannelName {
    static let awsS3 = "org.deetechpk/aws_s3_plugin_flutter"
    static let uploadingSatus = "uploading_status"
}

public class SwiftAwsS3Plugin: NSObject, FlutterPlugin {
    private var events: FlutterEventSink?

  public static func register(with registrar: FlutterPluginRegistrar) {
    let channel = FlutterMethodChannel(name: ChannelName.awsS3, binaryMessenger: registrar.messenger())
    let eventChannel = FlutterEventChannel(name: ChannelName.uploadingSatus, binaryMessenger: registrar.messenger())
    let instance = SwiftAwsS3Plugin()
    registrar.addMethodCallDelegate(instance, channel: channel)
    eventChannel.setStreamHandler(instance)

  }

  public func handle(_ call: FlutterMethodCall, result: @escaping FlutterResult) {
        switch (call.method) {
            case "uploadToS3":
                    self.uploadFile(result: result, args: call.arguments)
                    break;
            case "createPreSignedURL":
            self.getPreSignedURL(result: result, args: call.arguments)

            default:
                    result(FlutterMethodNotImplemented)
            }
  }



    func getPreSignedURL(result: @escaping FlutterResult, args: Any?){
    let argsMap = args as! NSDictionary
            if  let awsFolder = argsMap["awsFolder"],
                let fileNameWithExt = argsMap["fileNameWithExt"],
                let bucketName = argsMap["bucketName"], let region = argsMap["region"] , let access = argsMap["AWSAccess"], let secret = argsMap["AWSSecret"] {
                let convertedRegion = decideRegion(region as! String)
            let credentialsProvider = AWSStaticCredentialsProvider(accessKey: access as! String, secretKey: secret as! String)
            let configuration = AWSServiceConfiguration.init(region: convertedRegion, credentialsProvider: credentialsProvider)
            AWSServiceManager.default().defaultServiceConfiguration = configuration


             var preSignedURLString = ""
            let getPreSignedURLRequest = AWSS3GetPreSignedURLRequest()
            getPreSignedURLRequest.httpMethod = AWSHTTPMethod.GET

            let folder = awsFolder as! String
              if (folder != "") {
                  getPreSignedURLRequest.key = folder + "/" + (fileNameWithExt as! String)
              } else {
                  getPreSignedURLRequest.key = (fileNameWithExt as! String)
               }

            getPreSignedURLRequest.bucket = bucketName as! String
            getPreSignedURLRequest.expires = Date(timeIntervalSinceNow: 36000)

            AWSS3PreSignedURLBuilder.default().getPreSignedURL(getPreSignedURLRequest).continueWith { (task:AWSTask<NSURL>) -> Any? in
                if let error = task.error as NSError? {
                    print("Error: \(error)")

                    result(FlutterError(code: "FAILED TO CREATE PRE-SIGNED", message: "Error: \(error)", details: nil))
                    return nil
                }
                preSignedURLString = (task.result?.absoluteString)!
                result(preSignedURLString)
                return nil
            }
         } else {
                    print("Did not provided required args")
                     result(FlutterError(code: "UNAVAILABLE", message: "Did not provided required args", details: nil))
         }
    }


   private func decideRegion(_ region: String) -> AWSRegionType {
       let reg: String = (region as AnyObject).replacingOccurrences(of: "Regions.", with: "")
       switch reg {
           case "Unknown":
               return AWSRegionType.Unknown
       case "US_EAST_1":
           return AWSRegionType.USEast1
       case "US_EAST_2":
           return AWSRegionType.USEast2
       case "US_WEST_1":
           return AWSRegionType.USWest1
       case "US_WEST_2":
           return AWSRegionType.USWest2
       case "EU_WEST_1":
           return AWSRegionType.EUWest1
       case "EU_WEST_2":
           return AWSRegionType.EUWest2
       case "EU_CENTRAL_1":
           return AWSRegionType.EUCentral1
       case "AP_SOUTHEAST_1":
           return AWSRegionType.APSoutheast1
       case "AP_NORTHEAST_1":
           return AWSRegionType.APNortheast1
       case "AP_NORTHEAST_2":
           return AWSRegionType.APNortheast2
       case "AP_SOUTHEAST_2":
           return AWSRegionType.APSoutheast2
       case "AP_SOUTH_1":
           return AWSRegionType.APSouth1
       case "CN_NORTH_1":
           return AWSRegionType.CNNorth1
       case "CA_CENTRAL_1":
           return AWSRegionType.CACentral1
       case "USGovWest1":
           return AWSRegionType.USGovWest1
       case "CN_NORTHWEST_1":
           return AWSRegionType.CNNorthWest1
       case "EU_WEST_3":
           return AWSRegionType.EUWest3
    //    case "US_GOV_EAST_1":
    //        return AWSRegionType.USGovEast1
    //    case "EU_NORTH_1":
    //        return AWSRegionType.EUNorth1
    //    case "AP_EAST_1":
    //        return AWSRegionType.APEast1
    //    case "ME_SOUTH_1":
    //        return AWSRegionType.MESouth1
       default:
           return AWSRegionType.Unknown
       }
   }

    
    private func uploadFile(result: @escaping FlutterResult, args: Any?) {
        
        let argsMap = args as! NSDictionary
        if let filePath = argsMap["filePath"], let awsFolder = argsMap["awsFolder"],
            let fileNameWithExt = argsMap["fileNameWithExt"],
            let bucketName = argsMap["bucketName"], let region = argsMap["region"], let access = argsMap["AWSAccess"], let secret = argsMap["AWSSecret"] {
            
            let convertedRegion = decideRegion(region as! String)
            ///
            let credentialsProvider = AWSStaticCredentialsProvider(accessKey: access as! String, secretKey: secret as! String)
            
            let configuration = AWSServiceConfiguration(region: convertedRegion, credentialsProvider: credentialsProvider)
            ///
            
            
            AWSServiceManager.default().defaultServiceConfiguration = configuration
            var imageAmazonUrl = ""
            let url = NSURL(fileURLWithPath: filePath as! String)
            let fileType: String = (fileNameWithExt as AnyObject).components(separatedBy: ".")[1]
            let uploadRequest = AWSS3TransferManagerUploadRequest()!
            uploadRequest.body = url as URL
            
            let folder = awsFolder as! String
            if (folder != nil && folder != "") {
                uploadRequest.key = folder + "/" + (fileNameWithExt as! String)
            } else {
                uploadRequest.key = (fileNameWithExt as! String)
            }
            
            uploadRequest.bucket = bucketName as? String
            uploadRequest.contentType = "\(fileType)"
            uploadRequest.acl = .public
            uploadRequest.uploadProgress = { (bytesSent, totalBytesSent,
                totalBytesExpectedToSend) -> Void in
                DispatchQueue.main.async(execute: {
                    let uploadedPercentage = Float(totalBytesSent) / (Float(bytesSent) + 0.1)
                    print("byte current \(totalBytesSent) byte total \(bytesSent) percentage \(uploadedPercentage)")
                    print(Int(uploadedPercentage))
                    self.events?(Int(uploadedPercentage))
                })
            }
            
            let transferManager = AWSS3TransferManager.default()
            transferManager.upload(uploadRequest).continueWith { (task) -> AnyObject? in
                if let error = task.error as NSError? {
                    if error.domain == AWSS3TransferManagerErrorDomain as String {
                        if let errorCode = AWSS3TransferManagerErrorType(rawValue: error.code) {
                            switch (errorCode) {
                            case .cancelled, .paused:
                                print("upload failed .cancelled, .paused:")
                                result(FlutterError(code: "upload() failed:", message: "cancelled", details: nil))
                                break;
                            default:
                                print("upload() failed: defaultd [\(error)]")
                                result(FlutterError(code: "upload() failed:", message: "[\(error)]", details: nil))
                                break;
                            }
                        } else {
                            print("upload() failed: [\(error)]")
                            result(FlutterError(code: "upload() failed:", message: "[\(error)]", details: nil))
                        }
                    } else {
                        //upload failed
                        print("upload() failed: domain [\(error)]")
                        result(FlutterError(code: "UNAVAILABLE", message: "domain [\(error)]", details: nil))
                    }
                }
                
                if task.result != nil {
                    print("✅ Upload successed (\(fileNameWithExt))")
                    result(fileNameWithExt)
                }
                return nil
            }
        } else {
            print("Did not provided required args")
             result(FlutterError(code: "UNAVAILABLE", message: "Did not provided required args", details: nil))
        }
    }

}


extension SwiftAwsS3Plugin : FlutterStreamHandler {
    
    public func onListen(withArguments arguments: Any?,
                         eventSink events: @escaping FlutterEventSink) -> FlutterError? {
        self.events = events
        return nil
    }
    
    public func onCancel(withArguments arguments: Any?) -> FlutterError? {
        self.events = nil
        return nil
    }
}
