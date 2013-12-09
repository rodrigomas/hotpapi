//
//  DCAPIException.h
//  DCAPI
//
//  Created by Rodrigo Marques on 11/10/13.
//  Copyright (c) 2013 Ande Tecnologia. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface DCAPIException : NSException

@property NSString *message;

@property NSString *code;

@property BOOL show;

@end
