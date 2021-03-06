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
//#import "NSURLRequest+IgnoreSSL.h"
#import "cryptlib.h"
#include <stdlib.h>
#import "AuthResponse.h"

#import <CommonCrypto/CommonCryptor.h>
#import <UIKit/UIKit.h>

static DCAPID *sharedSingleton = NULL;

// MENSAGENS ESTÁTICAS
static NSString *ERROR_WRONG_SERVER_ADDRESS = @"O endereço do servidor está incorreto.";
static NSString *ERROR_CONNECTION_TIMEOUT = @"Não foi possível conectar ao Serviço Wallet";
static NSString *ERROR_NO_CONNECTION = @"Sem conexão com a Internet.";
static NSString *ERROR_CONNECTION_ERROR = @"Falha na comunicação.";

static NSString *ERROR_HEADER = @"DCAPI Error";
static NSString *ERROR_INTERNAL_MESSAGE = @"Falha interna!";
static NSString *ERROR_INTERNAL_DATA_MESSAGE = @"Aparelho não registrado no serviço!";
static NSString *ERROR_INVALID_RESPONSE_MESSAGE = @"Protocolo ou resposta inválida!";

static NSString *ERROR_PARAMETER_MESSAGE = @"Parâmetro inválido!";

// Comandos do servidor
static NSString *SERVLET_REGUSER = @"RegUser";
static NSString *SERVLET_RECOVERPASSWORD = @"RecoverPassword";
static NSString *SERVLET_CHANGEPASSWORD = @"ChangePassword";
static NSString *SERVLET_RETRIEVEEMAIL = @"RetrieveEmail";
static NSString *SERVLET_REGPHONE = @"RegPhone";
static NSString *SERVLET_RECEIVECARDS = @"ReceiveCards";
static NSString *SERVLET_RECEIVENOTIFICATIONS = @"ReceiveBenefits";
static NSString *SERVLET_DOWNLOADBENEFITIMAGE = @"DownloadImageBenefit";
static NSString *SERVLET_RECEIVETRANSACTIONS = @"ReceiveTransactions";
static NSString *SERVLET_EVALTRANSACTION = @"EvalTransaction";
static NSString *SERVLET_REGUSERNOTIFICATIONS = @"RegUserNotifications";

// Verificador de internet.
static Reachability *internetReachable = nil;

// CHAVE MESTRA
#define DCAPI_KEY @"745e8F18d4A34B0b"

// Código de erro.
enum ErrorCode {
    SERVER_REPONSE_ERROR, SERVER_COMMUNICATION_ERROR, INTERNAL_API_ERROR, INTERNAL_DATA_ERROR,
    PARAMETER_ERROR
};

/**
 * Realiza a solicitação ao servidor de cartões digitais para obter dados textuais.
 * @author Rodrigo Marques
 *
 * @param ServletAddress Segredo.
 * @param args Parâmetros do protocolo.
 * @param comunicationTimeout Tempo máximo de espera.
 * @return Retorna os dados textuais solicitados em forma de lista chave valor caso seja bem sucedida e null c.c.
 */
NSMutableArray* makeHTTPRequest(NSString* ServletAddress, NSMutableDictionary* args, int comunicationTimeout);

/**
 * Redimensiona uma imagem usando nearest.
 * @author Rodrigo Marques
 *
 * @param image Imagem associada.
 * @param size Novo tamanho pretendido.
 * @return Retorna a imagem redimensionada.
 */
UIImage * imageWithImage(UIImage *image, CGSize size);

/**
 * Converte um Bitmap (byte array) em uma imagem RGB de 8 bits por canal.
 * @author Rodrigo Marques
 *
 * @param buffer Imagem associada.
 * @param width Largura da imagem codificada no vetor.
 * @param height Altura da imagem codificada no vetor.
 * @return Retorna a imagem caso seja bem sucedida e null c.c.
 */
UIImage* convertBitmapRGBA8ToUIImage(unsigned char * buffer, int width, int height );

/**
 * Avalia se a resposta do servidor está de acordo com o protocolo e se os campos necessários estão presentes.
 * @author Rodrigo Marques
 *
 * @param keys Chaves necessárias.
 * @param resp Reposta do servidor.
 * @return Retorna true caso seja bem sucedida e false c.c.
 */
BOOL ProtocolValid(NSMutableArray *keys, NSMutableDictionary* resp);

/**
 * Converte uma data para UTC.
 * @author Rodrigo Marques
 *
 * @param sourceDate Data local.
 * @return Retorna a data em UTC caso seja bem sucedida e null c.c.
 */
NSDate* convertToUTC( NSDate* sourceDate);

/**
 * Gera o segredo do token tipo 1.
 * @author Rodrigo Marques
 *
 * @param secret Segredo.
 * @param phoneid Id do aparelho.
 * @return Retorna o segredo tipo 1 caso seja bem sucedida e null c.c.
 */
NSString *GetSecretFormat1(NSString *secret, NSString *phoneid);

/**
 * Gera o segredo do token tipo 2.
 * @author Rodrigo Marques
 *
 * @param secret Segredo.
 * @param phoneid Id do aparelho.
 * @param cardid Número do cartão.
 * @return Retorna o segredo tipo 2 caso seja bem sucedida e null c.c.
 */
NSString *GetSecretFormat2(NSString *secret, NSString *phoneid, NSString *cardid);

/**
 * Decodifica uma string encodada em URL.
 * @author Rodrigo Marques
 *
 * @param value String a ser decodificada.
 * @return Retorna a string decodificada caso seja bem sucedida e null c.c.
 */
NSString *decodeURL(NSString *value);

/**
 * Realiza a solicitação ao servidor de cartões digitais para obter dados binários.
 * @author Rodrigo Marques
 *
 * @param ServletAddress Segredo.
 * @param args Parâmetros do protocolo.
 * @param comunicationTimeout Tempo máximo de espera.
 * @return Retorna os dados binários solicitados caso seja bem sucedida e null c.c.
 */
