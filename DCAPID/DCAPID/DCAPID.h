//
//  DCAPID.h
//  DCAPID
//
//  Created by Rodrigo Marques on 11/11/13.
//  Copyright (c) 2013 Ande Tecnologia. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>

#import "AuthResponse.h"
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

- (void)setupWithAddress: (NSString*) serverAdress withTimeout: (int) comunicationTimeout;

- (BOOL)registerUserWithName: (NSString*) name withCPF: (NSString*) cpf withRG: (NSString*) rg withBirth: (NSDate*) birthDate withEmail: (NSString*) email;

- (BOOL)recoverPasswordWithName: (NSString*) name withCPF: (NSString*) cpf withBith: (NSDate*) birthDate withEmail: (NSString*) email;

- (BOOL)changePasswordWithEmail: (NSString*) email withOldPassword: (NSString*) oldPassword withNewPassword: (NSString*) newPassword;

- (NSString*)retrieveEmailWithName: (NSString*) name withCPF: (NSString*) cpf withBith: (NSDate*) birthDate;

- (AuthResponse*)registerPhoneWithEmail: (NSString*) email withPassword: (NSString*) password withPhoneID: (NSString*) PhoneID withCard: (NSString*) cardNumber withCardType: (NSString*) cardTypeCode;

- (NSMutableArray*) receiveCardsWithSecret: (NSString*) secret withPhoneID: (NSString*) PhoneID withGUID: (NSString*) guid withPassword: (NSString*) Password;

- (BOOL) registerUserNotificationPushWithSecret: (NSString*) secret withPhoneID: (NSString*) PhoneID withGUID: (NSString*) GUID withDeviceToken: (NSString*) deviceToken;

- (NSMutableArray*) receiveBenefitsWithSecret: (NSString*) secret withPhoneID: (NSString*) PhoneID withGUID: (NSString*) guid;

- (NSMutableArray*) receiveTransactionsWithSecret: (NSString*) secret withPhoneID: (NSString*) PhoneID withGUID: (NSString*) guid withCNT: (int) cnt withLastGUID: (NSString*) lastGuid;

- (BOOL) sendEvaluationWithTransGuid: (NSString*) transactionGuid withRate: (int) rate withMessage: (NSString*) message withPhoneID: (NSString*) PhoneID withGUID: (NSString*) guid withKEY: (NSString*) secretKey;

- (QRCodeResp*) createQRCodeWithSecret: (NSString*) secretKey withGUID: (NSString*) guid withLatitute: (float) latitute withLongitute: (float) longitude withCard: (NSString*) cardNumber withPhoneID: (NSString*) PhoneID withCardType: (NSString*) cardTypeCode withWith: (int) width withHeight: (int) height;

- (TokenResp*) createTokenWithSecret: (NSString*) secretkey withPhoneID: (NSString*) PhoneID withCard: (NSString*) cardNumber;

+ (DCAPID*) getInstance;

@end
