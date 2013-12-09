//
//  DCAPID.m
//  DCAPID
//
//  Created by Rodrigo Marques on 11/11/13.
//  Copyright (c) 2013 Ande Tecnologia. All rights reserved.
//

#import "DCAPID.h"
#import "ProtocolKeys.h"
#import "TOTPGenerator.h"
#import "qrencode.h"
#import "MF_Base32Additions.h"
#import "Reachability.h"

#import <UIKit/UIKit.h>

static DCAPID *sharedSingleton = NULL;

static NSString *ERROR_WRONG_SERVER_ADDRESS = @"O endereço do servidor está incorreto.";
static NSString *ERROR_CONNECTION_TIMEOUT = @"Tempo limite de conexão estourado";
static NSString *ERROR_NO_CONNECTION = @"Sem conexão com a Internet";

static NSString *ERROR_HEADER = @"DCAPI Error";
static NSString *ERROR_INTERNAL_MESSAGE = @"Falha interna!";
static NSString *ERROR_INVALID_RESPONSE_MESSAGE = @"Protocolo ou resposta inválida!";

static NSString *SERVLET_REGUSER = @"RegUser";
static NSString *SERVLET_RECOVERPASSWORD = @"RecoverPassword";
static NSString *SERVLET_CHANGEPASSWORD = @"ChangePassword";
static NSString *SERVLET_RETRIEVEEMAIL = @"RetrieveEmail";
static NSString *SERVLET_REGPHONE = @"RegPhone";
static NSString *SERVLET_RECEIVECARDS = @"ReceiveCards";
static NSString *SERVLET_RECEIVENOTIFICATIONS = @"ReceiveBenefits";
static NSString *SERVLET_RECEIVETRANSACTIONS = @"ReceiveTransactions";
static NSString *SERVLET_EVALTRANSACTION = @"EvalTransaction";
static NSString *SERVLET_REGUSERNOTIFICATIONS = @"RegUserNotifications";

static Reachability *internetReachable;

enum ErrorCode {
    SERVER_REPONSE_ERROR, SERVER_COMMUNICATION_ERROR, INTERNAL_API_ERROR
};


NSMutableArray* makeHTTPRequest(NSString* ServletAddress, NSMutableDictionary* args, int comunicationTimeout);
UIImage * imageWithImage(UIImage *image, CGSize size);
UIImage* convertBitmapRGBA8ToUIImage(unsigned char * buffer, int width, int height );
BOOL ProtocolValid(NSMutableArray *keys, NSMutableDictionary* resp);
NSDate* convertToUTC( NSDate* sourceDate);
NSString *GetSecretFormat1(NSString *secret, NSString *phoneid);
NSString *GetSecretFormat2(NSString *secret, NSString *phoneid, NSString *cardid);
NSString *decodeURL(NSString *value);

@implementation DCAPID

+ (DCAPID*) getInstance
{
    if (sharedSingleton == NULL)
    {
        sharedSingleton = [[DCAPID alloc] init];
    }
    
    return sharedSingleton;
}

- (void)setupWithAddress: (NSString*) serverAdress withTimeout: (int) comunicationTimeout
{
    __serverAdress = serverAdress;
    __comunicationTimeout = [[NSNumber alloc] initWithInt:comunicationTimeout];
    
    internetReachable = [Reachability reachabilityWithHostname:serverAdress];
    
    [internetReachable startNotifier];
}

- (BOOL)registerUserWithName: (NSString*) name withCPF: (NSString*) cpf withRG: (NSString*) rg withBirth: (NSDate*) birthDate withEmail: (NSString*) email
{
    @try {
        
        if(!internetReachable.isReachable)
        {
            DCAPIException *ex = [[DCAPIException alloc] initWithName:ERROR_HEADER reason:ERROR_NO_CONNECTION userInfo:nil];
            NSString *msg = ERROR_NO_CONNECTION;
            ex.code = [[NSString alloc] initWithFormat:@"%02d", SERVER_COMMUNICATION_ERROR];
            ex.show = true;
            ex.message = msg;
            
            @throw (ex);
        }
        
        NSMutableDictionary * args = [[NSMutableDictionary alloc] init];
    
        args[ [ProtocolKeys CLIENT_NAME] ] = name;
        args[ [ProtocolKeys CLIENT_CPF] ] = cpf;
        args[ [ProtocolKeys CLIENT_RG] ] = rg;
    
        NSDateFormatter *dateFormatter = [[NSDateFormatter alloc] init];
        [dateFormatter setDateFormat:@"dd/MM/yyyy HH:mm:ss"];
    
        NSString *datestr = [dateFormatter stringFromDate:birthDate];
    
        args[ [ProtocolKeys CLIENT_BIRTH] ] = datestr;
        args[ [ProtocolKeys CLIENT_EMAIL] ] = email;
    
        NSMutableArray * resp = makeHTTPRequest([[NSString alloc] initWithFormat:@"%@%@", __serverAdress, SERVLET_REGUSER], args, [__comunicationTimeout intValue]);
        
        if (resp == nil || [resp count] == 0 || [resp[0] objectForKey:[ProtocolKeys ERROR]] != nil) {

            DCAPIException *ex = [[DCAPIException alloc] initWithName:ERROR_HEADER reason:resp[0][[ProtocolKeys ERROR]] userInfo:nil];
            NSString *msg = resp[0][[ProtocolKeys ERROR]];
            ex.code = [msg substringWithRange:NSMakeRange(1, 2)];
            ex.show = [msg hasPrefix:@"1"];
            ex.message = [msg substringFromIndex:4];
            
            @throw (ex);
            
        } else if( [resp[0][[ProtocolKeys IS_OK]] isEqualToString: [ProtocolKeys TRUE_MESSAGE]] )
        {
            return true;
        }
    }
    @catch (DCAPIException *exception)
    {
        @throw;
    }
    @catch (NSException *exception) {
        DCAPIException *ex = [[DCAPIException alloc] initWithName:ERROR_HEADER reason:exception.reason userInfo:nil];
        ex.code = [[NSString alloc] initWithFormat:@"%02d", INTERNAL_API_ERROR];
        ex.show = false;
        ex.message = ex.reason;
        
        @throw (ex);
    }
    
    return false;
}

