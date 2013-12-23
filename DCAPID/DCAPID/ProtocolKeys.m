//
//  ProtocolKeys.m
//  DCAPI
//
//  Created by Rodrigo Marques on 11/10/13.
//  Copyright (c) 2013 Ande Tecnologia. All rights reserved.
//

#import "ProtocolKeys.h"

 static NSString *theCLIENT_NAME = @"client_name";
 static NSString *theCLIENT_CPF = @"client_cpf";
 static NSString *theCLIENT_RG = @"client_rg";
 static NSString *theCLIENT_BIRTH = @"client_birth";
 static NSString *theCLIENT_EMAIL = @"client_email";

 static NSString *theIS_OK = @"is_ok";
 static NSString *theTRUE_MESSAGE = @"true";
 static NSString *theFALSE_MESSAGE = @"false";
 static NSString *theERROR = @"error";

 static NSString *thePASSWORD = @"password";
 static NSString *theOLD_PASSWORD = @"old_password";
 static NSString *theNEW_PASSWORD = @"new_password";

 static NSString *theIMEI = @"phoneid";
 static NSString *theGUID = @"guid";
 static NSString *theSECRET = @"secret";
 static NSString *theTOKEN = @"token";

 static NSString *theCARD_NAME = @"card_name";
 static NSString *theCARD_CODE = @"card_code";
 static NSString *theCARD_TITLE = @"card_title";
 static NSString *theCARD_NUMBER = @"card_number";
 static NSString *theCARD_DESCRIPTION = @"card_description";
 static NSString *theCARD_ISDEPENDENT = @"card_isdependent";

 static NSString *theCARD_EXPIRATION = @"card_expiration";
 static NSString *theCARD_ISSUE = @"card_issue_date";

 static NSString *theNOT_SUBJECT = @"not_subject";
 static NSString *theNOT_MESSAGE = @"not_message";
 static NSString *theNOT_TIMESTAMP = @"not_timestamp";
 static NSString  *theNOT_IMAGE = @"not_image";
 static NSString  *theNOT_GUID = @"not_guid";

 static NSString *theTRANS_CNT = @"trans_cnt";
 static NSString *theTRANS_GUID = @"trans_guid";
 static NSString *theTRANS_COMPANY = @"trans_company";
 static NSString *theTRANS_LOCATION = @"trans_location";
 static NSString *theTRANS_TIMESTAMP = @"trans_timestamp";
 static NSString *theTRANS_PROCEDURE = @"trans_procedure";
 static NSString *theTRANS_EVALUATION = @"trans_evaluation";
 static NSString *theTRANS_EVALUATION_MSG = @"trans_evaluation_msg";
 static NSString *theTRANS_CARD_TYPE = @"trans_card_type";
 static NSString *theTRANS_CARD_NUMBER = @"trans_card_number";

 static NSString *theDEVICETOKEN = @"device_token";


@implementation ProtocolKeys

+ (NSString*) CLIENT_NAME { return theCLIENT_NAME; }
+ (NSString*) CLIENT_CPF { return theCLIENT_CPF; }
+ (NSString*) CLIENT_RG { return theCLIENT_RG; }
+ (NSString*) CLIENT_BIRTH { return theCLIENT_BIRTH; }
+ (NSString*) CLIENT_EMAIL { return theCLIENT_EMAIL; }

+ (NSString*) IS_OK { return theIS_OK; }
+ (NSString*) TRUE_MESSAGE { return theTRUE_MESSAGE; }
+ (NSString*) FALSE_MESSAGE { return theFALSE_MESSAGE; }
+ (NSString*) ERROR { return theERROR; }

+ (NSString*) PASSWORD { return thePASSWORD; }
+ (NSString*) OLD_PASSWORD { return theOLD_PASSWORD; }
+ (NSString*) NEW_PASSWORD { return theNEW_PASSWORD; }

+ (NSString*) IMEI { return theIMEI; }
+ (NSString*) GUID { return theGUID; }
+ (NSString*) SECRET { return theSECRET; }
+ (NSString*) TOKEN { return theTOKEN; }

+ (NSString*) CARD_NAME { return theCARD_NAME; }
+ (NSString*) CARD_CODE { return theCARD_CODE; }
+ (NSString*) CARD_TITLE { return theCARD_TITLE; }
+ (NSString*) CARD_NUMBER { return theCARD_NUMBER; }
+ (NSString*) CARD_DESCRIPTION { return theCARD_DESCRIPTION; }
+ (NSString*) CARD_ISDEPENDENT { return theCARD_ISDEPENDENT; }
+ (NSString*) CARD_EXPIRATION { return theCARD_EXPIRATION; }
+ (NSString*) CARD_ISSUE { return theCARD_ISSUE; }

+ (NSString*) NOT_SUBJECT { return theNOT_SUBJECT; }
+ (NSString*) NOT_MESSAGE { return theNOT_MESSAGE; }
+ (NSString*) NOT_TIMESTAMP { return theNOT_TIMESTAMP; }
+ (NSString*) NOT_IMAGE { return theNOT_IMAGE; }
+ (NSString*) NOT_GUID { return theNOT_GUID; }

+ (NSString*) TRANS_CNT { return theTRANS_CNT; }
+ (NSString*) TRANS_GUID { return theTRANS_GUID; }
+ (NSString*) TRANS_COMPANY { return theTRANS_COMPANY; }
+ (NSString*) TRANS_LOCATION { return theTRANS_LOCATION; }
+ (NSString*) TRANS_TIMESTAMP { return theTRANS_TIMESTAMP; }
+ (NSString*) TRANS_PROCEDURE { return theTRANS_PROCEDURE; }
+ (NSString*) TRANS_EVALUATION { return theTRANS_EVALUATION; }
+ (NSString*) TRANS_EVALUATION_MSG { return theTRANS_EVALUATION_MSG; }
+ (NSString*) TRANS_CARD_TYPE { return theTRANS_CARD_TYPE;}
+ (NSString*) TRANS_CARD_NUMBER { return theTRANS_CARD_NUMBER;}

+ (NSString*) DEVICETOKEN { return theDEVICETOKEN; }

@end
