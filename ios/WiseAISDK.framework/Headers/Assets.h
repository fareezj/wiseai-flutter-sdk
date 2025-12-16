//
//  Assets.h
//  WiseAISDK
//
//  Created by JPCHOI on 27/02/2021.
//

#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>
#import <CommonCrypto/CommonCryptor.h>
#import <AVFoundation/AVFoundation.h>

NS_ASSUME_NONNULL_BEGIN

@interface Assets : NSObject

+ (Assets *) sharedInstance;
+ (NSData *) createBodyWithBoundary:(NSString *)boundary
                         parameters:(NSDictionary *)parameters;
+ (NSData *) createBodyWithBoundary:(NSString *)boundary
                        parameters:(NSDictionary *)parameters
                             path:(NSString *)path
                          fieldName:(NSString *)fieldName;
+ (NSData *) createBodyWithBoundary:(NSString *)boundary
                        parameters:(NSDictionary *)parameters
                             paths:(NSArray *)paths
                          fieldName:(NSString *)fieldName;
+ (NSString *) getJsonStringFromJsonDictionary:(NSDictionary *) jsonDictionary;
+ (NSString *) getErrorResponseWithCode:(NSString *) errorCode
                             andMessage:(NSString *) errorMessage;
+ (NSString *) getErrorResponseWithCode:(NSString *) errorCode
                         andJsonMessage:(NSString *) errorMessage;
+ (NSString *) getCompletionResponseWithMyKadFrontResp: (NSString *) mykadFrontResp
                                      andMyKadBackResp: (NSString *) mykadBackResp
                                   andFaceLivenessResp: (NSString *) faceLivenessResp;
+ (NSString *) getCompletionResponseWithMyKadFrontResp: (NSString *) mykadFrontResp
                                      andMyKadBackResp: (NSString *) mykadBackResp;
+ (NSString *) getCompletionResponseWithPassportResp: (NSString *) passportResp
                                 andFaceLivenessResp: (NSString *) faceLivenessResp;
+ (NSString *) getCompletionResponseWithPassportResp: (NSString *) passportResp;
+ (NSString *) getFormattedResp: (NSString *) resultString;
+ (NSString *) getFormattedErrorResp: (NSString *) resultString;
+ (NSString *) getCompletionResponseWithLivenessCaptureResp: (NSString *) livenessCaptureResp;
+ (NSString *) encodeToBase64String:(NSData *) imageData;
+ (NSString *) getSdkInformationWithLocationCoordinate:(NSString *) locationCoordinate;
+ (NSData *) compressImage:(NSData *) imgData;
+ (UIViewController*) topMostController;
+ (UIImage *)cropImage:(UIImage *)image fromCenterWithSize:(CGSize)size;
+ (NSString *)encryptResult:(NSString *)result withConfiguration:(NSDictionary *)encryptionConfig;
+ (NSString *) wrapInJSONWithSessionID:(NSString *) result;
+ (NSURL *) extractMiddleFramesFromVideo:(NSURL *) videoURL;
+ (CVPixelBufferRef) pixelBufferFromCGImage:(CGImageRef) image size:(CGSize) size;
+ (NSString *) deviceIdentifier;
@property (nonatomic, strong) NSString *WS_URL;
@property (nonatomic, strong) NSString *WS_API_KEY;
@property (nonatomic) BOOL isOCROnly;
@property (nonatomic) BOOL isExportFace;
@property (nonatomic) BOOL isExportDoc;
@property (nonatomic, strong) NSString *countryCode;
@property (nonatomic, strong) NSString *idType;
@property (nonatomic, strong) NSString *action;
@property (nonatomic, strong) NSString *sessionID;
@property (nonatomic, strong) NSString *frontReqID;
@property (nonatomic, strong) NSString *backReqID;
@property (nonatomic, strong) NSString *locationCoordinateInfo;
@property (nonatomic, strong) NSString *frReqID;
@property (nonatomic, strong) NSData *frontICImage;
@property (nonatomic, strong) NSData *backICImage;
@property (nonatomic, strong) NSData *passportImage;
@property (nonatomic, strong) NSData *selfieImage;
@property (nonatomic, strong) NSURL *videoPath;
@property (nonatomic, strong) NSDictionary *isBackIDRequired;
@property (nonatomic) BOOL isFrontICFailed;
@property (nonatomic) BOOL isDebug;
@property (nonatomic) BOOL isPassport;
@property (nonatomic) BOOL isEncrypt;
@property (nonatomic, strong) NSDictionary *encryptionKey;
@property (nonatomic, strong) NSString *extraParam;
@property (nonatomic, strong) NSDictionary *languageDictionary;
@property (nonatomic, strong) NSString *language;
@property (nonatomic) NSString *cameraFacing;
@property (nonatomic) NSString *mykadFrontResult;
@property (nonatomic) NSString *mykadBackResult;
@property (nonatomic) NSString *passportResult;
@property (nonatomic) NSString *faceLivenessResult;
@property (nonatomic) NSString *livenessCaptureResult;
@end

NS_ASSUME_NONNULL_END