- (BOOL)recoverPasswordWithName: (NSString*) name withCPF: (NSString*) cpf withBith: (NSDate*) birthDate withEmail: (NSString*) email
{
    @try
    {
        
        if(!internetReachable.isReachable)
        {
            DCAPIException *ex = [[DCAPIException alloc] initWithName:ERROR_HEADER reason:ERROR_NO_CONNECTION userInfo:nil];
            NSString *msg = ERROR_NO_CONNECTION;
            ex.code = [[NSString alloc] initWithFormat:@"%02d", SERVER_COMMUNICATION_ERROR];
            ex.show = true;
            ex.message = msg;
            
            @throw (ex);
        }
        
        NSMutableDictionary * args = [[NSMutableDictionary alloc] init];
        
        args[ [ProtocolKeys CLIENT_NAME] ] = name;
        args[ [ProtocolKeys CLIENT_CPF] ] = cpf;
        
        NSDateFormatter *dateFormatter = [[NSDateFormatter alloc] init];
        [dateFormatter setDateFormat:@"dd/MM/yyyy HH:mm:ss"];
        
        NSString *datestr = [dateFormatter stringFromDate:birthDate];
        
        args[ [ProtocolKeys CLIENT_BIRTH] ] = datestr;
        args[ [ProtocolKeys CLIENT_EMAIL] ] = email;
        
        NSMutableArray * resp = makeHTTPRequest([[NSString alloc] initWithFormat:@"%@%@", __serverAdress, SERVLET_RECOVERPASSWORD], args, [__comunicationTimeout intValue]);
        
        if (resp == nil || [resp count] == 0 || [resp[0] objectForKey:[ProtocolKeys ERROR]] != nil) {
            
            DCAPIException *ex = [[DCAPIException alloc] initWithName:ERROR_HEADER reason:resp[0][[ProtocolKeys ERROR]] userInfo:nil];
            NSString *msg = resp[0][[ProtocolKeys ERROR]];
            ex.code = [msg substringWithRange:NSMakeRange(1, 2)];
            ex.show = [msg hasPrefix:@"1"];
            ex.message = [msg substringFromIndex:4];
            
            @throw (ex);

        } else if( [resp[0][[ProtocolKeys IS_OK]] isEqualToString: [ProtocolKeys TRUE_MESSAGE]] )
        {
            return true;
        }
    }
    @catch (DCAPIException *exception)
    {
        @throw;
    }
    @catch (NSException *exception) {
        DCAPIException *ex = [[DCAPIException alloc] initWithName:ERROR_HEADER reason:exception.reason userInfo:nil];
        ex.code = [[NSString alloc] initWithFormat:@"%02d", INTERNAL_API_ERROR];
        ex.show = false;
        ex.message = ex.reason;
        
        @throw (ex);
    }
    
    return false;

}

- (BOOL)changePasswordWithEmail: (NSString*) email withOldPassword: (NSString*) oldPassword withNewPassword: (NSString*) newPassword
{
    @try
    {
        if(!internetReachable.isReachable)
        {
            DCAPIException *ex = [[DCAPIException alloc] initWithName:ERROR_HEADER reason:ERROR_NO_CONNECTION userInfo:nil];
            NSString *msg = ERROR_NO_CONNECTION;
            ex.code = [[NSString alloc] initWithFormat:@"%02d", SERVER_COMMUNICATION_ERROR];
            ex.show = true;
            ex.message = msg;
            
            @throw (ex);
        }
        
        NSMutableDictionary * args = [[NSMutableDictionary alloc] init];
        
        args[ [ProtocolKeys OLD_PASSWORD] ] = oldPassword;
        args[ [ProtocolKeys NEW_PASSWORD] ] = newPassword;
        args[ [ProtocolKeys CLIENT_EMAIL] ] = email;
            
        NSMutableArray * resp = makeHTTPRequest([[NSString alloc] initWithFormat:@"%@%@", __serverAdress, SERVLET_CHANGEPASSWORD], args, [__comunicationTimeout intValue]);
        
        if (resp == nil || [resp count] == 0 || [resp[0] objectForKey:[ProtocolKeys ERROR]] != nil) {
            DCAPIException *ex = [[DCAPIException alloc] initWithName:ERROR_HEADER reason:resp[0][[ProtocolKeys ERROR]] userInfo:nil];
            NSString *msg = resp[0][[ProtocolKeys ERROR]];
            ex.code = [msg substringWithRange:NSMakeRange(1, 2)];
            ex.show = [msg hasPrefix:@"1"];
            ex.message = [msg substringFromIndex:4];
            
            @throw (ex);
        } else if( [resp[0][[ProtocolKeys IS_OK]] isEqualToString: [ProtocolKeys TRUE_MESSAGE]] )
        {
            return true;
        }
        
    }
    @catch (DCAPIException *exception)
    {
        @throw;
    }
    @catch (NSException *exception) {
        DCAPIException *ex = [[DCAPIException alloc] initWithName:ERROR_HEADER reason:exception.reason userInfo:nil];
        ex.code = [[NSString alloc] initWithFormat:@"%02d", INTERNAL_API_ERROR];
        ex.show = false;
        ex.message = ex.reason;
        
        @throw (ex);
    }
    
    return false;
}

- (NSString*)retrieveEmailWithName: (NSString*) name withCPF: (NSString*) cpf withBith: (NSDate*) birthDate
{
    @try
    {
        if(!internetReachable.isReachable)
        {
            DCAPIException *ex = [[DCAPIException alloc] initWithName:ERROR_HEADER reason:ERROR_NO_CONNECTION userInfo:nil];
            NSString *msg = ERROR_NO_CONNECTION;
            ex.code = [[NSString alloc] initWithFormat:@"%02d", SERVER_COMMUNICATION_ERROR];
            ex.show = true;
            ex.message = msg;
            
            @throw (ex);
        }
        
        NSMutableDictionary * args = [[NSMutableDictionary alloc] init];
        
        args[ [ProtocolKeys CLIENT_NAME] ] = name;
        args[ [ProtocolKeys CLIENT_CPF] ] = cpf;
        
        NSDateFormatter *dateFormatter = [[NSDateFormatter alloc] init];
        [dateFormatter setDateFormat:@"dd/MM/yyyy HH:mm:ss"];
        
        NSString *datestr = [dateFormatter stringFromDate:birthDate];
        
        args[ [ProtocolKeys CLIENT_BIRTH] ] = datestr;
            
        NSMutableArray * resp = makeHTTPRequest([[NSString alloc] initWithFormat:@"%@%@", __serverAdress, SERVLET_RETRIEVEEMAIL], args, [__comunicationTimeout intValue]);
        
        if (resp == nil || [resp count] == 0 || [resp[0] objectForKey:[ProtocolKeys ERROR]] != nil) {
            DCAPIException *ex = [[DCAPIException alloc] initWithName:ERROR_HEADER reason:resp[0][[ProtocolKeys ERROR]] userInfo:nil];
            NSString *msg = resp[0][[ProtocolKeys ERROR]];
            ex.code = [msg substringWithRange:NSMakeRange(1, 2)];
            ex.show = [msg hasPrefix:@"1"];
            ex.message = [msg substringFromIndex:4];
            
            @throw (ex);
        } else if([resp[0] objectForKey:[ProtocolKeys CLIENT_EMAIL]] != nil )
        {
            return resp[0][[ProtocolKeys CLIENT_EMAIL]];
        } else
        {
            DCAPIException *ex = [[DCAPIException alloc] initWithName:ERROR_HEADER reason:ERROR_INTERNAL_MESSAGE userInfo:nil];
            ex.code = [[NSString alloc] initWithFormat:@"%02d", INTERNAL_API_ERROR];
            ex.show = false;
            ex.message = ex.reason;
            
            @throw (ex);
        }
    }
    @catch (DCAPIException *exception)
    {
        @throw;
    }
    @catch (NSException *exception) {
        DCAPIException *ex = [[DCAPIException alloc] initWithName:ERROR_HEADER reason:exception.reason userInfo:nil];
        ex.code = [[NSString alloc] initWithFormat:@"%02d", INTERNAL_API_ERROR];
        ex.show = false;
        ex.message = ex.reason;
        
        @throw (ex);
    }
    
    return nil;
}

