//
//  AuthResponse.h
//  DCAPI
//
//  Created by Rodrigo Marques on 11/10/13.
//  Copyright (c) 2013 Ande Tecnologia. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface AuthResponse : NSObject

@property NSString *secretKey;

@property NSString *clientName;

@property NSString *GUID;

@end
