//
//  WiseAiApp.h
//  WiseAISDK
//
//  Created by JPCHOI on 27/02/2021.
//

#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>
#import "Assets.h"
#import "MyCardOCR.h"
#import "PassportOCR.h"
#import "FaceLiveness.h"
#import "LivenessCapture.h"
#import "AppLocationManager.h"

NS_ASSUME_NONNULL_BEGIN
@protocol WiseAIAppDelegate <NSObject>
- (void) onEkycComplete:(NSString *) jsonResult;
- (void) onEkycException:(NSString *) jsonResult;
- (void) onEkycCancelled;
//- (void) onLivenessComplete:(NSString *) jsonResult;
//- (void) onLivenessException:(NSString *) jsonResult;
- (void) getSessionIdAndEncryptionConfig:(NSString *) sessionIDandConfig;
@end

@interface WiseAiApp : NSObject <MyCardOCRDelegate, PassportOCRDelegate, FaceLivenessDelegate>
@property (nonatomic, weak) id<WiseAIAppDelegate> delegate;
@property (strong, nonatomic) NSString *apiToken;
@property (strong, nonatomic) NSString *apiURL;
@property (strong, nonatomic) NSString *extraParam;

- (void) setLanguage:(NSString *) language;
- (instancetype) initWithApiToken:(NSString *) apiToken
                        andApiURL:(NSString *) apiURL;
- (instancetype) initWithApiToken:(NSString *) apiToken
                        andApiURL:(NSString *) apiURL
                    andExtraParam:(NSString *) extraParam;
- (void) performEkycAndExportFace:(BOOL) isExportFace;
- (void) performEkycWithExportDoc:(BOOL) isExportDoc AndExportFace:(BOOL) isExportFace;
- (void) performEkycWithExportDoc:(BOOL) isExportDoc AndExportFace:(BOOL) isExportFace AndCameraFacing:(NSString *) cameraFacing;
- (void) performPassportEkycWithExportDoc:(BOOL) isExportDoc AndExportFace:(BOOL) isExportFace;
- (void) performPassportEkycWithExportDoc:(BOOL) isExportDoc AndExportFace:(BOOL) isExportFace AndCameraFacing:(NSString *) cameraFacing;
- (void) performEkycForCountry: (NSString *) countryCode IDType: (NSString *) idType WithExportDoc: (BOOL) isExportDoc AndExportFace: (BOOL) isExportFace;
- (void) performEkycForCountry: (NSString *) countryCode IDType: (NSString *) idType WithExportDoc: (BOOL) isExportDoc AndExportFace: (BOOL) isExportFace AndCameraFacing:(NSString *) cameraFacing;
- (void) performOCRWithExportDoc:(BOOL) isExportDoc AndExportFace:(BOOL) isExportFace AndEkycType:(NSString *) type;
- (void) startNewSession;
- (void) startNewSessionWithEncryption;
//- (void) performLivenessCapture;
- (NSString *)decryptResult:(NSString *)encryptedData withConfiguration:(NSDictionary *)encryptionConfig;

@end

NS_ASSUME_NONNULL_END