- (AuthResponse*)registerPhoneWithEmail: (NSString*) email withPassword: (NSString*) password withPhoneID: (NSString*) PhoneID withCard: (NSString*) cardNumber withCardType: (NSString*) cardTypeCode
{
    @try {
        
        if(!internetReachable.isReachable)
        {
            DCAPIException *ex = [[DCAPIException alloc] initWithName:ERROR_HEADER reason:ERROR_NO_CONNECTION userInfo:nil];
            NSString *msg = ERROR_NO_CONNECTION;
            ex.code = [[NSString alloc] initWithFormat:@"%02d", SERVER_COMMUNICATION_ERROR];
            ex.show = true;
            ex.message = msg;
            
            @throw (ex);
        }
        
        NSMutableDictionary * args = [[NSMutableDictionary alloc] init];
        
        args[ [ProtocolKeys CLIENT_EMAIL] ] = email;
        args[ [ProtocolKeys PASSWORD] ] = password;
        args[ [ProtocolKeys IMEI] ] = PhoneID;
        args[ [ProtocolKeys CARD_CODE] ] = cardTypeCode;
        args[ [ProtocolKeys CARD_NUMBER] ] = cardNumber;
        
        NSMutableArray * resp = makeHTTPRequest([[NSString alloc] initWithFormat:@"%@%@", __serverAdress, SERVLET_REGPHONE], args, [__comunicationTimeout intValue]);
        
        if (resp == nil ||[resp count] == 0  || [resp[0] objectForKey:[ProtocolKeys ERROR]] != nil) {
            
            DCAPIException *ex = [[DCAPIException alloc] initWithName:ERROR_HEADER reason:resp[0][[ProtocolKeys ERROR]] userInfo:nil];
            NSString *msg = resp[0][[ProtocolKeys ERROR]];
            ex.code = [msg substringWithRange:NSMakeRange(1, 2)];
            ex.show = [msg hasPrefix:@"1"];
            ex.message = [msg substringFromIndex:4];
            
            @throw (ex);
            
        } else if([resp[0] objectForKey:[ProtocolKeys CLIENT_NAME]] != nil )
        {
            AuthResponse * r = [AuthResponse alloc];
            
            r.clientName = resp[0][[ProtocolKeys CLIENT_NAME]];
            r.GUID = resp[0][[ProtocolKeys GUID]];
            r.secretKey = resp[0][[ProtocolKeys SECRET]];
            
            return r;
        } else
        {
            DCAPIException *ex = [[DCAPIException alloc] initWithName:ERROR_HEADER reason:ERROR_INTERNAL_MESSAGE userInfo:nil];
            ex.code = [[NSString alloc] initWithFormat:@"%02d", INTERNAL_API_ERROR];
            ex.show = false;
            ex.message = ex.reason;
            
            @throw (ex);
        }
    }
    @catch (DCAPIException *exception)
    {
        @throw;
    }
    @catch (NSException *exception) {
        DCAPIException *ex = [[DCAPIException alloc] initWithName:ERROR_HEADER reason:exception.reason userInfo:nil];
        ex.code = [[NSString alloc] initWithFormat:@"%02d", INTERNAL_API_ERROR];
        ex.show = false;
        ex.message = ex.reason;
        
        @throw (ex);
    }
    
    return nil;
}

- (NSMutableArray*) receiveCardsWithSecret: (NSString*) secret withPhoneID: (NSString*) PhoneID withGUID: (NSString*) guid withPassword: (NSString*) Password
{
    NSMutableArray *arr = [[NSMutableArray alloc] init];
    
    @try {
        
        if(!internetReachable.isReachable)
        {
            DCAPIException *ex = [[DCAPIException alloc] initWithName:ERROR_HEADER reason:ERROR_NO_CONNECTION userInfo:nil];
            NSString *msg = ERROR_NO_CONNECTION;
            ex.code = [[NSString alloc] initWithFormat:@"%02d", SERVER_COMMUNICATION_ERROR];
            ex.show = true;
            ex.message = msg;
            
            @throw (ex);
        }
        
        NSString *sec = GetSecretFormat1(secret, PhoneID);
        NSData* dataKey = [MF_Base32Codec dataFromBase32String:sec];
        //NSData* dataKey = [MF_Base32Codec dataFromBase32String:secret];
        
        NSString *Token;
        
        TOTPGenerator *otpProvider = [[TOTPGenerator alloc] initWithSecret:dataKey algorithm:kOTPGeneratorSHA1Algorithm digits:6 period:30];
        
        NSDate *currentDate = [NSDate date];
        
        Token = [otpProvider generateOTPForDate:currentDate];
        
        NSMutableDictionary * args = [[NSMutableDictionary alloc] init];
        
        args[ [ProtocolKeys GUID] ] = guid;
        args[ [ProtocolKeys TOKEN] ] = Token;
        
        NSMutableArray * resp = makeHTTPRequest([[NSString alloc] initWithFormat:@"%@%@", __serverAdress, SERVLET_RECEIVECARDS], args, [__comunicationTimeout intValue]);
        
        if (resp == nil || [resp count] == 0 || [resp[0] objectForKey:[ProtocolKeys ERROR]] != nil) {
            
            if( resp != nil && [resp count] == 0)
            {
                return arr;
            } else
            {
                DCAPIException *ex = [[DCAPIException alloc] initWithName:ERROR_HEADER reason:resp[0][[ProtocolKeys ERROR]] userInfo:nil];
                NSString *msg = resp[0][[ProtocolKeys ERROR]];
                ex.code = [msg substringWithRange:NSMakeRange(1, 2)];
                ex.show = [msg hasPrefix:@"1"];
                ex.message = [msg substringFromIndex:4];
                
                @throw (ex);
            }
            
        } else
        {
            NSMutableArray *protokeys = [[NSMutableArray alloc] init];
            
            [protokeys addObject:[ProtocolKeys CARD_TITLE]];
            [protokeys addObject:[ProtocolKeys CARD_NAME]];
            [protokeys addObject:[ProtocolKeys CARD_CODE]];
            [protokeys addObject:[ProtocolKeys CARD_DESCRIPTION]];
            [protokeys addObject:[ProtocolKeys CARD_ISDEPENDENT]];
            [protokeys addObject:[ProtocolKeys CARD_NUMBER]];
            [protokeys addObject:[ProtocolKeys CARD_EXPIRATION]];
            [protokeys addObject:[ProtocolKeys CARD_ISSUE]];
            
            for (int i = 0; i < [resp count]; i++)
            {
                NSMutableDictionary *dic = (NSMutableDictionary*)resp[i];
                
                if( ProtocolValid(protokeys, dic) == false )
                {
                    DCAPIException *ex = [[DCAPIException alloc] initWithName:ERROR_HEADER reason:ERROR_INVALID_RESPONSE_MESSAGE userInfo:nil];
                    ex.code = [[NSString alloc] initWithFormat:@"%02d", SERVER_REPONSE_ERROR];
                    ex.show = false;
                    ex.message = ex.reason;
                    
                    @throw (ex);
                }
                
                CardInfo *ci = [CardInfo alloc];
                
                ci.title = dic[[ProtocolKeys CARD_TITLE]];
                ci.clientName = dic[[ProtocolKeys CARD_NAME]];
                ci.code = dic[[ProtocolKeys CARD_CODE]];
                ci.description = dic[[ProtocolKeys CARD_DESCRIPTION]];
                ci.isDependent = [dic[[ProtocolKeys CARD_ISDEPENDENT]] isEqualToString:[ProtocolKeys TRUE_MESSAGE]];
                ci.number = dic[[ProtocolKeys CARD_NUMBER]];
                
                if( [dic objectForKey:[ProtocolKeys CARD_EXPIRATION]] != nil || ![[dic objectForKey:[ProtocolKeys CARD_EXPIRATION]] isEqualToString:@""] )
                {
                    @try {
                        NSString *dateStr = dic[[ProtocolKeys CARD_EXPIRATION]];
                        
                        NSDateFormatter *dateFormat = [[NSDateFormatter alloc] init];
                        
                        [dateFormat setDateFormat:@"dd/MM/yyyy"];
                        
                        NSDate *date = [dateFormat dateFromString:dateStr];
                        
                        ci.expirationDate = date;
                    }
                    @catch (NSException *exception) {
                        ci.expirationDate = nil;
                    }
                   
                } else
                {
                    ci.expirationDate = nil;
                }
                
                if( [dic objectForKey:[ProtocolKeys CARD_ISSUE]] != nil || ![[dic objectForKey:[ProtocolKeys CARD_ISSUE]] isEqualToString:@""] )
                {
                    @try {
                        NSString *dateStr = dic[[ProtocolKeys CARD_ISSUE]];
                        
                        NSDateFormatter *dateFormat = [[NSDateFormatter alloc] init];
                        
                        [dateFormat setDateFormat:@"dd/MM/yyyy"];
                        
                        NSDate *date = [dateFormat dateFromString:dateStr];
                        
                        ci.issueDate = date;
                    }
                    @catch (NSException *exception) {
                        ci.issueDate = nil;
                    }
                    
                } else
                {
                    ci.issueDate = nil;
                }
                
                [arr addObject:ci];
            }
        }
        
    }
    @catch (DCAPIException *exception)
    {
        @throw;
    }
    @catch (NSException *exception) {
        DCAPIException *ex = [[DCAPIException alloc] initWithName:ERROR_HEADER reason:exception.reason userInfo:nil];
        ex.code = [[NSString alloc] initWithFormat:@"%02d", INTERNAL_API_ERROR];
        ex.show = false;
        ex.message = ex.reason;
        
        @throw (ex);

    }
    
    return arr;
}

