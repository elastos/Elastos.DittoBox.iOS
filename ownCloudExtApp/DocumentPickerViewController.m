//
//  DocumentPickerViewController.m
//  ownCloudExtApp
//
//  Created by Gonzalo Gonzalez on 14/10/14.
//

/*
 Copyright (C) 2016, ownCloud GmbH.
 This code is covered by the GNU Public License Version 3.
 For distribution utilizing Apple mechanisms please see https://owncloud.org/contribute/iOS-license-exception/
 You should have received a copy of this license
 along with this program. If not, see <http://www.gnu.org/licenses/gpl-3.0.en.html>.
 */

#import "DocumentPickerViewController.h"

#import "ManageUsersDB.h"
#import "ManageFilesDB.h"
#import "UserDto.h"
#import "UtilsUrls.h"
#import "FileListDocumentProviderViewController.h"
#import "OCNavigationController.h"
#import "OCCommunication.h"
#import "OCFrameworkConstants.h"
#import "OCURLSessionManager.h"
#import "CheckAccessToServer.h"
#import "OCKeychain.h"
#import "OCCredentialsDto.h"
#import "FileListDBOperations.h"
#import "ManageAppSettingsDB.h"
#import "KKPasscodeViewController.h"
#import "OCPortraitNavigationViewController.h"
#import "UtilsFramework.h"
#import "constants.h"
#import "ProvidingFileDto.h"
#import "ManageProvidingFilesDB.h"
#import "NSString+Encoding.h"
#import "InitializeDatabase.h"
#import "UploadsOfflineDto.h"
#import "ManageUploadsDB.h"
#import "UtilsDtos.h"
#import "ManageTouchID.h"
#import "OCOAuth2Configuration.h"
#import "Customization.h"

@interface DocumentPickerViewController ()

@end

@implementation DocumentPickerViewController

- (void) viewDidLoad {
    [super viewDidLoad];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(showOwnCloudNavigationOrShowErrorLogin) name:userHasChangeNotification object:nil];
}

- (void) viewWillDisappear:(BOOL)animated{
    [super viewWillDisappear:animated];
    [[NSNotificationCenter defaultCenter] postNotificationName: userHasCloseDocumentPicker object: nil];
    
}

- (void) closeDocumentPicker{
    [self dismissGrantingAccessToURL:nil];
}

-(void)prepareForPresentationInMode:(UIDocumentPickerMode)mode {
    // TODO: present a view controller appropriate for picker mode here
    
    [InitializeDatabase initDataBase];
    
    self.mode = mode;
    
    if ([ManageAppSettingsDB isPasscode]) {
        [self showPassCode];
        if([ManageAppSettingsDB isTouchID])
            [[ManageTouchID sharedSingleton] showTouchIDAuth];
    } else {
        [self showOwnCloudNavigationOrShowErrorLogin];
    }
}

- (void) showOwnCloudNavigationOrShowErrorLogin {
    
    self.user = [ManageUsersDB getActiveUser];
    
    if (self.user) {
        
        [UtilsFramework deleteAllCookies];
        
        FileDto *rootFolder = [ManageFilesDB getRootFileDtoByUser:self.user];
        
        if (!rootFolder) {
            rootFolder = [FileListDBOperations createRootFolderAndGetFileDtoByUser:self.user];
        }
        
        NSString *xibName = @"FileListDocumentProviderViewController";
        
        if (self.mode == UIDocumentPickerModeMoveToService || self.mode == UIDocumentPickerModeExportToService) {
            xibName = @"FileListDocumentProviderMoveViewController";
        }
        
        FileListDocumentProviderViewController *fileListTableViewController = [[FileListDocumentProviderViewController alloc] initWithNibName:xibName onFolder:rootFolder];
        fileListTableViewController.delegate = self;
        fileListTableViewController.mode = self.mode;
        
        OCNavigationController *navigationViewController = [[OCNavigationController alloc] initWithRootViewController:fileListTableViewController];
        
        if (IS_IPHONE && [ManageAppSettingsDB isPasscode] && self.view.frame.size.height < self.view.frame.size.width) {
            fileListTableViewController.isNecessaryAdjustThePositionAndTheSizeOfTheNavigationBar = YES;
        }

        [self presentViewController:navigationViewController animated:NO completion:^{
            //We check the connection here because we need to accept the certificate on the self signed server before go to the files tab
            ((CheckAccessToServer *)[CheckAccessToServer sharedManager]).viewControllerToShow = fileListTableViewController;
            ((CheckAccessToServer *)[CheckAccessToServer sharedManager]).delegate = fileListTableViewController;
            [[CheckAccessToServer sharedManager] isConnectionToTheServerByUrl:self.user.url];
        }];
        
    } else {
        //TODO: show the login view
        NSString *appName = [[NSBundle mainBundle] objectForInfoDictionaryKey:@"CFBundleDisplayName"];
        NSString *message = [NSLocalizedString(@"error_login_doc_provider", nil) stringByReplacingOccurrencesOfString:@"$appname" withString:appName];
        _labelErrorLogin.text = message;
        _labelErrorLogin.textAlignment = NSTextAlignmentCenter;
    }
}


