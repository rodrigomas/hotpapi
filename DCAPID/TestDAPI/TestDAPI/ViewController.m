//
//  ViewController.m
//  TestDAPI
//
//  Created by Rodrigo Marques on 11/11/13.
//  Copyright (c) 2013 Ande Tecnologia. All rights reserved.
//

#import "ViewController.h"
#import "DCAPID.h"
#import "UAirship.h"
#import <CoreLocation/CoreLocation.h>

@interface ViewController ()
{
    NSString *username;
   CLLocationManager *loc;
    float lat;
    float lng;
}
@end

@implementation ViewController

- (void) locationManager:(CLLocationManager*)manager didUpdateToLocation:(CLLocation *) newLocation fromLocation: (CLLocation*) oldLocation
{
    lat = newLocation.coordinate.latitude;
    lng = newLocation.coordinate.longitude;
}

//#define API_URL @"https://labs245.scopus.com.br/wallet/"
#define API_URL @"https://walletbsp.scopus.com.br/wallet/"
//#define API_URL @"http://andedcserver.cloudapp.net:8080/wallet/"

- (void)viewDidLoad
{
    [super viewDidLoad];
	// Do any additional setup after loading the view, typically from a nib.
    
    [[DCAPID getInstance] setupWithAddress:API_URL withTimeout:300000];
    
    loc = [[CLLocationManager alloc] init];
    
    loc.delegate = self;
    loc.desiredAccuracy = kCLLocationAccuracyBest;
    [loc startUpdatingLocation];
    
    lat = 12.0;
    lng = 10.0;
    
}
- (IBAction)testToken:(id)sender {
    
 //  [self testInternetConnection];
    
    NSString *uniqueID = [UIDevice currentDevice].identifierForVendor.UUIDString;
    
    TokenResp *tr = [[DCAPID getInstance] createTokenWithCard:@"123"];
    
    [_lbtext setText:tr.token];
    
//    QRCodeResp* resp = [[DCAPID getInstance] createQRCodeWithSecret:@"GEZDGNBVGY3TQOJQ" withGUID:@"123" withLatitute:12.2 withLongitute:14.5 withCard:@"123456789012" withPhoneID:uniqueID withCardType:@"01" withWith:200 withHeight:200];
    
    QRCodeResp* resp = [[DCAPID getInstance] createQRCodeWithLatitute:lat withLongitute:lng withCard:@"123456789012" withCardType:@"01" withWith:200 withHeight:200];
    
    UIImage* image = resp.image;
    
    [_imageView setImage:image];
    
    [_imageView layer].magnificationFilter = kCAFilterNearest;
}

- (NSDate *)dateWithYear:(NSInteger)year month:(NSInteger)month day:(NSInteger)day {
    NSCalendar *calendar = [[NSCalendar alloc] initWithCalendarIdentifier:NSGregorianCalendar];
    NSDateComponents *components = [[NSDateComponents alloc] init];
    [components setYear:year];
    [components setMonth:month];
    [components setDay:day];
    return [calendar dateFromComponents:components];
}

