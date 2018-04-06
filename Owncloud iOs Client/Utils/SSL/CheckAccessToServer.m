//
//  CheckAccessToServer.m
//  Owncloud iOs Client
//
//  Created by Javier Gonzalez on 8/21/12.
//

/*
 Copyright (C) 2016, ownCloud GmbH.
 This code is covered by the GNU Public License Version 3.
 For distribution utilizing Apple mechanisms please see https://owncloud.org/contribute/iOS-license-exception/
 You should have received a copy of this license
 along with this program. If not, see <http://www.gnu.org/licenses/gpl-3.0.en.html>.
 */

#import "CheckAccessToServer.h"
#import <netinet/in.h>
#import <CFNetwork/CFNetwork.h>
#import <SystemConfiguration/SystemConfiguration.h>
#import "OCFrameworkConstants.h"
#import "UtilsUrls.h"

#import <openssl/x509.h>
#import <openssl/bio.h>
#import <openssl/err.h>
#include <openssl/pem.h>
#import "ManageAppSettingsDB.h"
#import "UtilsDtos.h"
#import "Customization.h"
#import "ManageUsersDB.h"
#import "UtilsFramework.h"
#import "OCCommunication.h"

#ifdef CONTAINER_APP
#import "AppDelegate.h"
#endif

@implementation CheckAccessToServer


@synthesize delegate = _delegate;

//Singleton
+ (id)sharedManager {
    static CheckAccessToServer *sharedCheckAccessToServer = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        sharedCheckAccessToServer = [[self alloc] init];
        sharedCheckAccessToServer.sslStatus = sslStatusNotChecked;
        sharedCheckAccessToServer.sslCertificateManager = [[SSLCertificateManager alloc] init];
    });
    return sharedCheckAccessToServer;
}

-(void) isConnectionToTheServerByUrl:(NSString *) url {
    [self isConnectionToTheServerByUrl:url withTimeout:k_timeout_webdav];
}

- (void)isConnectionToTheServerByUrl:(NSString *) url withTimeout:(NSInteger) timeout {
    
    //We save the url to later compare with urlServerRedirected in request
    self.urlUserToCheck = url;
    self.isSameCertificateSelfSigned = NO;
    
    self.urlStatusCheck = [NSString stringWithFormat:@"%@status.php", url];
    
    DLog(@"_isConnectionToTheServerByUrl_ URL Status: |%@|", self.urlStatusCheck);
    
    
    NSMutableURLRequest* request = [NSMutableURLRequest requestWithURL:[NSURL URLWithString:self.urlStatusCheck] cachePolicy:NSURLRequestReloadIgnoringCacheData timeoutInterval:timeout];
    //Add the user agent
    [request addValue:[UtilsUrls getUserAgent] forHTTPHeaderField:@"User-Agent"];
    [request setHTTPShouldHandleCookies:false];
    [request setValue:@"" forHTTPHeaderField:@"Authorization"];  // this is VERY IMPORTANT; for some reason, if not explicitly set,
                                                                 // when the request is used to build the NSURLSessionDataTask below
                                                                 // an authorization header will be added, reusing the last authorization header the app used;
                                                                 // that credential will survive even after uninstalling and reinstalling the app!!!
    
    //Configure connectionSession
    NSURLSessionConfiguration *configuration = [NSURLSessionConfiguration defaultSessionConfiguration];
    [configuration setHTTPShouldSetCookies:false];
    configuration.HTTPCookieAcceptPolicy = NSHTTPCookieAcceptPolicyNever;
    configuration.HTTPCookieStorage = nil;
    configuration.URLCredentialStorage = nil;   // enforce no credential is set to the request
    NSURLSession *session = [NSURLSession sessionWithConfiguration:configuration delegate:self delegateQueue:nil];
    
    
    NSURLSessionDataTask *task = [session dataTaskWithRequest:request
                                            completionHandler:
                                  ^(NSData *data, NSURLResponse *response, NSError *error) {
                                      
                                      NSInteger httpStatusCode = 0;
                                      if (response != nil) {
                                          NSHTTPURLResponse * httpResponse = (NSHTTPURLResponse *) response;
                                          httpStatusCode = [httpResponse statusCode];
                                      }
                                      
                                      if(error != nil) {
                                          DLog(@"Error: %@", error);
                                          DLog(@"Error: %ld - %@",(long)[error code] , [error localizedDescription]);
                                          
                                          
                                          if (error.code == kCFURLErrorServerCertificateUntrusted         ||
                                              error.code == kCFURLErrorServerCertificateHasBadDate        ||
                                              error.code == kCFURLErrorServerCertificateHasUnknownRoot    ||
                                              error.code == kCFURLErrorServerCertificateNotYetValid)
                                          {
                                              if (![self.sslCertificateManager isCurrentCertificateTrusted]) {
                                                  [self askToAcceptCertificate];
                                              }
                                              
                                          } else {
                                              if(self.delegate) {
                                                  [self.delegate
                                                    connectionToTheServerWasChecked:NO
                                                    withHttpStatusCode:httpStatusCode
                                                    andError:error
                                                   ];
                                              }
                                          }
                                          
                                      } else {
                                      
                                          if ([[self.urlStatusCheck lowercaseString] hasPrefix:@"http:"]) {
                                              self.sslStatus = sslStatusSignedOrNotSSL;
                                          } else {
                                              if (self.isSameCertificateSelfSigned) {
                                                  self.sslStatus = sslStatusSelfSigned;
                                              } else {
                                                  self.sslStatus = sslStatusSignedOrNotSSL;
                                              }
                                          }
                                          
                                          BOOL installed = NO;
                                          BOOL maintenance = NO;
                                          NSError *e = nil;
                                          
                                          if (httpStatusCode == 200 && data!= nil) {
                                              NSMutableDictionary *jsonArray = [NSJSONSerialization JSONObjectWithData: data options: NSJSONReadingMutableContainers error: &e];
                                              DLog(@"data_check_server: %@",[[NSString alloc]initWithData:data encoding:NSUTF8StringEncoding]);
                                              if (!jsonArray) {
                                                  DLog(@"Error parsing JSON: %@", e);
                                                  
                                              } else {
                                                  installed = [[jsonArray valueForKey:@"installed"] boolValue];
                                                  maintenance = [[jsonArray valueForKey:@"maintenance"] boolValue];
                                                  if (maintenance) {
                                                      e = [UtilsFramework getErrorByCodeId:OCErrorServerMaintenanceMode];
                                                  }
                                              }
                                          }
                                          
                                          if(self.delegate) {
                                              [self.delegate connectionToTheServerWasChecked:(installed && !maintenance) withHttpStatusCode:httpStatusCode andError:e];
                                          }
                                          
                                      }
                                   
                                      [session finishTasksAndInvalidate];   // clean up!
                                  }];
    
    [task resume];
    
}