NSData* makeHTTPRequestData(NSString* ServletAddress, NSMutableDictionary* args, int comunicationTimeout);

/**
 * Gera o cifrador de tempo.
 * @author Rodrigo Marques
 *
 * @return Retorna o valor novo do cifrador.
 */
NSString *GenTimeST();

/**
 * Salva o cifrador de tempo.
 * @author Rodrigo Marques
 *
 * @param timestamp Cifrador.
 * @return Sem Retorno.
 */
void SaveTimeST(NSString * timestamp);

/**
 * Recupera o cifrador de tempo.
 * @author Rodrigo Marques
 *
 * @return Retorna o valor atual do cifrador.
 */
NSString *GetTimeST();

/**
 * Recupera a senha do usuário de forma segura usando K2.
 * @author Rodrigo Marques
 *
 * @return Retorna a senha se os dados estivem corretos ou null c.c. ou haja comprometimento do cifrador de tempo.
 */
NSString* getPassword()
{
    NSUserDefaults *currentDefaults = [NSUserDefaults standardUserDefaults];
    
    NSString *pass = [currentDefaults objectForKey:@"dcapiPwd"];
    
    if (pass == nil)
        return nil;
    
    NSString *timestamp = GetTimeST();
    
    @try {
        
        int tokenval = [timestamp intValue];
        
        NSString *uniqueID = [UIDevice currentDevice].identifierForVendor.UUIDString;
        
        srand(tokenval);
        
        int rval = (int)(rand() / (float)RAND_MAX * 100000.0) + 100;
        
        NSString *rnd = [[NSString alloc] initWithFormat:@"%d", rval ];
        
        NSString *k2 = [[NSString alloc] initWithFormat:@"%@%@%@",[timestamp substringWithRange:NSMakeRange(4,3)], [uniqueID substringWithRange:NSMakeRange(3, 3)], [rnd substringWithRange:NSMakeRange(0, 2)]];
        
        if( pass != nil)
        {
            NSData *cipher = [MF_Base32Codec dataFromBase32String:pass];
            
            NSData *plain = [cipher AES256DecryptWithKey:k2];
            
            pass = [[NSString alloc] initWithData:plain encoding:NSUTF8StringEncoding];
        }
    }
    @catch (NSException *exception) {
        DCAPIException *ex = [[DCAPIException alloc] initWithName:ERROR_HEADER reason:exception.reason userInfo:nil];
        NSString *msg = exception.description;
        ex.code = [[NSString alloc] initWithFormat:@"%02d", INTERNAL_API_ERROR];
        ex.show = true;
        ex.message = msg;
        
        @throw (ex);
    }
    
    return pass;
}

/**
 * Salva a senha do usuário de forma segura usando K2.
 * @author Rodrigo Marques
 *
 * @param pass Senha do usuário.
 * @return Sem Retorno.
 */
void setPassword(NSString* pass)
{
    NSString *timestamp = GetTimeST();
    
    @try {
        if( pass != nil)
        {
            int tokenval = [timestamp intValue];
            
            NSString *uniqueID = [UIDevice currentDevice].identifierForVendor.UUIDString;
            
            srand(tokenval);
            
            int rval = (int)(rand() / (float)RAND_MAX * 100000.0) + 100;
            
            NSString *rnd = [[NSString alloc] initWithFormat:@"%d", rval ];
            
            NSString *k2 = [[NSString alloc] initWithFormat:@"%@%@%@",[timestamp substringWithRange:NSMakeRange(4,3)], [uniqueID substringWithRange:NSMakeRange(3, 3)], [rnd substringWithRange:NSMakeRange(0, 2)]];
            
            
            NSData *plain = [pass dataUsingEncoding:NSUTF8StringEncoding];
            
            NSData *cipher = [plain AES256EncryptWithKey:k2];
            
            NSString *passc = [MF_Base32Codec base32StringFromData:cipher];
            
            NSUserDefaults *currentDefaults = [NSUserDefaults standardUserDefaults];
            
            [currentDefaults setObject:passc forKey:@"dcapiPwd"];
            [currentDefaults synchronize];
        }
    }
    @catch (NSException *exception) {
        DCAPIException *ex = [[DCAPIException alloc] initWithName:ERROR_HEADER reason:exception.reason userInfo:nil];
        NSString *msg = exception.description;
        ex.code = [[NSString alloc] initWithFormat:@"%02d", INTERNAL_API_ERROR];
        ex.show = true;
        ex.message = msg;
        
        @throw (ex);
    }
}

/**
 * Recupera o segredo do usuário de forma segura usando K2.
 * @author Rodrigo Marques
 *
 * @return Retorna o segredo se os dados estivem corretos ou null c.c. ou haja comprometimento do cifrador de tempo.
 */
NSString* getSecret()
{
    NSString *timestamp = GetTimeST();
    
    NSUserDefaults *currentDefaults = [NSUserDefaults standardUserDefaults];
    
    NSString *sec = [currentDefaults objectForKey:@"dcapiSec"];
    
    @try {
        
        if( sec != nil)
        {
            int tokenval = [timestamp intValue];
            
            NSString *uniqueID = [UIDevice currentDevice].identifierForVendor.UUIDString;
            
            srand(tokenval);
            
            int rval = (int)(rand() / (float)RAND_MAX * 100000.0) + 100;
            
            NSString *rnd = [[NSString alloc] initWithFormat:@"%d", rval ];
            
            NSString *k2 = [[NSString alloc] initWithFormat:@"%@%@%@", [uniqueID substringWithRange:NSMakeRange(3, 3)], [timestamp substringWithRange:NSMakeRange(4,3)],[rnd substringWithRange:NSMakeRange(0, 2)]];
            
            NSData *cipher = [MF_Base32Codec dataFromBase32String:sec];
            
            NSData *plain = [cipher AES256DecryptWithKey:k2];
            
            sec = [[NSString alloc] initWithData:plain encoding:NSUTF8StringEncoding];
        }
    }
    @catch (NSException *exception) {
        DCAPIException *ex = [[DCAPIException alloc] initWithName:ERROR_HEADER reason:exception.reason userInfo:nil];
        NSString *msg = exception.description;
        ex.code = [[NSString alloc] initWithFormat:@"%02d", INTERNAL_API_ERROR];
        ex.show = true;
        ex.message = msg;
        
        @throw (ex);
    }
    
    return sec;
    
}