- (IBAction)tested:(id)sender {
    
    NSDate *dt = [self dateWithYear:1985 month:12 day:12];
    
    NSString *user = @"Rodrigo Marques da Silva";
    NSString *cpf =@"123123";
    NSString *rg = @"123123";
    NSString *email = @"rodrigomas@gmail.com";
    NSString *pass = @"28071985";
     
    
/*
    NSString *pass = @"123456";
    NSString *user = @"Homer Simpson";
    NSString *cpf =@"123456";
    NSString *rg = @"654321";
    NSString *email = @"homer@simpsons.com";
*/
    for(int ll = 0 ; ll < 100 ; ll++)
    {
        @try {
            
            
            NSString *uniqueID = [UIDevice currentDevice].identifierForVendor.UUIDString;
            
            BOOL val = [[DCAPID getInstance] isRegisteredPhone];
            
            NSLog(@"%d", val);
            
            val = [[DCAPID getInstance] unregisterPhone];
            NSLog(@"%d", val);
            
            val = [[DCAPID getInstance] isRegisteredPhone];
            NSLog(@"%d", val);
            
            /*[[DCAPID getInstance] registerUserWithName:user withCPF:cpf withRG:rg withBirth:dt withEmail:email];
             
             NSLog(@"%d", val);
             
             val = [[DCAPID getInstance] recoverPasswordWithName:user withCPF:cpf withBith:dt withEmail:email];
             
             NSLog(@"%d", val);
             
             val = [[DCAPID getInstance] changePasswordWithEmail:email withOldPassword:@"123456" withNewPassword:pass];
             
             NSLog(@"%d", val);
             */
            NSString* vv = @""; /*[[DCAPID getInstance] retrieveEmailWithName:user withCPF:cpf withBith:dt];
                                 
                                 NSLog(@"%@", vv);*/
            
            NSString *resp = [[DCAPID getInstance] registerPhoneWithEmail:email withPassword:pass withPhoneID:uniqueID withCard:@"1114"];
            
            NSLog(@"%@", resp);
            
            NSMutableArray *arr = [[DCAPID getInstance] receiveCards];
            
            NSLog(@"%lu", (unsigned long)[arr count]);
            
            NSLog(@"TESTE 1");
            for(int i = 0 ; i < 20 ; i++)
            {
                arr = [[DCAPID getInstance] receiveTransactionsWithCNT:20 withLastGUID:nil];
                
                for(int j = 0; j < [arr count] ; j++)
                {
                    if (i == 0 && j == 0) vv = ((Transaction*)arr[j]).transactionGUID;
                    
                    NSLog(@"%i - %@", j, ((Transaction*)arr[j]).transactionGUID);
                }
            }
            
            NSLog(@"TESTE 2");
            for(int i = 0 ; i < 20 ; i++)
            {
                arr = [[DCAPID getInstance] receiveTransactionsWithCNT:20 withLastGUID:vv];
                
                for(int j = 0; j < [arr count] ; j++)
                {
                    NSLog(@"%i - %@", j, ((Transaction*)arr[j]).transactionGUID);
                }
            }
            
            NSLog(@"TESTE 3");
            vv = nil;
            for(int i = 0 ; i < 20 ; i++)
            {
                arr = [[DCAPID getInstance] receiveTransactionsWithCNT:20 withLastGUID:vv];
                
                for(int j = 0 ; j < [arr count] ; j++)
                {
                    if (j == 0) vv = ((Transaction*)arr[j]).transactionGUID;
                    
                    NSLog(@"%i - %@", j, ((Transaction*)arr[j]).transactionGUID);
                }
            }
            
            
            NSLog(@"%lu", (unsigned long)[arr count]);
            
            arr = [[DCAPID getInstance] receiveTransactionsWithCNT:20 withLastGUID:nil];
            
            NSLog(@"%lu", (unsigned long)[arr count]);
            
            
            arr = [[DCAPID getInstance] receiveBenefits];
            
            if([arr count] > 0)
            {
                Notification *n = (Notification*)arr[0];
                
                if(n.image != nil)
                {
                    [_imageview2 setImage:n.image];
                }
                
                UIImage *img = [[DCAPID getInstance] downloadImageBenefitWithBGUID:n.bguid];
                
                [_imageview2 setImage:img];
            }
            
            NSLog(@"%lu", (unsigned long)[arr count]);
            
            val = [[DCAPID getInstance] registerUserNotificationPushWithDeviceToken:[[UAirship shared] deviceToken]];
            
            NSLog(@"%d", val);
            
            arr = [[DCAPID getInstance] receiveTransactionsWithCNT:10 withLastGUID:nil];
            
            NSLog(@"%lu", (unsigned long)[arr count]);
            
            int kx = 6;
            
            if( [arr count] > 0)
            {
                Transaction *t = (Transaction*)arr[kx];
                
                val = [[DCAPID getInstance] sendEvaluationWithTransGuid:t.transactionGUID withRate:2 withMessage:@"dddd"];
                
                NSLog(@"%d", val);
            } else
            {
                val = [[DCAPID getInstance] sendEvaluationWithTransGuid:@"1234" withRate:2 withMessage:@"dddd"];
                
                NSLog(@"%d", val);
                
            }
        }
        @catch (DCAPIException *exception) {
            
            if(exception.show)
             {
                 /*UIAlertView *message = [[UIAlertView alloc] initWithTitle:@"Error"
                                                                   message:exception.message
                                                                  delegate:nil
                                                         cancelButtonTitle:@"OK"
                                                         otherButtonTitles:nil];
                 [message show];*/
             }
            
        }
        @catch (NSException *exception) {
            
        }
        @finally {
            
        }
    }
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

@end