#pragma mark - OCCommunications
+ (OCCommunication*)sharedOCCommunication
{
    static OCCommunication* sharedOCCommunication = nil;
    if (sharedOCCommunication == nil)
    {
        
        NSURLSessionConfiguration *configurationDownload = nil;
        configurationDownload = [NSURLSessionConfiguration backgroundSessionConfigurationWithIdentifier:k_download_session_name_ext_app];
        configurationDownload.sharedContainerIdentifier = [UtilsUrls getBundleOfSecurityGroup];
        
        configurationDownload.HTTPMaximumConnectionsPerHost = 1;
        configurationDownload.requestCachePolicy = NSURLRequestUseProtocolCachePolicy;
        configurationDownload.timeoutIntervalForRequest = k_timeout_upload;
        configurationDownload.sessionSendsLaunchEvents = YES;
        [configurationDownload setAllowsCellularAccess:YES];
        OCURLSessionManager *downloadSessionManager = [[OCURLSessionManager alloc] initWithSessionConfiguration:configurationDownload];
        [downloadSessionManager.operationQueue setMaxConcurrentOperationCount:1];
        [downloadSessionManager setSessionDidReceiveAuthenticationChallengeBlock:^NSURLSessionAuthChallengeDisposition (NSURLSession *session, NSURLAuthenticationChallenge *challenge, NSURLCredential * __autoreleasing *credential) {
            return NSURLSessionAuthChallengePerformDefaultHandling;
        }];
        
        NSURLSessionConfiguration *networkConfiguration = [NSURLSessionConfiguration defaultSessionConfiguration];
        networkConfiguration.HTTPShouldUsePipelining = YES;
        networkConfiguration.HTTPMaximumConnectionsPerHost = 1;
        networkConfiguration.requestCachePolicy = NSURLRequestReloadIgnoringLocalCacheData;
        
        OCURLSessionManager *networkSessionManager = [[OCURLSessionManager alloc] initWithSessionConfiguration:networkConfiguration];
        [networkSessionManager.operationQueue setMaxConcurrentOperationCount:1];
        networkSessionManager.responseSerializer = [AFHTTPResponseSerializer serializer];
        
        sharedOCCommunication = [[OCCommunication alloc] initWithUploadSessionManager:nil andDownloadSessionManager:downloadSessionManager andNetworkSessionManager:networkSessionManager];
        
        //Cookies is allways available in current supported Servers
        [sharedOCCommunication setIsCookiesAvailable:YES];
        
        OCOAuth2Configuration *ocOAuth2conf = [[OCOAuth2Configuration alloc]
                                               initWithClientId:k_oauth2_client_id
                                               clientSecret:k_oauth2_client_secret
                                               redirectUri:k_oauth2_redirect_uri
                                               authorizationEndpoint:k_oauth2_authorization_endpoint
                                               tokenEndpoint:k_oauth2_token_endpoint];
        
        [sharedOCCommunication setValueOauth2Configuration: ocOAuth2conf];
        
        [sharedOCCommunication setValueOfUserAgent:[UtilsUrls getUserAgent]];
        
        OCKeychain *oKeychain = [[OCKeychain alloc] init];
        [sharedOCCommunication setValueCredentialsStorage:oKeychain];
        
        SSLCertificateManager *sslCertificateManager = [[SSLCertificateManager alloc] init];
        [sharedOCCommunication setValueTrustedCertificatesStore:sslCertificateManager];

    }
    return sharedOCCommunication;
}


#pragma mark - FileListDocumentProviderViewControllerDelegate