- (void) askToAcceptCertificate {

#ifdef CONTAINER_APP
    dispatch_async(dispatch_get_main_queue(), ^{
        //Your main thread code goes in here
        UIAlertView *alert = [[UIAlertView alloc] initWithTitle:@"" message:NSLocalizedString(@"invalid_ssl_cert", nil) delegate: self cancelButtonTitle:NSLocalizedString(@"no", nil) otherButtonTitles:NSLocalizedString(@"yes", nil), nil];
        [alert show];
        [alert release];
    });
    
#else
    
    UIAlertController *alert =   [UIAlertController
                                  alertControllerWithTitle:@""
                                  message:NSLocalizedString(@"invalid_ssl_cert", nil)
                                  preferredStyle:UIAlertControllerStyleAlert];
    UIAlertAction* no = [UIAlertAction
                         actionWithTitle:NSLocalizedString(@"no", nil)
                         style:UIAlertActionStyleDefault
                         handler:^(UIAlertAction * action)
                         {
                             
                         }];
    
    UIAlertAction* yes = [UIAlertAction
                          actionWithTitle:NSLocalizedString(@"yes", nil)
                          style:UIAlertActionStyleDefault
                          handler:^(UIAlertAction * action)
                          {
                              [self acceptCertificateAndRetryCheckToTheServer];
                          }];
    [alert addAction:no];
    [alert addAction:yes];
    
    [self.viewControllerToShow presentViewController:alert animated:YES completion:nil];
    
#endif
    
}

-(void) URLSession:(NSURLSession *)session didReceiveChallenge:(NSURLAuthenticationChallenge *)challenge completionHandler:(void (^)(NSURLSessionAuthChallengeDisposition, NSURLCredential * _Nullable))completionHandler{
    
    DLog(@"didReceiveChallenge");
  
    NSURLCredential *credential = nil;
    
    self.isSameCertificateSelfSigned = [self.sslCertificateManager isTrustedServerCertificateIn:challenge];
    if (self.isSameCertificateSelfSigned) {
        credential = [NSURLCredential credentialForTrust:challenge.protectionSpace.serverTrust];
        completionHandler(NSURLSessionAuthChallengeUseCredential,credential);
    } else {
        completionHandler(NSURLSessionAuthChallengePerformDefaultHandling, credential);
    }
}