- (BOOL) registerUserNotificationPushWithSecret: (NSString*) secret withPhoneID: (NSString*) PhoneID withGUID: (NSString*) GUID withDeviceToken: (NSString*) deviceToken
{
   @try{
       
       if(!internetReachable.isReachable)
       {
           DCAPIException *ex = [[DCAPIException alloc] initWithName:ERROR_HEADER reason:ERROR_NO_CONNECTION userInfo:nil];
           NSString *msg = ERROR_NO_CONNECTION;
           ex.code = [[NSString alloc] initWithFormat:@"%02d", SERVER_COMMUNICATION_ERROR];
           ex.show = true;
           ex.message = msg;
           
           @throw (ex);
       }
       
        NSString *sec = GetSecretFormat1(secret, PhoneID);
        NSData* dataKey = [MF_Base32Codec dataFromBase32String:sec];
        
        //NSData* dataKey = [MF_Base32Codec dataFromBase32String:secret];
        
        NSMutableDictionary * args = [[NSMutableDictionary alloc] init];
        
        args[ [ProtocolKeys GUID] ] = GUID;
        args[ [ProtocolKeys IMEI] ] = PhoneID;
        
        NSString *Token;
        
        TOTPGenerator *otpProvider = [[TOTPGenerator alloc] initWithSecret:dataKey algorithm:kOTPGeneratorSHA1Algorithm digits:6 period:30];
        
        NSDate *currentDate = [NSDate date];
        
        Token = [otpProvider generateOTPForDate:currentDate];
        
        args[ [ProtocolKeys TOKEN] ] = Token;
        args[ [ProtocolKeys DEVICETOKEN] ] = deviceToken;
        
        NSMutableArray * resp = makeHTTPRequest([[NSString alloc] initWithFormat:@"%@%@", __serverAdress, SERVLET_REGUSERNOTIFICATIONS], args, [__comunicationTimeout intValue]);
        
        if (resp == nil || [resp count] == 0 || [resp[0] objectForKey:[ProtocolKeys ERROR]] != nil) {
            DCAPIException *ex = [[DCAPIException alloc] initWithName:ERROR_HEADER reason:resp[0][[ProtocolKeys ERROR]] userInfo:nil];
            NSString *msg = resp[0][[ProtocolKeys ERROR]];
            ex.code = [msg substringWithRange:NSMakeRange(1, 2)];
            ex.show = [msg hasPrefix:@"1"];
            ex.message = [msg substringFromIndex:4];
            
            @throw (ex);
            
        } else if( [resp[0][[ProtocolKeys IS_OK]] isEqualToString: [ProtocolKeys TRUE_MESSAGE]] )
        {
            return true;
        }
    }
    @catch (DCAPIException *exception)
    {
        @throw;
    }
    @catch (NSException *exception) {
        DCAPIException *ex = [[DCAPIException alloc] initWithName:ERROR_HEADER reason:exception.reason userInfo:nil];
        ex.code = [[NSString alloc] initWithFormat:@"%02d", INTERNAL_API_ERROR];
        ex.show = false;
        ex.message = ex.reason;
        
        @throw (ex);
    }
    
    return false;
}