- (void) openFile:(FileDto *)fileDto {
    
    NSURL *originUrl = [NSURL fileURLWithPath:fileDto.localFolder];
    NSString *folder = [NSString stringWithFormat: @"file_%@/", fileDto.etag];
    NSURL *destinationUrl = [self.documentStorageURL URLByAppendingPathComponent:folder];
    
    NSError *error = nil;
    
    if (![[NSFileManager defaultManager] fileExistsAtPath:destinationUrl.path]) {
        [[NSFileManager defaultManager] createDirectoryAtPath:destinationUrl.path withIntermediateDirectories:NO attributes:nil error:&error];
        DLog(@"Error: %@", [error localizedDescription]);
    }
    
    if (self.mode == UIDocumentPickerModeImport) {
        //Import mode return the name without encoding
        destinationUrl = [destinationUrl URLByAppendingPathComponent:[fileDto.fileName stringByRemovingPercentEncoding]] ;
    } else {
        destinationUrl = [destinationUrl URLByAppendingPathComponent:fileDto.fileName];
    }
    
    if ([[NSFileManager defaultManager] fileExistsAtPath:destinationUrl.path]) {
        if (![[NSFileManager defaultManager] removeItemAtURL:destinationUrl error:&error]) {
            NSLog(@"Error removing file: %@", error);
        }
    }
    
    if ([[NSFileManager defaultManager] fileExistsAtPath:fileDto.localFolder]) {
        if (![[NSFileManager defaultManager] copyItemAtURL:originUrl toURL:destinationUrl error:&error]) {
            NSLog(@"Error copyng file: %@", error);
        }
    }
    
    NSDictionary *attributes = nil;
    
    if (!error) {
        attributes = [[NSFileManager defaultManager] attributesOfItemAtPath:destinationUrl.path error:&error];
         NSLog(@"Error getting the artributtes of the file: %@", error);
    }
    
    
    //Some error in the process to send the file to the document picker.
   if (attributes && !error) {
       
       ProvidingFileDto *providingFile = [ManageProvidingFilesDB insertProvidingFileDtoWithPath:[UtilsUrls getRelativePathForDocumentProviderUsingAboslutePath:destinationUrl.path] byUserId:self.user.userId];
       [ManageFilesDB updateFile:fileDto.idFile withProvidingFile:providingFile.idProvidingFile];
       
       [self dismissGrantingAccessToURL:destinationUrl];
        
    }else{
        
        OCNavigationController *navigationController = (OCNavigationController*) self.presentedViewController;
        FileListDocumentProviderViewController *fileListController = (FileListDocumentProviderViewController*) [navigationController.viewControllers objectAtIndex:0];
        [fileListController showErrorMessage:NSLocalizedString(@"error_sending_file_to_document_picker", nil)];
    }
}


