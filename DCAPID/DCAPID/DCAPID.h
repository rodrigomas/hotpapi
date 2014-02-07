//
//  DCAPID.h
//  DCAPID
//
//  Created by Rodrigo Marques on 11/11/13.
//  Copyright (c) 2013 Ande Tecnologia. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>

#import "CardInfo.h"
#import "Notification.h"
#import "Transaction.h"
#import "QRCodeResp.h"
#import "TokenResp.h"
#import "DCAPIException.h"


@interface DCAPID : NSObject

@property (nonatomic, retain) NSString *_serverAdress;

@property (nonatomic, retain) NSNumber *_comunicationTimeout;

- (BOOL)isConnected;

- (BOOL)isRegisteredPhone;

- (BOOL) unregisterPhone;

- (void)setupWithAddress: (NSString*) serverAdress withTimeout: (int) comunicationTimeout;

- (BOOL)registerUserWithName: (NSString*) name withCPF: (NSString*) cpf withRG: (NSString*) rg withBirth: (NSDate*) birthDate withEmail: (NSString*) email;

- (BOOL)recoverPasswordWithName: (NSString*) name withCPF: (NSString*) cpf withBith: (NSDate*) birthDate withEmail: (NSString*) email;

- (BOOL)changePasswordWithEmail: (NSString*) email withOldPassword: (NSString*) oldPassword withNewPassword: (NSString*) newPassword;

- (NSString*)retrieveEmailWithName: (NSString*) name withCPF: (NSString*) cpf withBith: (NSDate*) birthDate;

- (NSString*)registerPhoneWithEmail: (NSString*) email withPassword: (NSString*) password withPhoneID: (NSString*) PhoneID withCard: (NSString*) cardNumber;

- (NSMutableArray*) receiveCards;

- (BOOL) registerUserNotificationPushWithDeviceToken: (NSString*) deviceToken;

- (NSMutableArray*) receiveBenefits;

- (UIImage*) downloadImageBenefitWithBGUID: (NSString*) bguid ;

- (NSMutableArray*) receiveTransactionsWithCNT: (int) cnt withLastGUID: (NSString*) lastGuid;

- (BOOL) sendEvaluationWithTransGuid: (NSString*) transactionGuid withRate: (int) rate withMessage: (NSString*) message;

- (QRCodeResp*) createQRCodeWithLatitute: (float) latitute withLongitute: (float) longitude withCard: (NSString*) cardNumber withCardType: (NSString*) cardTypeCode withWith: (int) width withHeight: (int) height;

- (TokenResp*) createTokenWithCard: (NSString*) cardNumber;

+ (DCAPID*) getInstance;

@end
