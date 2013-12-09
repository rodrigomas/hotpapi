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
   AuthResponse *respd;
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

- (void)viewDidLoad
{
    [super viewDidLoad];
	// Do any additional setup after loading the view, typically from a nib.
    
    [[DCAPID getInstance] setupWithAddress:@"http://andedcserver.cloudapp.net:8080/DigitalCards-Scopus/" withTimeout:300000];
    
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
    
    TokenResp *tr = [[DCAPID getInstance] createTokenWithSecret:respd.secretKey withPhoneID:uniqueID withCard:@"123"];
    
    [_lbtext setText:tr.token];
    
//    QRCodeResp* resp = [[DCAPID getInstance] createQRCodeWithSecret:@"GEZDGNBVGY3TQOJQ" withGUID:@"123" withLatitute:12.2 withLongitute:14.5 withCard:@"123456789012" withPhoneID:uniqueID withCardType:@"01" withWith:200 withHeight:200];
    
    QRCodeResp* resp = [[DCAPID getInstance] createQRCodeWithSecret:respd.secretKey withGUID:@"123" withLatitute:lat withLongitute:lng withCard:@"123456789012"
                        withPhoneID:uniqueID withCardType:@"01" withWith:200 withHeight:200];
    
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
    
    NSDate *dt = [self dateWithYear:1986 month:11 day:11];
    
    NSString *user = @"Ana Marques da Silva";
    NSString *cpf =@"456456";
    NSString *rg = @"456456";
    NSString *email = @"ana@gmail.com";
    NSString *pass = @"123456";
     
     /*

    NSString *pass = @"123456";
    NSString *user = @"Homer Simpson";
    NSString *cpf =@"123456";
    NSString *rg = @"654321";
    NSString *email = @"homer@simpsons.com";
*/
    @try {
        NSString *uniqueID = [UIDevice currentDevice].identifierForVendor.UUIDString;
        
        BOOL val = [[DCAPID getInstance] registerUserWithName:user withCPF:cpf withRG:rg withBirth:dt withEmail:email];
        
        NSLog(@"%d", val);
        
        val = [[DCAPID getInstance] recoverPasswordWithName:user withCPF:cpf withBith:dt withEmail:email];
        
        NSLog(@"%d", val);
        
        val = [[DCAPID getInstance] changePasswordWithEmail:email withOldPassword:@"123456" withNewPassword:pass];
        
        NSLog(@"%d", val);
        
        NSString* vv = [[DCAPID getInstance] retrieveEmailWithName:user withCPF:cpf withBith:dt];
        
       NSLog(@"%@", vv);
        
        respd = [[DCAPID getInstance] registerPhoneWithEmail:email withPassword:pass withPhoneID:uniqueID withCard:@"1114" withCardType:@"01"];
        
        AuthResponse *r = respd;
        
        NSLog(@"%@", r.clientName);
        
        NSMutableArray *arr = [[DCAPID getInstance] receiveCardsWithSecret:r.secretKey withPhoneID:uniqueID withGUID:r.GUID withPassword:pass];
        
        NSLog(@"%lu", (unsigned long)[arr count]);
        
        arr = [[DCAPID getInstance] receiveBenefitsWithSecret:r.secretKey withPhoneID:uniqueID withGUID:r.GUID];
        
        NSLog(@"%lu", (unsigned long)[arr count]);
        
        val = [[DCAPID getInstance] registerUserNotificationPushWithSecret:r.secretKey withPhoneID:uniqueID withGUID:r.GUID withDeviceToken:[[UAirship shared] deviceToken]];
        
        NSLog(@"%d", val);
        
        arr = [[DCAPID getInstance] receiveTransactionsWithSecret:r.secretKey withPhoneID:uniqueID withGUID:r.GUID withCNT:10 withLastGUID:nil];
        
        NSLog(@"%lu", (unsigned long)[arr count]);
        
        if( [arr count] > 0)
        {
            Transaction *t = (Transaction*)arr[0];
            
            val = [[DCAPID getInstance] sendEvaluationWithTransGuid:t.transactionGUID withRate:2 withMessage:@"dddd" withPhoneID:uniqueID withGUID:r.GUID withKEY:r.secretKey];
            
            NSLog(@"%d", val);
        } else
        {
            val = [[DCAPID getInstance] sendEvaluationWithTransGuid:@"1234" withRate:2 withMessage:@"dddd" withPhoneID:uniqueID withGUID:r.GUID withKEY:r.secretKey];
            
            NSLog(@"%d", val);
            
        }
    }
    @catch (DCAPIException *exception) {
        
        if(exception.show)
        {
            UIAlertView *message = [[UIAlertView alloc] initWithTitle:@"Error"
                                                              message:exception.message
                                                             delegate:nil
                                                    cancelButtonTitle:@"OK"
                                                    otherButtonTitles:nil];
            [message show];
        }
    
    }
    @catch (NSException *exception) {
        
    }
    @finally {
        
    }
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

@end