/**
 * Salva o segredo do usuário de forma segura usando K2.
 * @author Rodrigo Marques
 *
 * @param sec Segredo do usuário.
 * @return Sem Retorno.
 */
void setSecret(NSString* sec)
{
    NSString *timestamp = GetTimeST();
    
    @try {
        if( sec != nil)
        {
            int tokenval = [timestamp intValue];
            
            NSString *uniqueID = [UIDevice currentDevice].identifierForVendor.UUIDString;
            
            srand(tokenval);
            
            int rval = (int)(rand() / (float)RAND_MAX * 100000.0) + 100;
            
            NSString *rnd = [[NSString alloc] initWithFormat:@"%d", rval ];
            
            NSString *k2 = [[NSString alloc] initWithFormat:@"%@%@%@",[uniqueID substringWithRange:NSMakeRange(3, 3)], [timestamp substringWithRange:NSMakeRange(4,3)], [rnd substringWithRange:NSMakeRange(0, 2)]];
            
            NSData *plain = [sec dataUsingEncoding:NSUTF8StringEncoding];
            
            NSData *cipher = [plain AES256EncryptWithKey:k2];
            
            NSString *secc = [MF_Base32Codec base32StringFromData:cipher];
            
            NSUserDefaults *currentDefaults = [NSUserDefaults standardUserDefaults];
            
            [currentDefaults setObject:secc forKey:@"dcapiSec"];
            [currentDefaults synchronize];
        }
    }
    @catch (NSException *exception) {
        DCAPIException *ex = [[DCAPIException alloc] initWithName:ERROR_HEADER reason:exception.reason userInfo:nil];
        NSString *msg = exception.description;
        ex.code = [[NSString alloc] initWithFormat:@"%02d", INTERNAL_API_ERROR];
        ex.show = true;
        ex.message = msg;
        
        @throw (ex);
    }
}

/**
 * Recupera o id do usuário de forma segura usando K2.
 * @author Rodrigo Marques
 *
 * @return Retorna o id do aparelho se os dados estivem corretos ou null c.c.
 */
NSString* getGUID()
{
    NSUserDefaults *currentDefaults = [NSUserDefaults standardUserDefaults];
    
    NSString *sec = nil;
    
    @try {
        
        sec = [currentDefaults objectForKey:@"dcapiGuid"];
        
    }
    @catch (NSException *exception) {
        DCAPIException *ex = [[DCAPIException alloc] initWithName:ERROR_HEADER reason:exception.reason userInfo:nil];
        NSString *msg = exception.description;
        ex.code = [[NSString alloc] initWithFormat:@"%02d", INTERNAL_API_ERROR];
        ex.show = true;
        ex.message = msg;
        
        @throw (ex);
    }
    
    return sec;
    
}

 /**
 * Salva o id do usuário.
 * @author Rodrigo Marques
 *
 * @param sec Id do usuário.
 * @return Sem Retorno.
 */
void setGUID(NSString* sec)
{
    @try {
        if( sec != nil)
        {
            NSUserDefaults *currentDefaults = [NSUserDefaults standardUserDefaults];
            
            [currentDefaults setObject:sec forKey:@"dcapiGuid"];
            [currentDefaults synchronize];
        }
    }
    @catch (NSException *exception) {
        DCAPIException *ex = [[DCAPIException alloc] initWithName:ERROR_HEADER reason:exception.reason userInfo:nil];
        NSString *msg = exception.description;
        ex.code = [[NSString alloc] initWithFormat:@"%02d", INTERNAL_API_ERROR];
        ex.show = true;
        ex.message = msg;
        
        @throw (ex);
    }
}

/**
 * Recupera o id do aparelho de forma segura usando K2.
 * @author Rodrigo Marques
 *
 * @return Retorna o id do aparelho se os dados estivem corretos ou null c.c.
 */
NSString* getPhoneID()
{
    NSUserDefaults *currentDefaults = [NSUserDefaults standardUserDefaults];
    
    NSString *sec = nil;
    
    @try {
        
        sec = [currentDefaults objectForKey:@"dcapiPid"];
    }
    @catch (NSException *exception) {
        DCAPIException *ex = [[DCAPIException alloc] initWithName:ERROR_HEADER reason:exception.reason userInfo:nil];
        NSString *msg = exception.description;
        ex.code = [[NSString alloc] initWithFormat:@"%02d", INTERNAL_API_ERROR];
        ex.show = true;
        ex.message = msg;
        
        @throw (ex);
    }
    
    return sec;
    
}

/**
 * Salva o id do aparelho de forma segura usando K2.
 * @author Rodrigo Marques
 *
 * @param sec Id do aparelho.
 * @return Sem Retorno.
 */
void setPhoneID(NSString* sec)
{
    @try {
        if( sec != nil)
        {
            NSUserDefaults *currentDefaults = [NSUserDefaults standardUserDefaults];
            
            [currentDefaults setObject:sec forKey:@"dcapiPid"];
            [currentDefaults synchronize];
        }
    }
    @catch (NSException *exception) {
        DCAPIException *ex = [[DCAPIException alloc] initWithName:ERROR_HEADER reason:exception.reason userInfo:nil];
        NSString *msg = exception.description;
        ex.code = [[NSString alloc] initWithFormat:@"%02d", INTERNAL_API_ERROR];
        ex.show = true;
        ex.message = msg;
        
        @throw (ex);
    }
}