/*
 * Network status
 */
- (BOOL)isNetworkIsReachable {
    
    struct sockaddr_in zeroAddress;
    bzero(&zeroAddress, sizeof(zeroAddress));
    zeroAddress.sin_len = sizeof(zeroAddress);
    zeroAddress.sin_family = AF_INET;
    
    SCNetworkReachabilityRef defaultRouteReachability = SCNetworkReachabilityCreateWithAddress(NULL, (struct sockaddr *)&zeroAddress);
    SCNetworkReachabilityFlags flags;
    BOOL gotFlags = SCNetworkReachabilityGetFlags(defaultRouteReachability, &flags);
    CFRelease(defaultRouteReachability);
    if (!gotFlags) {
        return NO;
    }
    BOOL isReachable = flags & kSCNetworkReachabilityFlagsReachable;
    
    BOOL noConnectionRequired = !(flags & kSCNetworkReachabilityFlagsConnectionRequired);
    if ((flags & kSCNetworkReachabilityFlagsIsWWAN)) {
        noConnectionRequired = YES;
    }
    
    return (isReachable && noConnectionRequired) ? YES : NO;
}

#pragma mark - UIAlertViewDelegate

- (void)alertView:(UIAlertView *)alertView clickedButtonAtIndex:(NSInteger)buttonIndex {
    
    if (buttonIndex == 1) {
        DLog(@"user pressed YES");
        [self acceptCertificateAndRetryCheckToTheServer];
    } else {
        DLog(@"user pressed CANCEL");
        [self.delegate badCertificateNotAcceptedByUser];
    }
}

- (void) acceptCertificateAndRetryCheckToTheServer {
    [self.sslCertificateManager trustCurrentCertificate];
    [self.delegate repeatTheCheckToTheServer];
}

- (void)URLSession:(NSURLSession *)session
              task:(NSURLSessionTask *)task
willPerformHTTPRedirection:(NSHTTPURLResponse *)redirectResponse
        newRequest:(NSURLRequest *)request
 completionHandler:(void (^)(NSURLRequest *))completionHandler{
    
    NSHTTPURLResponse *httpResponse = (NSHTTPURLResponse *) redirectResponse;
    
    NSDictionary *dict = [httpResponse allHeaderFields];
    //Server path of redirected server
    NSString *responseURLString = [dict objectForKey:@"Location"];
    
    if (responseURLString) {
        
        //We obtain the urlServerRedirected to make the uploads in background 
        NSURL *url = [[NSURL alloc] initWithString:responseURLString];
        NSURL * urlByRemovingLastComponent = [url URLByDeletingLastPathComponent];

        UserDto *activeUser = [ManageUsersDB getActiveUser];
        if (activeUser) {
            if ([activeUser.url isEqualToString:self.urlUserToCheck]) {
                [ManageUsersDB updateUrlRedirected:[urlByRemovingLastComponent absoluteString] byUserDto:activeUser];
            }
        }
        
#ifdef CONTAINER_APP
        AppDelegate *app = (AppDelegate *)[[UIApplication sharedApplication]delegate];
        app.urlServerRedirected = [urlByRemovingLastComponent absoluteString];
        app.activeUser = [ManageUsersDB getActiveUser];
#endif

        // reuse current request and set redirected URL into it to prevent undesired changes in request by the system, such as undesired authorization headers
        NSMutableURLRequest *requestRedirect = [task.currentRequest mutableCopy];
        [requestRedirect setURL: [NSURL URLWithString:responseURLString]];
        completionHandler(requestRedirect);
        
    } else {
        
        //We obtain the urlServerRedirected to make the uploads in background
#ifdef CONTAINER_APP
        AppDelegate *app = (AppDelegate *)[[UIApplication sharedApplication]delegate];
        app.urlServerRedirected = nil;
        app.activeUser = [ManageUsersDB getActiveUser];
#endif
        UserDto *activeUser = [ManageUsersDB getActiveUser];
        if (activeUser) {
            if ([activeUser.url isEqualToString:self.urlUserToCheck]) {
                [ManageUsersDB updateUrlRedirected:nil byUserDto:activeUser];
            }
        }
        
        completionHandler(request);
    }
}


- (NSInteger) getSslStatus {
    return self.sslStatus;
}

@end
