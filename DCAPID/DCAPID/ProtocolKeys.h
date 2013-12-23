//
//  ProtocolKeys.h
//  DCAPI
//
//  Created by Rodrigo Marques on 11/10/13.
//  Copyright (c) 2013 Ande Tecnologia. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface ProtocolKeys : NSObject
+ (NSString*) CLIENT_NAME;
+ (NSString*) CLIENT_CPF;
+ (NSString*) CLIENT_RG;
+ (NSString*) CLIENT_BIRTH;
+ (NSString*) CLIENT_EMAIL;

+ (NSString*) IS_OK;
+ (NSString*) TRUE_MESSAGE;
+ (NSString*) FALSE_MESSAGE;
+ (NSString*) ERROR;

+ (NSString*) PASSWORD;
+ (NSString*) OLD_PASSWORD;
+ (NSString*) NEW_PASSWORD;

+ (NSString*) IMEI;
+ (NSString*) GUID;
+ (NSString*) SECRET;
+ (NSString*) TOKEN;

+ (NSString*) CARD_NAME;
+ (NSString*) CARD_CODE;
+ (NSString*) CARD_TITLE;
+ (NSString*) CARD_NUMBER;
+ (NSString*) CARD_DESCRIPTION;
+ (NSString*) CARD_ISDEPENDENT;
+ (NSString*) CARD_EXPIRATION;
+ (NSString*) CARD_ISSUE;

+ (NSString*) NOT_SUBJECT;
+ (NSString*) NOT_MESSAGE;
+ (NSString*) NOT_TIMESTAMP;
+ (NSString*) NOT_IMAGE;
+ (NSString*) NOT_GUID;

+ (NSString*) TRANS_CNT;
+ (NSString*) TRANS_GUID;
+ (NSString*) TRANS_COMPANY;
+ (NSString*) TRANS_LOCATION;
+ (NSString*) TRANS_TIMESTAMP;
+ (NSString*) TRANS_PROCEDURE;
+ (NSString*) TRANS_EVALUATION;
+ (NSString*) TRANS_EVALUATION_MSG;
+ (NSString*) TRANS_CARD_TYPE;
+ (NSString*) TRANS_CARD_NUMBER;

+ (NSString*) DEVICETOKEN;

@end