NSString *GenTimeST()
{
    NSString *uniqueID = [UIDevice currentDevice].identifierForVendor.UUIDString;
    NSString *sec = uniqueID;
    NSData* dataKey = [MF_Base32Codec dataFromBase32String:sec];
    
    TOTPGenerator *otpProvider = [[TOTPGenerator alloc] initWithSecret:dataKey algorithm:kOTPGeneratorSHA1Algorithm digits:8 period:30];
    
    NSDate *currentDate = [NSDate date];
    
    NSString* timestamp = [otpProvider generateOTPForDate:currentDate];
    
    return timestamp;
}

void SaveTimeST(NSString * timestamp)
{
    
    NSData *plain = [timestamp dataUsingEncoding:NSUTF8StringEncoding];
    
    NSData *cipher = [plain AES256EncryptWithKey:DCAPI_KEY];
    
    NSString *secc = [MF_Base32Codec base32StringFromData:cipher];
    
    NSUserDefaults *currentDefaults = [NSUserDefaults standardUserDefaults];
    
    [currentDefaults setObject:secc forKey:@"dcapiTsp"];
    [currentDefaults synchronize];

}

NSString *GetTimeST()
{
    NSUserDefaults *currentDefaults = [NSUserDefaults standardUserDefaults];
    
    NSString *timestamp = [currentDefaults objectForKey:@"dcapiTsp"];
    
    if(timestamp == nil)
    {
        timestamp = GenTimeST();
        
        SaveTimeST(timestamp);
        
        return timestamp;
    }
    
    NSData *cipher = [MF_Base32Codec dataFromBase32String:timestamp];
    
    NSData *plain = [cipher AES256DecryptWithKey:DCAPI_KEY];
    
    timestamp = [[NSString alloc] initWithData:plain encoding:NSUTF8StringEncoding];

    return timestamp;
}

@implementation DCAPID

+ (DCAPID*) getInstance
{
    if (sharedSingleton == NULL)
    {
        sharedSingleton = [[DCAPID alloc] init];
    }
    
    return sharedSingleton;
}

- (BOOL)isRegisteredPhone
{
    @try {
        NSString* sec = getSecret();
        
        return sec != nil;
    }
    @catch (NSException *exception) {
        return false;
    }
}

- (BOOL) unregisterPhone
{
    if( ![self isRegisteredPhone] )
        return false;
    
    @try {
        NSUserDefaults *currentDefaults = [NSUserDefaults standardUserDefaults];
        
        if( [currentDefaults objectForKey:@"dcapiPwd"] != nil )
            [currentDefaults removeObjectForKey:@"dcapiPwd"];
        
        if( [currentDefaults objectForKey:@"dcapiTsp"] != nil )
            [currentDefaults removeObjectForKey:@"dcapiTsp"];
        
        if( [currentDefaults objectForKey:@"dcapiSec"] != nil )
            [currentDefaults removeObjectForKey:@"dcapiSec"];
        
        if( [currentDefaults objectForKey:@"dcapiGuid"] != nil )
            [currentDefaults removeObjectForKey:@"dcapiGuid"];
        
        if( [currentDefaults objectForKey:@"dcapiPid"] != nil )
            [currentDefaults removeObjectForKey:@"dcapiPid"];
    }
    @catch (NSException *exception) {
        return false;
    }
    
    return true;
}

- (BOOL)isConnected
{
    if (internetReachable == nil)
    {
        return false;
    } else
    {
        return internetReachable.isReachable;
    }
}

- (void)setupWithAddress: (NSString*) serverAdress withTimeout: (int) comunicationTimeout
{
    __serverAdress = serverAdress;
    __comunicationTimeout = [[NSNumber alloc] initWithInt:comunicationTimeout];
    
    internetReachable = [Reachability reachabilityForInternetConnection];
    [internetReachable startNotifier];
    
    @try {
        
        if(![self isRegisteredPhone])
        {
            return;
        }
        
        NSString *pass = getPassword();
        
        NSString *sec = getSecret();
        
        NSString *timestamp = GenTimeST();
        
        SaveTimeST(timestamp);
        
        if( pass != nil )
        {
            setPassword(pass);
        }
        
        if( sec != nil )
        {
            setSecret(sec);
        }

    }
    @catch (NSException *exception) {
        
    }
    
}

