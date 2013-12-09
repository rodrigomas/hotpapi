//
//  Transaction.h
//  DCAPI
//
//  Created by Rodrigo Marques on 11/10/13.
//  Copyright (c) 2013 Ande Tecnologia. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface Transaction : NSObject

@property NSString *company;

@property NSString *location;

@property NSDate *UTCTimeStamp;

@property NSString *procedure;

@property int evaluation;

@property NSString *evaluationMessage;

@property NSString *transactionGUID;

@property NSString *cardNumber;

@property NSString *cardType;

@end