- (NSMutableArray*) receiveBenefitsWithSecret: (NSString*) secret withPhoneID: (NSString*) PhoneID withGUID: (NSString*) guid
{
    NSMutableArray *arr = [[NSMutableArray alloc] init];
    
    @try {
        
        if(!internetReachable.isReachable)
        {
            DCAPIException *ex = [[DCAPIException alloc] initWithName:ERROR_HEADER reason:ERROR_NO_CONNECTION userInfo:nil];
            NSString *msg = ERROR_NO_CONNECTION;
            ex.code = [[NSString alloc] initWithFormat:@"%02d", SERVER_COMMUNICATION_ERROR];
            ex.show = true;
            ex.message = msg;
            
            @throw (ex);
        }
        
        NSString *sec = GetSecretFormat1(secret, PhoneID);
        NSData* dataKey = [MF_Base32Codec dataFromBase32String:sec];
        //NSData* dataKey = [MF_Base32Codec dataFromBase32String:[secret base32String]];
        
        NSString *Token;
        
        TOTPGenerator *otpProvider = [[TOTPGenerator alloc] initWithSecret:dataKey algorithm:kOTPGeneratorSHA1Algorithm digits:6 period:30];
        
        NSDate *currentDate = [NSDate date];
        
        Token = [otpProvider generateOTPForDate:currentDate];
        
        NSMutableDictionary * args = [[NSMutableDictionary alloc] init];
        
        args[ [ProtocolKeys GUID] ] = guid;
        args[ [ProtocolKeys TOKEN] ] = Token;
        
        NSMutableArray * resp = makeHTTPRequest([[NSString alloc] initWithFormat:@"%@%@", __serverAdress, SERVLET_RECEIVENOTIFICATIONS], args, [__comunicationTimeout intValue]);
        
        if (resp == nil || [resp count] == 0 || [resp[0] objectForKey:[ProtocolKeys ERROR]] != nil) {
           
            if( resp != nil && [resp count] == 0)
            {
                return arr;
            } else
            {
                DCAPIException *ex = [[DCAPIException alloc] initWithName:ERROR_HEADER reason:resp[0][[ProtocolKeys ERROR]] userInfo:nil];
                NSString *msg = resp[0][[ProtocolKeys ERROR]];
                ex.code = [msg substringWithRange:NSMakeRange(1, 2)];
                ex.show = [msg hasPrefix:@"1"];
                ex.message = [msg substringFromIndex:4];
                
                @throw (ex);
            }
            
        } else
        {
            NSMutableArray *protokeys = [[NSMutableArray alloc] init];
            
            [protokeys addObject:[ProtocolKeys NOT_SUBJECT]];
            [protokeys addObject:[ProtocolKeys NOT_MESSAGE]];
            [protokeys addObject:[ProtocolKeys NOT_TIMESTAMP]];
            
            for (int i = 0; i < [resp count]; i++)
            {
                NSMutableDictionary *dic = (NSMutableDictionary*)resp[i];
                
                if( ProtocolValid(protokeys, dic) == false )
                {
                    DCAPIException *ex = [[DCAPIException alloc] initWithName:ERROR_HEADER reason:ERROR_INVALID_RESPONSE_MESSAGE userInfo:nil];
                    ex.code = [[NSString alloc] initWithFormat:@"%02d", SERVER_REPONSE_ERROR];
                    ex.show = false;
                    ex.message = ex.reason;
                    
                    @throw (ex);
                }
                
                Notification *note = [Notification alloc];
                
                note.title = dic[[ProtocolKeys NOT_SUBJECT]];
                note.message = dic[[ProtocolKeys NOT_MESSAGE]];
                
                NSString *dateStr = dic[[ProtocolKeys NOT_TIMESTAMP]];
                
                NSDateFormatter *dateFormat = [[NSDateFormatter alloc] init];
                
                [dateFormat setDateFormat:@"dd/MM/yyyy HH:mm:ss"];
                
                NSDate *date = [dateFormat dateFromString:dateStr];
                
                note.UTCTimeStamp = date;
                
                if( [dic objectForKey:[ProtocolKeys NOT_IMAGE]] != nil )
                {
                    @try {
                        
                        NSString *image64 = dic[[ProtocolKeys NOT_IMAGE]];
                        
                        NSData *data = [[NSData alloc] initWithBase64EncodedString:image64 options:NSDataBase64DecodingIgnoreUnknownCharacters];
                        
                        UIImage *image = [UIImage imageWithData:data];
                        
                        note.image = image;
                        
                    }
                    @catch (NSException *exception) {
                        note.image = nil;
                    }
                    
                } else
                {
                    note.image = nil;
                }
                
                [arr addObject:note];
            }
        }
        
    }
    @catch (DCAPIException *exception)
    {
        @throw;
    }
    @catch (NSException *exception) {
        DCAPIException *ex = [[DCAPIException alloc] initWithName:ERROR_HEADER reason:exception.reason userInfo:nil];
        ex.code = [[NSString alloc] initWithFormat:@"%02d", INTERNAL_API_ERROR];
        ex.show = false;
        ex.message = ex.reason;
        
        @throw (ex);
    }
    
    return arr;
}