- (void) selectFolder:(FileDto*)fileDto{
    
    BOOL access = [self.originalURL startAccessingSecurityScopedResource];

    if (access) {
        
        DLog(@"URL : %@", self.originalURL.path);
        
        
        NSString *serverPath = [UtilsUrls getFilePathOnDBByFilePathOnFileDto:fileDto.filePath andUser:self.user];
        NSString *folder = [NSString stringWithFormat:@"%@%@", serverPath, fileDto.fileName];
       
        NSURL *destinationUrl = [self.documentStorageURL URLByAppendingPathComponent:folder];
        
        NSError *error = nil;
        
        //Create the destiny folder
        if (![[NSFileManager defaultManager] fileExistsAtPath:destinationUrl.path]) {
            [[NSFileManager defaultManager] createDirectoryAtPath:destinationUrl.path withIntermediateDirectories:YES attributes:nil error:&error];
        }
        
        //Add the file name provided to the final path
        destinationUrl = [destinationUrl URLByAppendingPathComponent:self.originalURL.lastPathComponent];
        
        
        if ([[NSFileManager defaultManager] fileExistsAtPath:destinationUrl.path]) {
            if (![[NSFileManager defaultManager] removeItemAtURL:destinationUrl error:&error]) {
                NSLog(@"Error removing file: %@", error);
            }
        }
        
        NSFileCoordinator *fileCoordinator = [NSFileCoordinator new];
        
        [fileCoordinator coordinateReadingItemAtURL:self.originalURL options: NSFileCoordinatorReadingForUploading error:&error byAccessor:^(NSURL *newURL) {
            
            if (error) {
               // NSLog(@"Error: %@", error.description);
               
            }else{
               
                 NSError *copyError = nil;
                [[NSFileManager defaultManager] copyItemAtURL:newURL toURL:destinationUrl error:&copyError];
                
                if (self.mode == UIDocumentPickerModeExportToService) {
                    
                    //Export mode
                    NSString *temp = [NSString stringWithFormat:@"%@%@", [UtilsUrls getTempFolderForUploadFiles], self.originalURL.lastPathComponent];
                    [[NSFileManager defaultManager] copyItemAtPath:newURL.path toPath:temp error:&copyError];
                    
                    NSDictionary *attributes = nil;
                    attributes = [[NSFileManager defaultManager] attributesOfItemAtPath:temp error:&copyError];
                    long long fileLength = [[attributes valueForKey:NSFileSize] unsignedLongLongValue];
                    
                    UserDto *user = [ManageUsersDB getActiveUser];
                    NSString *remotePath = [NSString stringWithFormat: @"%@%@", [UtilsUrls getFullRemoteServerPathWithWebDav:user],folder];
                    
                     NSString *checkPath = [NSString stringWithFormat:@"%@%@", remotePath, temp.lastPathComponent];
                    
                    if (![UtilsUrls isFileUploadingWithPath:remotePath andUser:user]) {
                        
                        UploadsOfflineDto *upload = [UploadsOfflineDto new];
                        
                        upload.originPath = temp;
                        upload.destinyFolder = remotePath;
                        upload.uploadFileName = temp.lastPathComponent;
                        upload.kindOfError = notAnError;
                        upload.estimateLength = (long)fileLength;
                        upload.userId = user.userId;
                        upload.isLastUploadFileOfThisArray = YES;
                        upload.status = generatedByDocumentProvider;
                        upload.chunksLength = k_lenght_chunk;
                        upload.isNotNecessaryCheckIfExist = NO;
                        upload.isInternalUpload = NO;
                        upload.taskIdentifier = 0;
                        
                        [ManageUploadsDB insertUpload:upload];
                        
                    }
                    
                }
            }
            
            [self.originalURL stopAccessingSecurityScopedResource];
            
            [self dismissGrantingAccessToURL:destinationUrl];

        }];
        
    }else{
         DLog(@"There are not access to the file by export/move mode");
    }

 
}


- (void) copyFileOnTheFileSystemByOrigin:(NSString *) origin andDestiny:(NSString *) destiny {
    
    NSFileManager *filemgr = [NSFileManager defaultManager];
    
    [filemgr removeItemAtPath:destiny error:nil];
    
    NSURL *oldPath = [NSURL fileURLWithPath:origin];
    NSURL *newPath= [NSURL fileURLWithPath:destiny];
    
    [filemgr copyItemAtURL:oldPath toURL:newPath error:nil];
    
}

#pragma mark - Pass Code

- (void)showPassCode {
    
    KKPasscodeViewController* vc = [[KKPasscodeViewController alloc] initWithNibName:nil bundle:nil];
    vc.delegate = self;
    
    OCNavigationController *oc = [[OCNavigationController alloc]initWithRootViewController:vc];
    vc.mode = KKPasscodeModeEnter;
    
    UIViewController *rootController = [[UIViewController alloc]init];
    rootController.view.backgroundColor = [UIColor darkGrayColor];
    
    [self presentViewController:oc animated:NO completion:^{
    }];
}

#pragma mark - KKPasscodeViewControllerDelegate

- (void)didPasscodeEnteredCorrectly:(KKPasscodeViewController*)viewController{
    DLog(@"Did pass code entered correctly");
    
    [self performSelector:@selector(showOwnCloudNavigationOrShowErrorLogin) withObject:nil afterDelay:0.1];
}

- (void)didPasscodeEnteredIncorrectly:(KKPasscodeViewController*)viewController{
    DLog(@"Did pass code entered incorrectly");

}

/*
- (NSURL *)documentStorageURL {
    
    NSString *path = [self.documentStorageURL path];
    path = [path stringByAppendingString:@"PEPE/"];
    
    if (![[NSFileManager defaultManager] fileExistsAtPath:path]) {
        NSError *error = nil;
        [[NSFileManager defaultManager] createDirectoryAtPath:path withIntermediateDirectories:NO attributes:nil error:&error];
        DLog(@"Error: %@", [error localizedDescription]);
    }
    
    return [NSURL fileURLWithPath:path];
}*/

@end
