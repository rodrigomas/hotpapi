//
//  CardInfo.h
//  DCAPI
//
//  Created by Rodrigo Marques on 11/9/13.
//  Copyright (c) 2013 Ande Tecnologia. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface CardInfo : NSObject

@property NSString *clientName;

@property BOOL isDependent;

@property NSString *code;

@property NSString *description;

@property NSString *number;

@property NSString *title;

@property NSDate *expirationDate;

@property NSDate *issueDate;

@end