- (NSMutableArray*) receiveTransactionsWithSecret: (NSString*) secret withPhoneID: (NSString*) PhoneID withGUID: (NSString*) guid withCNT: (int) cnt withLastGUID: (NSString*) lastGuid;
{
    NSMutableArray *arr = [[NSMutableArray alloc] init];
    
    @try {
        
        if(!internetReachable.isReachable)
        {
            DCAPIException *ex = [[DCAPIException alloc] initWithName:ERROR_HEADER reason:ERROR_NO_CONNECTION userInfo:nil];
            NSString *msg = ERROR_NO_CONNECTION;
            ex.code = [[NSString alloc] initWithFormat:@"%02d", SERVER_COMMUNICATION_ERROR];
            ex.show = true;
            ex.message = msg;
            
            @throw (ex);
        }
        
        NSString *sec = GetSecretFormat1(secret, PhoneID);
        NSData* dataKey = [MF_Base32Codec dataFromBase32String:sec];
        //NSData* dataKey = [MF_Base32Codec dataFromBase32String:secret];
        
        NSString *Token;
        
        TOTPGenerator *otpProvider = [[TOTPGenerator alloc] initWithSecret:dataKey algorithm:kOTPGeneratorSHA1Algorithm digits:6 period:30];
        
        NSDate *currentDate = [NSDate date];
        
        Token = [otpProvider generateOTPForDate:currentDate];
        
        NSMutableDictionary * args = [[NSMutableDictionary alloc] init];
        
        args[ [ProtocolKeys GUID] ] = guid;
        args[ [ProtocolKeys TOKEN] ] = Token;
        args[ [ProtocolKeys TRANS_CNT] ] = [[NSString alloc] initWithFormat:@"%d", cnt];
        
        if(lastGuid == nil) lastGuid = @"-1";
        
        args[ [ProtocolKeys TRANS_GUID] ] = lastGuid;
        
        NSMutableArray * resp = makeHTTPRequest([[NSString alloc] initWithFormat:@"%@%@", __serverAdress, SERVLET_RECEIVETRANSACTIONS], args, [__comunicationTimeout intValue]);
        
        if (resp == nil || [resp count] == 0 || [resp[0] objectForKey:[ProtocolKeys ERROR]] != nil) {
            
            if( resp != nil && [resp count] == 0)
            {
                return arr;
            } else
            {
                DCAPIException *ex = [[DCAPIException alloc] initWithName:ERROR_HEADER reason:resp[0][[ProtocolKeys ERROR]] userInfo:nil];
                NSString *msg = resp[0][[ProtocolKeys ERROR]];
                ex.code = [msg substringWithRange:NSMakeRange(1, 2)];
                ex.show = [msg hasPrefix:@"1"];
                ex.message = [msg substringFromIndex:4];
                
                @throw (ex);
            }
            
        } else
        {
            NSMutableArray *protokeys = [[NSMutableArray alloc] init];
            
            [protokeys addObject:[ProtocolKeys TRANS_COMPANY]];
            [protokeys addObject:[ProtocolKeys TRANS_EVALUATION]];
            [protokeys addObject:[ProtocolKeys TRANS_EVALUATION_MSG]];
            [protokeys addObject:[ProtocolKeys TRANS_LOCATION]];
            [protokeys addObject:[ProtocolKeys TRANS_PROCEDURE]];
            [protokeys addObject:[ProtocolKeys TRANS_GUID]];
            [protokeys addObject:[ProtocolKeys TRANS_CARD_NUMBER]];
            [protokeys addObject:[ProtocolKeys TRANS_CARD_TYPE]];
            [protokeys addObject:[ProtocolKeys TRANS_TIMESTAMP]];
            
            for (int i = 0; i < [resp count]; i++)
            {
                NSMutableDictionary *dic = (NSMutableDictionary*)resp[i];
                
                if( ProtocolValid(protokeys, dic) == false )
                {
                    DCAPIException *ex = [[DCAPIException alloc] initWithName:ERROR_HEADER reason:ERROR_INVALID_RESPONSE_MESSAGE userInfo:nil];
                    ex.code = [[NSString alloc] initWithFormat:@"%02d", SERVER_REPONSE_ERROR];
                    ex.show = false;
                    ex.message = ex.reason;
                    
                    @throw (ex);
                }
                
                Transaction *trans = [Transaction alloc];
                
                trans.company = dic[[ProtocolKeys TRANS_COMPANY]];
                
                trans.evaluation = [dic[[ProtocolKeys TRANS_EVALUATION]] intValue];
                
                trans.evaluationMessage = dic[[ProtocolKeys TRANS_EVALUATION_MSG]];
                trans.location = dic[[ProtocolKeys TRANS_LOCATION]];
                trans.procedure = dic[[ProtocolKeys TRANS_PROCEDURE]];
                trans.transactionGUID = dic[[ProtocolKeys TRANS_GUID]];
                
                trans.cardNumber = dic[[ProtocolKeys TRANS_CARD_NUMBER]];
                
                trans.cardType = dic[[ProtocolKeys TRANS_CARD_TYPE]];
                
                NSString *dateStr = dic[[ProtocolKeys TRANS_TIMESTAMP]];
                
                NSDateFormatter *dateFormat = [[NSDateFormatter alloc] init];
                
                [dateFormat setDateFormat:@"dd/MM/yyyy HH:mm:ss"];
                
                NSDate *date = [dateFormat dateFromString:dateStr];
                
                trans.UTCTimeStamp = date;
                
                [arr addObject:trans];
            }
        }
        
    }
    @catch (DCAPIException *exception)
    {
        @throw;
    }
    @catch (NSException *exception) {
        DCAPIException *ex = [[DCAPIException alloc] initWithName:ERROR_HEADER reason:exception.reason userInfo:nil];
        ex.code = [[NSString alloc] initWithFormat:@"%02d", INTERNAL_API_ERROR];
        ex.show = false;
        ex.message = ex.reason;
        
        @throw (ex);
    }
    
    return arr;
}


- (BOOL) sendEvaluationWithTransGuid: (NSString*) transactionGuid withRate: (int) rate withMessage: (NSString*) message withPhoneID: (NSString*) PhoneID withGUID: (NSString*) guid withKEY: (NSString*) secretKey
{
   @try {
       
       if(!internetReachable.isReachable)
       {
           DCAPIException *ex = [[DCAPIException alloc] initWithName:ERROR_HEADER reason:ERROR_NO_CONNECTION userInfo:nil];
           NSString *msg = ERROR_NO_CONNECTION;
           ex.code = [[NSString alloc] initWithFormat:@"%02d", SERVER_COMMUNICATION_ERROR];
           ex.show = true;
           ex.message = msg;
           
           @throw (ex);
       }
       
        NSString *sec = GetSecretFormat1(secretKey, PhoneID);
        NSData* dataKey = [MF_Base32Codec dataFromBase32String:sec];
        //NSData* dataKey = [MF_Base32Codec dataFromBase32String:secretKey];
        
        NSString *Token;
        
        TOTPGenerator *otpProvider = [[TOTPGenerator alloc] initWithSecret:dataKey algorithm:kOTPGeneratorSHA1Algorithm digits:6 period:30];
        
        NSDate *currentDate = [NSDate date];
        
        Token = [otpProvider generateOTPForDate:currentDate];
        
        NSMutableDictionary * args = [[NSMutableDictionary alloc] init];
        
        if( message == nil || [message length] == 0 )
        {
            message = @" ";
        }
        
        args[ [ProtocolKeys TRANS_GUID] ] = transactionGuid;
        args[ [ProtocolKeys TRANS_EVALUATION] ] = [[NSString alloc] initWithFormat:@"%d", rate];
        args[ [ProtocolKeys TRANS_EVALUATION_MSG] ] = message;
        args[ [ProtocolKeys GUID] ] = guid;
        args[ [ProtocolKeys TOKEN] ] = Token;
       
        NSMutableArray * resp = makeHTTPRequest([[NSString alloc] initWithFormat:@"%@%@", __serverAdress, SERVLET_EVALTRANSACTION], args, [__comunicationTimeout intValue]);
        
        if (resp == nil || [resp count] == 0 || [resp[0] objectForKey:[ProtocolKeys ERROR]] != nil) {
            DCAPIException *ex = [[DCAPIException alloc] initWithName:ERROR_HEADER reason:resp[0][[ProtocolKeys ERROR]] userInfo:nil];
            NSString *msg = resp[0][[ProtocolKeys ERROR]];
            ex.code = [msg substringWithRange:NSMakeRange(1, 2)];
            ex.show = [msg hasPrefix:@"1"];
            ex.message = [msg substringFromIndex:4];
            
            @throw (ex);
        } else if( [resp[0][[ProtocolKeys IS_OK]] isEqualToString:[ProtocolKeys TRUE_MESSAGE]] )
        {
            return true;
        }
        
    }
    @catch (DCAPIException *exception)
    {
        @throw;
    }
    @catch (NSException *exception) {
        DCAPIException *ex = [[DCAPIException alloc] initWithName:ERROR_HEADER reason:exception.reason userInfo:nil];
        ex.code = [[NSString alloc] initWithFormat:@"%02d", INTERNAL_API_ERROR];
        ex.show = false;
        ex.message = ex.reason;
        
        @throw (ex);
    }
    
    return false;
}