- (BOOL)registerUserWithName: (NSString*) name withCPF: (NSString*) cpf withRG: (NSString*) rg withBirth: (NSDate*) birthDate withEmail: (NSString*) email
{
    @try {
        
        if((internetReachable != nil) && !internetReachable.isReachable)
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
        
        if((internetReachable != nil) && !internetReachable.isReachable)
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
        if((internetReachable != nil) && !internetReachable.isReachable)
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
        if((internetReachable != nil) && !internetReachable.isReachable)
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

- (NSString*) registerPhoneWithEmail: (NSString*) email withPassword: (NSString*) password withPhoneID: (NSString*) PhoneID withCard: (NSString*) cardNumber
{
    @try {
        
        if((internetReachable != nil) && !internetReachable.isReachable)
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
        
        if(password == nil )
        {
            password = @"00";
        }
        
        NSData *passd = [password dataUsingEncoding:NSUTF8StringEncoding];
        
        NSString * pass = [MF_Base32Codec base32StringFromData:passd];
        
        pass = [pass stringByReplacingOccurrencesOfString:@"=" withString:@""];
        
        args[ [ProtocolKeys PASSWORD] ] = pass;
        
        //args[ [ProtocolKeys PASSWORD] ] = password;
        
        args[ [ProtocolKeys IMEI] ] = PhoneID;
        
        NSString* cardTypeCode = @"";
        
        if( cardTypeCode == nil )
        {
           args[ [ProtocolKeys CARD_CODE] ] = @"";
        } else
        {
            args[ [ProtocolKeys CARD_CODE] ] = cardTypeCode;
        }
        
        if( cardNumber == nil )
        {
            args[ [ProtocolKeys CARD_NUMBER] ] = @"";
        } else
        {
            args[ [ProtocolKeys CARD_NUMBER] ] = cardNumber;
        }
        
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
            NSString* timestamp = GenTimeST();
            
            SaveTimeST(timestamp);
            
            setPassword(password);
            setSecret(resp[0][[ProtocolKeys SECRET]]);
            setGUID(resp[0][[ProtocolKeys GUID]]);
            setPhoneID(PhoneID);
            
            return resp[0][[ProtocolKeys CLIENT_NAME]];
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

- (NSMutableArray*) receiveCards
{
    NSMutableArray *arr = [[NSMutableArray alloc] init];
    
    @try {
        
        if((internetReachable != nil) && !internetReachable.isReachable)
        {
            DCAPIException *ex = [[DCAPIException alloc] initWithName:ERROR_HEADER reason:ERROR_NO_CONNECTION userInfo:nil];
            NSString *msg = ERROR_NO_CONNECTION;
            ex.code = [[NSString alloc] initWithFormat:@"%02d", SERVER_COMMUNICATION_ERROR];
            ex.show = true;
            ex.message = msg;
            
            @throw (ex);
        }
        
        if(![self isRegisteredPhone])
        {
            DCAPIException *ex = [[DCAPIException alloc] initWithName:ERROR_HEADER reason:ERROR_INTERNAL_DATA_MESSAGE userInfo:nil];
            NSString *msg = ERROR_INTERNAL_DATA_MESSAGE;
            ex.code = [[NSString alloc] initWithFormat:@"%02d", INTERNAL_DATA_ERROR];
            ex.show = true;
            ex.message = msg;
            
            @throw (ex);
        }
        
        NSString* secret = getSecret();
        NSString* PhoneID = getPhoneID();
        NSString* Password = getPassword();
        NSString* guid = getGUID();
        
        if( secret == nil || PhoneID == nil || Password == nil || guid == nil)
        {
            DCAPIException *ex = [[DCAPIException alloc] initWithName:ERROR_HEADER reason:ERROR_INTERNAL_DATA_MESSAGE userInfo:nil];
            NSString *msg = ERROR_INTERNAL_DATA_MESSAGE;
            ex.code = [[NSString alloc] initWithFormat:@"%02d", INTERNAL_DATA_ERROR];
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
        
        if(Password == nil )
        {
            Password = @"00";
        }
        
        NSData *passd = [Password dataUsingEncoding:NSUTF8StringEncoding];
        
        NSString * pass = [MF_Base32Codec base32StringFromData:passd];
        
        pass = [pass stringByReplacingOccurrencesOfString:@"=" withString:@""];
        
        args[ [ProtocolKeys PASSWORD] ] = pass;
        
        //args[ [ProtocolKeys PASSWORD] ] = Password;
        
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

- (BOOL) registerUserNotificationPushWithDeviceToken: (NSString*) deviceToken
{
   @try{
       
       if((internetReachable != nil) && !internetReachable.isReachable)
       {
           DCAPIException *ex = [[DCAPIException alloc] initWithName:ERROR_HEADER reason:ERROR_NO_CONNECTION userInfo:nil];
           NSString *msg = ERROR_NO_CONNECTION;
           ex.code = [[NSString alloc] initWithFormat:@"%02d", SERVER_COMMUNICATION_ERROR];
           ex.show = true;
           ex.message = msg;
           
           @throw (ex);
       }
       
       if(![self isRegisteredPhone])
       {
           DCAPIException *ex = [[DCAPIException alloc] initWithName:ERROR_HEADER reason:ERROR_INTERNAL_DATA_MESSAGE userInfo:nil];
           NSString *msg = ERROR_INTERNAL_DATA_MESSAGE;
           ex.code = [[NSString alloc] initWithFormat:@"%02d", INTERNAL_DATA_ERROR];
           ex.show = true;
           ex.message = msg;
           
           @throw (ex);
       }
       
       NSString* secret = getSecret();
       NSString* PhoneID = getPhoneID();
       NSString* GUID = getGUID();
       
       if( secret == nil || PhoneID == nil || GUID == nil)
       {
           DCAPIException *ex = [[DCAPIException alloc] initWithName:ERROR_HEADER reason:ERROR_INTERNAL_DATA_MESSAGE userInfo:nil];
           NSString *msg = ERROR_INTERNAL_DATA_MESSAGE;
           ex.code = [[NSString alloc] initWithFormat:@"%02d", INTERNAL_DATA_ERROR];
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

- (UIImage*) downloadImageBenefitWithBGUID: (NSString*) bguid
{
    UIImage * img = nil;
    
    @try {
        
        if((internetReachable != nil) && !internetReachable.isReachable)
        {
            DCAPIException *ex = [[DCAPIException alloc] initWithName:ERROR_HEADER reason:ERROR_NO_CONNECTION userInfo:nil];
            NSString *msg = ERROR_NO_CONNECTION;
            ex.code = [[NSString alloc] initWithFormat:@"%02d", SERVER_COMMUNICATION_ERROR];
            ex.show = true;
            ex.message = msg;
            
            @throw (ex);
        }
        
        if(![self isRegisteredPhone])
        {
            DCAPIException *ex = [[DCAPIException alloc] initWithName:ERROR_HEADER reason:ERROR_INTERNAL_DATA_MESSAGE userInfo:nil];
            NSString *msg = ERROR_INTERNAL_DATA_MESSAGE;
            ex.code = [[NSString alloc] initWithFormat:@"%02d", INTERNAL_DATA_ERROR];
            ex.show = true;
            ex.message = msg;
            
            @throw (ex);
        }
        
        NSString* secret = getSecret();
        NSString* PhoneID = getPhoneID();
        NSString* guid = getGUID();
        
        if( secret == nil || PhoneID == nil || guid == nil)
        {
            DCAPIException *ex = [[DCAPIException alloc] initWithName:ERROR_HEADER reason:ERROR_INTERNAL_DATA_MESSAGE userInfo:nil];
            NSString *msg = ERROR_INTERNAL_DATA_MESSAGE;
            ex.code = [[NSString alloc] initWithFormat:@"%02d", INTERNAL_DATA_ERROR];
            ex.show = true;
            ex.message = msg;
            
            @throw (ex);
        }
        
        NSString *sec = GetSecretFormat1(secret, PhoneID);
        NSData* dataKey = [MF_Base32Codec dataFromBase32String:sec];
        
        NSString *Token;
        
        TOTPGenerator *otpProvider = [[TOTPGenerator alloc] initWithSecret:dataKey algorithm:kOTPGeneratorSHA1Algorithm digits:6 period:30];
        
        NSDate *currentDate = [NSDate date];
        
        Token = [otpProvider generateOTPForDate:currentDate];
        
        NSMutableDictionary * args = [[NSMutableDictionary alloc] init];
        
        args[ [ProtocolKeys GUID] ] = guid;
        args[ [ProtocolKeys TOKEN] ] = Token;
        args[ [ProtocolKeys NOT_GUID] ] = bguid;
        
        NSData * resp = makeHTTPRequestData([[NSString alloc] initWithFormat:@"%@%@", __serverAdress, SERVLET_DOWNLOADBENEFITIMAGE], args, [__comunicationTimeout intValue]);
        
        if (resp == nil || [resp length] == 0)
        {
            DCAPIException *ex = [[DCAPIException alloc] initWithName:ERROR_HEADER reason:ERROR_INVALID_RESPONSE_MESSAGE userInfo:nil];
            ex.code = [[NSString alloc] initWithFormat:@"%02d", SERVER_REPONSE_ERROR];
            ex.show = false;
            ex.message = ex.reason;
            
            @throw (ex);

        }
        
        img = [UIImage imageWithData:resp];
        
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
    
    return img;
}

- (NSMutableArray*) receiveBenefits;
{
    NSMutableArray *arr = [[NSMutableArray alloc] init];
    
    @try {
        
        if((internetReachable != nil) && !internetReachable.isReachable)
        {
            DCAPIException *ex = [[DCAPIException alloc] initWithName:ERROR_HEADER reason:ERROR_NO_CONNECTION userInfo:nil];
            NSString *msg = ERROR_NO_CONNECTION;
            ex.code = [[NSString alloc] initWithFormat:@"%02d", SERVER_COMMUNICATION_ERROR];
            ex.show = true;
            ex.message = msg;
            
            @throw (ex);
        }
        
        if(![self isRegisteredPhone])
        {
            DCAPIException *ex = [[DCAPIException alloc] initWithName:ERROR_HEADER reason:ERROR_INTERNAL_DATA_MESSAGE userInfo:nil];
            NSString *msg = ERROR_INTERNAL_DATA_MESSAGE;
            ex.code = [[NSString alloc] initWithFormat:@"%02d", INTERNAL_DATA_ERROR];
            ex.show = true;
            ex.message = msg;
            
            @throw (ex);
        }
        
        NSString* secret = getSecret();
        NSString* PhoneID = getPhoneID();
        NSString* guid = getGUID();
        
        if( secret == nil || PhoneID == nil || guid == nil)
        {
            DCAPIException *ex = [[DCAPIException alloc] initWithName:ERROR_HEADER reason:ERROR_INTERNAL_DATA_MESSAGE userInfo:nil];
            NSString *msg = ERROR_INTERNAL_DATA_MESSAGE;
            ex.code = [[NSString alloc] initWithFormat:@"%02d", INTERNAL_DATA_ERROR];
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
            [protokeys addObject:[ProtocolKeys NOT_GUID]];
            
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
                note.bguid = dic[[ProtocolKeys NOT_GUID]];
                
                NSString *dateStr = dic[[ProtocolKeys NOT_TIMESTAMP]];
                
                NSDateFormatter *dateFormat = [[NSDateFormatter alloc] init];
                
                [dateFormat setDateFormat:@"dd/MM/yyyy HH:mm:ss"];
                
                NSDate *date = [dateFormat dateFromString:dateStr];
                
                note.UTCTimeStamp = date;
                
                if( [dic objectForKey:[ProtocolKeys NOT_IMAGE]] != nil )
                {
                    @try {
                        
                        NSMutableString *image64 = [[NSMutableString alloc] initWithString:dic[[ProtocolKeys NOT_IMAGE]]];
                        
                        [image64 replaceOccurrencesOfString:@"-" withString:@"+" options:NSCaseInsensitiveSearch range:NSMakeRange(0, [image64 length])];
                        
                        [image64 replaceOccurrencesOfString:@"_" withString:@"/" options:NSCaseInsensitiveSearch range:NSMakeRange(0, [image64 length])];
                        
                        NSData *data = nil;
                        
                        for(int j = 0; j < 6; j++)
                        {
                            data = [[NSData alloc] initWithBase64EncodedString:image64 options:NSDataBase64DecodingIgnoreUnknownCharacters];
                            
                            if(data != nil)
                            {
                                break;
                            }
                            
                            [image64 appendString:@"="];
                        }
                        
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

- (NSMutableArray*) receiveTransactionsWithCNT: (int) cnt withLastGUID: (NSString*) lastGuid;
{
    NSMutableArray *arr = [[NSMutableArray alloc] init];
    
    @try {
        
        if((internetReachable != nil) && !internetReachable.isReachable)
        {
            DCAPIException *ex = [[DCAPIException alloc] initWithName:ERROR_HEADER reason:ERROR_NO_CONNECTION userInfo:nil];
            NSString *msg = ERROR_NO_CONNECTION;
            ex.code = [[NSString alloc] initWithFormat:@"%02d", SERVER_COMMUNICATION_ERROR];
            ex.show = true;
            ex.message = msg;
            
            @throw (ex);
        }
        
        if(![self isRegisteredPhone])
        {
            DCAPIException *ex = [[DCAPIException alloc] initWithName:ERROR_HEADER reason:ERROR_INTERNAL_DATA_MESSAGE userInfo:nil];
            NSString *msg = ERROR_INTERNAL_DATA_MESSAGE;
            ex.code = [[NSString alloc] initWithFormat:@"%02d", INTERNAL_DATA_ERROR];
            ex.show = true;
            ex.message = msg;
            
            @throw (ex);
        }
        
        NSString* secret = getSecret();
        NSString* PhoneID = getPhoneID();
        NSString* guid = getGUID();
        
        if( secret == nil || PhoneID == nil || guid == nil)
        {
            DCAPIException *ex = [[DCAPIException alloc] initWithName:ERROR_HEADER reason:ERROR_INTERNAL_DATA_MESSAGE userInfo:nil];
            NSString *msg = ERROR_INTERNAL_DATA_MESSAGE;
            ex.code = [[NSString alloc] initWithFormat:@"%02d", INTERNAL_DATA_ERROR];
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
                
                //////////////
                
                NSMutableString *mes = [[NSMutableString alloc] initWithString:dic[[ProtocolKeys TRANS_EVALUATION_MSG]]];
                
                NSData * dta = nil;
                
                if(mes != nil)
                {
                    for (int k = 0; k < 7; k++)
                    {
                        dta = [MF_Base32Codec dataFromBase32String:mes];
                        
                        if(dta != nil)
                        {
                            break;
                        }
                        
                        [mes appendString:@"="];
                        
                        break;
                        
                    }
                    
                    if(dta != nil)
                    {
                        mes = [[NSMutableString alloc] initWithData:dta encoding:NSUTF8StringEncoding];
                    } else
                    {
                        mes = nil;
                    }
                }
                
                trans.evaluationMessage = mes;
                
                ///////////////////////////
                
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


- (BOOL) sendEvaluationWithTransGuid: (NSString*) transactionGuid withRate: (int) rate withMessage: (NSString*) message
{
   @try {
       
       if((internetReachable != nil) && !internetReachable.isReachable)
       {
           DCAPIException *ex = [[DCAPIException alloc] initWithName:ERROR_HEADER reason:ERROR_NO_CONNECTION userInfo:nil];
           NSString *msg = ERROR_NO_CONNECTION;
           ex.code = [[NSString alloc] initWithFormat:@"%02d", SERVER_COMMUNICATION_ERROR];
           ex.show = true;
           ex.message = msg;
           
           @throw (ex);
       }
       
       if(![self isRegisteredPhone])
       {
           DCAPIException *ex = [[DCAPIException alloc] initWithName:ERROR_HEADER reason:ERROR_INTERNAL_DATA_MESSAGE userInfo:nil];
           NSString *msg = ERROR_INTERNAL_DATA_MESSAGE;
           ex.code = [[NSString alloc] initWithFormat:@"%02d", INTERNAL_DATA_ERROR];
           ex.show = true;
           ex.message = msg;
           
           @throw (ex);
       }
       
       NSString* secretKey = getSecret();
       NSString* PhoneID = getPhoneID();
       NSString* guid = getGUID();
       
       if( secretKey == nil || PhoneID == nil || guid == nil)
       {
           DCAPIException *ex = [[DCAPIException alloc] initWithName:ERROR_HEADER reason:ERROR_INTERNAL_DATA_MESSAGE userInfo:nil];
           NSString *msg = ERROR_INTERNAL_DATA_MESSAGE;
           ex.code = [[NSString alloc] initWithFormat:@"%02d", INTERNAL_DATA_ERROR];
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
       
        if((rate > 5) || (rate < 1))
        {
            DCAPIException *ex = [[DCAPIException alloc] initWithName:ERROR_HEADER reason:ERROR_PARAMETER_MESSAGE userInfo:nil];
            NSString *msg = ERROR_PARAMETER_MESSAGE;
            ex.code = [[NSString alloc] initWithFormat:@"%02d", PARAMETER_ERROR];
            ex.show = true;
            ex.message = msg;
            
            @throw (ex);
        }
       
        args[ [ProtocolKeys TRANS_GUID] ] = transactionGuid;
        args[ [ProtocolKeys TRANS_EVALUATION] ] = [[NSString alloc] initWithFormat:@"%d", rate];
       
       /////////////////////
        NSData *msgd = [message dataUsingEncoding:NSUTF8StringEncoding];
       
        NSString * msg = [MF_Base32Codec base32StringFromData:msgd];
       
        msg = [msg stringByReplacingOccurrencesOfString:@"=" withString:@""];
       //////////////////////
       
        args[ [ProtocolKeys TRANS_EVALUATION_MSG] ] = msg;
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

- (QRCodeResp*) createQRCodeWithLatitute: (float) latitute withLongitute: (float) longitude withCard: (NSString*) cardNumber withCardType: (NSString*) cardTypeCode withWith: (int) width withHeight: (int) height
{
    if(![self isRegisteredPhone])
    {
        DCAPIException *ex = [[DCAPIException alloc] initWithName:ERROR_HEADER reason:ERROR_INTERNAL_DATA_MESSAGE userInfo:nil];
        NSString *msg = ERROR_INTERNAL_DATA_MESSAGE;
        ex.code = [[NSString alloc] initWithFormat:@"%02d", INTERNAL_DATA_ERROR];
        ex.show = true;
        ex.message = msg;
        
        @throw (ex);
    }
    
    NSString* secretKey = getSecret();
    NSString* PhoneID = getPhoneID();
    NSString* guid = getGUID();
    
    if( secretKey == nil || PhoneID == nil || guid == nil)
    {
        DCAPIException *ex = [[DCAPIException alloc] initWithName:ERROR_HEADER reason:ERROR_INTERNAL_DATA_MESSAGE userInfo:nil];
        NSString *msg = ERROR_INTERNAL_DATA_MESSAGE;
        ex.code = [[NSString alloc] initWithFormat:@"%02d", INTERNAL_DATA_ERROR];
        ex.show = true;
        ex.message = msg;
        
        @throw (ex);
    }
    
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
    resp.timeout = timeout % 30 + 1;
    resp.interval = 30;
    
    return resp;
}

- (TokenResp*) createTokenWithCard: (NSString*) cardNumber
{
    if(![self isRegisteredPhone])
    {
        DCAPIException *ex = [[DCAPIException alloc] initWithName:ERROR_HEADER reason:ERROR_INTERNAL_DATA_MESSAGE userInfo:nil];
        NSString *msg = ERROR_INTERNAL_DATA_MESSAGE;
        ex.code = [[NSString alloc] initWithFormat:@"%02d", INTERNAL_DATA_ERROR];
        ex.show = true;
        ex.message = msg;
        
        @throw (ex);
    }
    
    NSString* secretKey = getSecret();
    NSString* PhoneID = getPhoneID();
    NSString* guid = getGUID();
    
    if( secretKey == nil || PhoneID == nil || guid == nil)
    {
        DCAPIException *ex = [[DCAPIException alloc] initWithName:ERROR_HEADER reason:ERROR_INTERNAL_DATA_MESSAGE userInfo:nil];
        NSString *msg = ERROR_INTERNAL_DATA_MESSAGE;
        ex.code = [[NSString alloc] initWithFormat:@"%02d", INTERNAL_DATA_ERROR];
        ex.show = true;
        ex.message = msg;
        
        @throw (ex);
    }
    
    NSString *sec = GetSecretFormat2(secretKey, PhoneID, cardNumber);
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
    resp.timeout = timeout % 30 + 1;
    
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

NSData* makeHTTPRequestData(NSString* ServletAddress, NSMutableDictionary* args, int comunicationTimeout)
{
    
    NSData* data = nil;
    
    NSMutableURLRequest *request = [[NSMutableURLRequest alloc] initWithURL:[NSURL URLWithString:ServletAddress] cachePolicy:NSURLRequestReloadIgnoringLocalAndRemoteCacheData timeoutInterval:comunicationTimeout];
    
    [request setHTTPMethod:@"POST"];
    
    NSMutableString *dataString = [[NSMutableString alloc] init];
    
    for (id key in args) {
        id value = [args objectForKey:key];
        [dataString appendFormat:@"%@=%@&", (NSString*)key, (NSString*)value];
    }
    
    [request setValue:[NSString stringWithFormat:@"%lu", (unsigned long)[dataString length]] forHTTPHeaderField:@"Content-length"];
    
    [request setHTTPBody:[dataString dataUsingEncoding:NSUTF8StringEncoding]];
    
    /*[NSURLRequest setAllowsAnyHTTPSCertificate:YES forHost:@"andedcserver.cloudapp.net"];
    */
    NSURLResponse* response = nil;
    
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
    
    if(data == nil || ([data length] == 0))
    {
        if(requestError != nil)
        {
            if([requestError code] == NSURLErrorNotConnectedToInternet)
            {
                DCAPIException *ex = [[DCAPIException alloc] initWithName:ERROR_HEADER reason:ERROR_NO_CONNECTION userInfo:nil];
                ex.code = [[NSString alloc] initWithFormat:@"%d", SERVER_COMMUNICATION_ERROR];
                ex.message = ex.reason;
                ex.show = true;
                @throw (ex);
            } else if([requestError code] == NSURLErrorTimedOut )
            {
                DCAPIException *ex = [[DCAPIException alloc] initWithName:ERROR_HEADER reason:ERROR_CONNECTION_TIMEOUT userInfo:nil];
                ex.code = [[NSString alloc] initWithFormat:@"%d", SERVER_COMMUNICATION_ERROR];
                ex.message = ex.reason;
                ex.show = true;
                @throw (ex);
            } else
            {
                //DCAPIException *ex = [[DCAPIException alloc] initWithName:[requestError localizedDescription] reason:[requestError localizedFailureReason] userInfo:nil];
                DCAPIException *ex = [[DCAPIException alloc] initWithName:ERROR_HEADER reason:[requestError localizedFailureReason] userInfo:nil];
                ex.code = [[NSString alloc] initWithFormat:@"%d", SERVER_COMMUNICATION_ERROR];
                ex.message = ERROR_CONNECTION_ERROR;
                ex.show = true;
                @throw (ex);
            }
            
        } else
        {
            DCAPIException *ex = [[DCAPIException alloc] initWithName:ERROR_HEADER reason:ERROR_INTERNAL_MESSAGE userInfo:nil];
            ex.code = [[NSString alloc] initWithFormat:@"%d", INTERNAL_API_ERROR];
            ex.message = ex.reason;
            ex.show = false;
            @throw (ex);
        }
    }
    
    return data;
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
    
    /*[NSURLRequest setAllowsAnyHTTPSCertificate:YES forHost:@"andedcserver.cloudapp.net"];
    */
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
            if([requestError code] == NSURLErrorNotConnectedToInternet)
            {
                DCAPIException *ex = [[DCAPIException alloc] initWithName:ERROR_HEADER reason:ERROR_NO_CONNECTION userInfo:nil];
                ex.code = [[NSString alloc] initWithFormat:@"%d", SERVER_COMMUNICATION_ERROR];
                ex.message = ex.reason;
                ex.show = true;
                @throw (ex);
            } else if([requestError code] == NSURLErrorTimedOut )
            {
                DCAPIException *ex = [[DCAPIException alloc] initWithName:ERROR_HEADER reason:ERROR_CONNECTION_TIMEOUT userInfo:nil];
                ex.code = [[NSString alloc] initWithFormat:@"%d", SERVER_COMMUNICATION_ERROR];
                ex.message = ex.reason;
                ex.show = true;
                @throw (ex);
            } else
            {
                //DCAPIException *ex = [[DCAPIException alloc] initWithName:[requestError localizedDescription] reason:[requestError localizedFailureReason] userInfo:nil];
                DCAPIException *ex = [[DCAPIException alloc] initWithName:ERROR_HEADER reason:[requestError localizedFailureReason] userInfo:nil];
                ex.code = [[NSString alloc] initWithFormat:@"%d", SERVER_COMMUNICATION_ERROR];
                ex.message = ERROR_CONNECTION_ERROR;
                ex.show = true;
                @throw (ex);
            }
            
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

