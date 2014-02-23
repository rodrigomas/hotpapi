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

/**
 * Avalia conectividade do dispositivo.
 * @author Rodrigo Marques
 *
 * @return true caso haja conexão de internet válida e false caso contrário.
 */
- (BOOL)isConnected;

/**
 * Verifica se o telefone já está registrado pela API.
 * @author Rodrigo Marques
 *
 * @return true caso esteja e seja válido e false caso contrário.
 */
- (BOOL)isRegisteredPhone;

/**
 * Desvincula o usuário ao aparelho.
 * @author Rodrigo Marques
 *
 * @return true caso a operação seja bem sucedida e false caso contrário.
 */
- (BOOL) unregisterPhone;


/**
 * Configura o singleton com os paramtros básicos para transmissão
 * @author Rodrigo Marques
 *
 * @param serverAdress Endereço do serviço, no caso de HTTPS, deve possuir certificado válido.
 * @param comunicationTimeout Tempo máximo de espera na comunicação em segundos.
 * @return Sem Retorno.
 */
- (void)setupWithAddress: (NSString*) serverAdress withTimeout: (int) comunicationTimeout;

/**
 * Realiza o registro do usuário na Plataforma do Bradesco
 * @author Rodrigo Marques
 *
 * @param name Nome completo do usuário na plataforma bradesco.
 * @param cpf CPF do usuário.
 * @param rg RG do usuário.
 * @param birthDate Aniversário do usuário.
 * @param email Email que será vinculado.
 * @return true se a operação for completada e false caso contrário.
 */
- (BOOL)registerUserWithName: (NSString*) name withCPF: (NSString*) cpf withRG: (NSString*) rg withBirth: (NSDate*) birthDate withEmail: (NSString*) email;

/**
 * Recupera a senha do usuário na Plataforma do Bradesco
 * @author Rodrigo Marques
 *
 * @param name Nome completo do usuário na plataforma bradesco.
 * @param cpf CPF do usuário.
 * @param birthDate Aniversário do usuário.
 * @param email Email vinculado.
 * @return true se a operação for completada e false caso contrário.
 */
- (BOOL)recoverPasswordWithName: (NSString*) name withCPF: (NSString*) cpf withBith: (NSDate*) birthDate withEmail: (NSString*) email;

/**
 * Modifica a senha do usuário na Plataforma do Bradesco
 * @author Rodrigo Marques
 *
 * @param email Email vinculado.
 * @param oldPassword Senha antiga.
 * @param newPassword Nova Senha.
 * @return true se a operação for completada e false caso contrário.
 */
- (BOOL)changePasswordWithEmail: (NSString*) email withOldPassword: (NSString*) oldPassword withNewPassword: (NSString*) newPassword;

/**
 * Recupera o email do usuário na Plataforma do Bradesco
 * @author Rodrigo Marques
 *
 * @param name Nome completo do usuário na plataforma bradesco.
 * @param cpf CPF do usuário.
 * @param birthDate Aniversário do usuário.
 * @return O email vinculado na plataforma Bradesco ou null caso os dados estejam errados.
 */
- (NSString*)retrieveEmailWithName: (NSString*) name withCPF: (NSString*) cpf withBith: (NSDate*) birthDate;

/**
 * Realiza a vinculação do aparelho com o servidor de Cartões Digitais
 * @author Rodrigo Marques
 *
 * @param email Email que será vinculado, o mesmo da plataforma Bradesco.
 * @param password Senha da plataforma Bradesco (dado armazenado de forma segura).
 * @param PhoneID ID do aparelho.
 * @param cardNumber Numero de um dos cartões do usuário.
 * @return Retorna o nome do cliente caso seja bem sucedido, null caso contrário.
 */
- (NSString*)registerPhoneWithEmail: (NSString*) email withPassword: (NSString*) password withPhoneID: (NSString*) PhoneID withCard: (NSString*) cardNumber;

/**
 * Recebe os cartões do usuário vinculado ao aparelho.
 * @author Rodrigo Marques
 *
 * @return Lista de CardInfo. Caso bem sucedido possuirá os cartões, c.c. será uma lista vazia.
 */
- (NSMutableArray*) receiveCards;

/**
 * Realiza a vinculação do aparelho com o servidor de notificações.
 * @author Rodrigo Marques
 *
 * @param deviceToken Token gerado pelo Urban Airship.
 * @return Retorna true caso bem sucedido e false c.c.
 */
- (BOOL) registerUserNotificationPushWithDeviceToken: (NSString*) deviceToken;

/**
 * Recebe os benefícios do usuário vinculado ao aparelho.
 * @author Rodrigo Marques
 *
 * @return Lista de Notification. Caso bem sucedido possuirá os benefícios, c.c. será uma lista vazia.
 */
- (NSMutableArray*) receiveBenefits;

/**
 * Retorna a imagem de alta resolução associada ao benefício.
 * @author Rodrigo Marques
 *
 * @param bguid Id do benefício.
 * @return Retorna a imagem caso seja bem sucedido ou null c.c.
 */
- (UIImage*) downloadImageBenefitWithBGUID: (NSString*) bguid ;

/**
 * Recebe as cnt transações compreendidas após a transação de id = lastGuid
 * @author Rodrigo Marques
 *
 * @param cnt Quantidade de transações a serem recebidas.
 * @param lastGuid Id da última transação recebida (pode ser null para ser a última realizada).
 * @return Retorna uma lista de Transaction. O tamanho depende de cnt e da quantidade que exista no servidor.
 */
- (NSMutableArray*) receiveTransactionsWithCNT: (int) cnt withLastGUID: (NSString*) lastGuid;

/**
 * Realiza a avaliação de uma transação.
 * @author Rodrigo Marques
 *
 * @param transactionGuid Id da Transação.
 * @param withRate Nota da transação (1 a 5).
 * @param message Mensagem sobre a transação.
 * @return Retorna true caso seja bem sucedida e false c.c.
 */
- (BOOL) sendEvaluationWithTransGuid: (NSString*) transactionGuid withRate: (int) rate withMessage: (NSString*) message;

/**
 * Cria um token com QRCode associado.
 * @author Rodrigo Marques
 *
 * @param latitute Latitude do aparelho.
 * @param longitude Longitude do aparelho.
 * @param cardNumber Numero do cartão.
 * @param cardTypeCode Tipo do cartão.
 * @param width Largura do QRCode.
 * @param height Altura do QRCode.
 * @return Retorna um QRCodeResp caso seja bem sucedida e null c.c.
 */
- (QRCodeResp*) createQRCodeWithLatitute: (float) latitute withLongitute: (float) longitude withCard: (NSString*) cardNumber withCardType: (NSString*) cardTypeCode withWith: (int) width withHeight: (int) height;

/**
 * Cria um token com o cartão solicitado.
 * @author Rodrigo Marques
 *
 * @param cardNumber Número do cartão.
 * @return Retorna o token (TokenResp) caso seja bem sucedido ou null c.c.
 */
- (TokenResp*) createTokenWithCard: (NSString*) cardNumber;

/**
 * Retorna o singleton.
 * @author Rodrigo Marques
 *
 * @return Retorna e cria, caso necessário, o singleton.
 */
+ (DCAPID*) getInstance;

@end