- (QRCodeResp*) createQRCodeWithSecret: (NSString*) secretKey withGUID: (NSString*) guid withLatitute: (float) latitute withLongitute: (float) longitude withCard: (NSString*) cardNumber withPhoneID: (NSString*) PhoneID withCardType: (NSString*) cardTypeCode withWith: (int) width withHeight: (int) height
{
    NSString *sec = GetSecretFormat2(secretKey, PhoneID, cardNumber);
    NSData* dataKey = [MF_Base32Codec dataFromBase32String:sec];
    //NSData* dataKey = [MF_Base32Codec dataFromBase32String:secretKey];
    
    NSString *Token;
    
    TOTPGenerator *otpProvider = [[TOTPGenerator alloc] initWithSecret:dataKey algorithm:kOTPGeneratorSHA1Algorithm digits:6 period:30];
    
    NSDate *currentDate = [NSDate date];
    
    Token = [otpProvider generateOTPForDate:currentDate];
    
    NSTimeInterval now = [currentDate timeIntervalSince1970];
    
    long currentValue = [otpProvider valueAtTime: (now/1000)];
    
    long nextValue = currentValue + 1;
    
    long nextValueStartTime = [otpProvider startTimeWithValue:nextValue] * 1000;
    
    long timeout = nextValueStartTime - now;
    
    QRCodeResp *resp = [QRCodeResp alloc];
    
    //NSString* contents = [[NSString alloc] initWithFormat:@"%@:%@:%f:%f:%@:%@", Token, guid, latitute, longitude, cardNumber, PhoneID];
    NSString* contents = [[NSString alloc] initWithFormat:@"%@:%@:%f:%f:%@", cardNumber, Token, latitute, longitude, cardTypeCode];
    
    QRcode *qrcode_ = QRcode_encodeString([contents UTF8String], 0, QR_ECLEVEL_H, QR_MODE_8, 1);
    
    UIImage *rr = convertBitmapRGBA8ToUIImage(qrcode_->data, qrcode_->width, qrcode_->width );
    
    UIImage *r = imageWithImage(rr, CGSizeMake(width, height));
    
    resp.image = r;
    
    QRcode_free(qrcode_);
    
    resp.token = Token;
    resp.timeout = timeout % 30;
    resp.interval = 30;
    
    return resp;
}

- (TokenResp*) createTokenWithSecret: (NSString*) secretkey withPhoneID: (NSString*) PhoneID withCard: (NSString*) cardNumber
{
    NSString *sec = GetSecretFormat2(secretkey, PhoneID, cardNumber);
    NSData* dataKey = [MF_Base32Codec dataFromBase32String:sec];
    //NSData* dataKey = [MF_Base32Codec dataFromBase32String:secretkey];
    
    NSString *Token;
    
    TOTPGenerator *otpProvider = [[TOTPGenerator alloc] initWithSecret:dataKey algorithm:kOTPGeneratorSHA1Algorithm digits:6 period:30];
    
    NSDate *currentDate = [NSDate date];
    
    Token = [otpProvider generateOTPForDate:currentDate];
    
    NSTimeInterval now = [currentDate timeIntervalSince1970];
    
    long currentValue = [otpProvider valueAtTime: (now/1000)];
    
    long nextValue = currentValue + 1;
    
    long nextValueStartTime = [otpProvider startTimeWithValue:nextValue] * 1000;
    
    long timeout = nextValueStartTime - now;
    
    TokenResp *resp = [TokenResp alloc];
    
    resp.token = Token;
    resp.timeout = timeout % 30;
    
    return resp;
}

@end

NSDate* convertToUTC( NSDate* sourceDate)
{
    NSTimeZone* currentTimeZone = [NSTimeZone localTimeZone];
    NSTimeZone* utcTimeZone = [NSTimeZone timeZoneWithAbbreviation:@"UTC"];
    
    NSInteger currentGMTOffset = [currentTimeZone secondsFromGMTForDate:sourceDate];
    NSInteger gmtOffset = [utcTimeZone secondsFromGMTForDate:sourceDate];
    NSTimeInterval gmtInterval = gmtOffset - currentGMTOffset;
    
    NSDate* destinationDate = [[NSDate alloc] initWithTimeInterval:gmtInterval sinceDate:sourceDate];
    
    return destinationDate;
}

UIImage* convertBitmapRGBA8ToUIImage(unsigned char * buffer, int width, int height )
{
    
    // added code
    char* rgba = (char*)malloc(width*height);
    
    memset(  rgba, 0, width*height* sizeof(char));
    for(int i=0; i < width*height; ++i) {
        //rgba[4*i] = buffer[3*i];
        ///rgba[4*i+1] = buffer[3*i+1];
       // rgba[4*i+2] = buffer[3*i+2];
        
        if (buffer[i] & 1)
        {
            rgba[i] = 0;

        } else
        {
            rgba[i] = 255;
        }
    }
    //
    
    size_t bufferLength = width * height;
    CGDataProviderRef provider = CGDataProviderCreateWithData(NULL, rgba, bufferLength, NULL);
    size_t bitsPerComponent = 8;
    size_t bitsPerPixel = 8;
    size_t bytesPerRow = width;
    
    CGColorSpaceRef colorSpaceRef = CGColorSpaceCreateDeviceGray();
    if(colorSpaceRef == NULL) {
        NSLog(@"Error allocating color space");
        CGDataProviderRelease(provider);
        return nil;
    }
    
    CGBitmapInfo bitmapInfo = kCGBitmapByteOrderDefault;
    CGColorRenderingIntent renderingIntent = kCGRenderingIntentDefault;
    
    CGImageRef iref = CGImageCreate(width,
                                    height,
                                    bitsPerComponent,
                                    bitsPerPixel,
                                    bytesPerRow,
                                    colorSpaceRef,
                                    bitmapInfo,
                                    provider,   // data provider
                                    NULL,       // decode
                                    YES,            // should interpolate
                                    renderingIntent);
    
    uint32_t* pixels = (uint32_t*)malloc(bufferLength);
    
    if(pixels == NULL) {
        NSLog(@"Error: Memory not allocated for bitmap");
        CGDataProviderRelease(provider);
        CGColorSpaceRelease(colorSpaceRef);
        CGImageRelease(iref);
        return nil;
    }
    
    CGContextRef context = CGBitmapContextCreate(pixels,
                                                 width,
                                                 height,
                                                 bitsPerComponent,
                                                 bytesPerRow,
                                                 colorSpaceRef,
                                                 bitmapInfo);
    
    if(context == NULL) {
        NSLog(@"Error context not created");
        free(pixels);
    }
    
    UIImage *image = nil;
    if(context) {
        
        CGContextDrawImage(context, CGRectMake(0.0f, 0.0f, width, height), iref);
        
        CGImageRef imageRef = CGBitmapContextCreateImage(context);
        
        // Support both iPad 3.2 and iPhone 4 Retina displays with the correct scale
        if([UIImage respondsToSelector:@selector(imageWithCGImage:scale:orientation:)]) {
            float scale = [[UIScreen mainScreen] scale];
            image = [UIImage imageWithCGImage:imageRef scale:scale orientation:UIImageOrientationUp];
        } else {
            image = [UIImage imageWithCGImage:imageRef];
        }
        
        CGImageRelease(imageRef);
        CGContextRelease(context);
    }
    
    CGColorSpaceRelease(colorSpaceRef);
    CGImageRelease(iref);
    CGDataProviderRelease(provider);
    
    if(pixels) {
        free(pixels);
    }
    
    return image;
}

BOOL ProtocolValid(NSMutableArray *keys, NSMutableDictionary* resp)
{
    for(int i = 0 ; i < [keys count] ; i++)
    {
        if( [resp objectForKey:keys[i]] == nil )
            return false;
    }
    
    return true;
}

NSString *GetSecretFormat1(NSString *secret, NSString *phoneid)
{
    NSMutableData *concatenatedData = [NSMutableData data];
    
    NSData *sec = [MF_Base32Codec dataFromBase32String:secret];
    
    NSData* phi = [phoneid dataUsingEncoding:NSUTF8StringEncoding];
    
    [concatenatedData appendData:phi];
    [concatenatedData appendData:sec];
    
    NSString * res = [MF_Base32Codec base32StringFromData:concatenatedData];
    
    return res;
}

NSString *GetSecretFormat2(NSString *secret, NSString *phoneid, NSString *cardid)
{
    NSMutableData *concatenatedData = [NSMutableData data];
    
    NSData *sec = [MF_Base32Codec dataFromBase32String:secret];
    
    NSData* phi = [phoneid dataUsingEncoding:NSUTF8StringEncoding];
    
    NSData* cid = [cardid dataUsingEncoding:NSUTF8StringEncoding];
    
    [concatenatedData appendData:phi];
    [concatenatedData appendData:cid];
    [concatenatedData appendData:sec];
    
    NSString * res = [MF_Base32Codec base32StringFromData:concatenatedData];
    
    return res;
}

NSString *decodeURL(NSString *value)
{    
    NSString *encodedString = [[value stringByReplacingOccurrencesOfString:@"+" withString:@" "] stringByReplacingPercentEscapesUsingEncoding:NSUTF8StringEncoding];
    
    if (encodedString == nil)
    {
        encodedString = [[value stringByReplacingOccurrencesOfString:@"+" withString:@" "] stringByReplacingPercentEscapesUsingEncoding:NSASCIIStringEncoding];
        
        if (encodedString == nil)
        {
            encodedString = value;
        }
    }
    
    return encodedString;
}

NSMutableArray* makeHTTPRequest(NSString* ServletAddress, NSMutableDictionary* args, int comunicationTimeout)
{
    NSMutableURLRequest *request = [[NSMutableURLRequest alloc] initWithURL:[NSURL URLWithString:ServletAddress] cachePolicy:NSURLRequestReloadIgnoringLocalAndRemoteCacheData timeoutInterval:comunicationTimeout];
    
    [request setHTTPMethod:@"POST"];
    
    NSMutableString *dataString = [[NSMutableString alloc] init];
    
    for (id key in args) {
        id value = [args objectForKey:key];
        [dataString appendFormat:@"%@=%@&", (NSString*)key, (NSString*)value];
    }
    
    [request setValue:[NSString stringWithFormat:@"%lu", (unsigned long)[dataString length]] forHTTPHeaderField:@"Content-length"];
    
    [request setHTTPBody:[dataString dataUsingEncoding:NSUTF8StringEncoding]];
    
    NSURLResponse* response = nil;

    NSData* data = nil;
    
    NSError *requestError;
    
    @try {
        data = [NSURLConnection sendSynchronousRequest:request returningResponse:&response error:&requestError];
    }
    @catch (NSException *exception) {
        DCAPIException *ex = [[DCAPIException alloc] initWithName:ERROR_HEADER reason:exception.reason userInfo:nil];
        ex.code = [[NSString alloc] initWithFormat:@"%d", INTERNAL_API_ERROR];
        ex.message = ex.reason;
        ex.show = false;
        
        @throw (ex);
    }
    
    if(data == nil)
    {
        if(requestError != nil)
        {
            DCAPIException *ex = [[DCAPIException alloc] initWithName:[requestError localizedDescription] reason:[requestError localizedFailureReason] userInfo:nil];
            ex.code = [[NSString alloc] initWithFormat:@"%d", SERVER_COMMUNICATION_ERROR];
            ex.message = ex.reason;
            ex.show = true;
            @throw (ex);
        } else
        {
            DCAPIException *ex = [[DCAPIException alloc] initWithName:ERROR_HEADER reason:ERROR_INTERNAL_MESSAGE userInfo:nil];
            ex.code = [[NSString alloc] initWithFormat:@"%d", INTERNAL_API_ERROR];
            ex.message = ex.reason;
            ex.show = false;
            @throw (ex);
        }
    }
    
    NSString *responsestr = [[NSString alloc] initWithData:data encoding:NSUTF8StringEncoding];
    
    if(responsestr == nil)
        responsestr = [[NSString alloc] initWithData:data encoding:NSASCIIStringEncoding];
    
    if(responsestr == nil)
    {
        DCAPIException *ex = [[DCAPIException alloc] initWithName:ERROR_HEADER reason:ERROR_INTERNAL_MESSAGE userInfo:nil];
        ex.code = [[NSString alloc] initWithFormat:@"%02d", INTERNAL_API_ERROR];
        ex.message = ex.reason;
        ex.show = true;
        
        @throw (ex);
    }
    
    if ( [responsestr rangeOfString:@"<html"].location != NSNotFound )
    {
        DCAPIException *ex = [[DCAPIException alloc] initWithName:ERROR_HEADER reason:ERROR_INVALID_RESPONSE_MESSAGE userInfo:nil];
        ex.code = [[NSString alloc] initWithFormat:@"%02d", SERVER_REPONSE_ERROR];
        ex.message = ex.reason;
        ex.show = true;
        
        @throw (ex);
    }
    
    NSMutableArray *resp = [[NSMutableArray alloc] init];
    
    NSArray *objcts = [responsestr componentsSeparatedByString:@";"];
    
    for (int i = 0; i < [objcts count]; i++)
    {
        NSString * str = objcts[i];
        
        if(str == nil || [str length] == 0) continue;
        
        NSArray *key_values = [str componentsSeparatedByString:@"&"];
        
        NSMutableDictionary *respobj = [[NSMutableDictionary alloc] init];
        
        for (int j = 0; j < [key_values count]; j++)
        {
            NSString * str2 = key_values[j];
            
            if(str2 == nil || [str2 length] == 0) continue;
            
            NSArray *data_val = [str2 componentsSeparatedByString:@"="];
            
            respobj[data_val[0]] = decodeURL(data_val[1]);
        }
        
        [resp addObject:respobj];
    }
    
    return resp;
}

UIImage * imageWithImage(UIImage *image, CGSize size)
{
    UIGraphicsBeginImageContext(size);
    
    CGContextRef context = UIGraphicsGetCurrentContext();
    
    CGContextSetInterpolationQuality(context, kCGInterpolationNone);
    CGContextSetAllowsAntialiasing(context, false);
    
    [image drawInRect:CGRectMake(0, 0, size.width, size.height)];
    UIImage *destImage = UIGraphicsGetImageFromCurrentImageContext();
    
    UIGraphicsEndImageContext();
    return destImage;
}

