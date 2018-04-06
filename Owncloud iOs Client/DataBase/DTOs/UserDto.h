//
//  UserDto.h
//  Owncloud iOs Client
//
//  Created by Javier Gonzalez on 7/18/12.
//

/*
 Copyright (C) 2017, ownCloud GmbH.
 This code is covered by the GNU Public License Version 3.
 For distribution utilizing Apple mechanisms please see https://owncloud.org/contribute/iOS-license-exception/
 You should have received a copy of this license
 along with this program. If not, see <http://www.gnu.org/licenses/gpl-3.0.en.html>.
 */

#import "OCCapabilities.h"
#import "OCCredentialsDto.h"

typedef NS_ENUM(NSInteger, enumHasShareApiSupport) {
    serverFunctionalityNotChecked = 0,
    serverFunctionalitySupported = 1,
    serverFunctionalityNotSupported = 2
};

typedef NS_ENUM(NSInteger, enumSortingType) {
    sortByName = 0,
    sortByModificationDate = 1,
};

@interface UserDto : NSObject <NSCopying>

@property NSInteger userId;
@property (nonatomic, copy) NSString *url;
@property (nonatomic, copy) NSString *username;
@property (nonatomic, copy) OCCredentialsDto *credDto;

@property BOOL ssl;
@property BOOL activeaccount;
@property long storageOccupied;
@property long storage;
@property NSInteger hasShareApiSupport;
@property NSInteger hasShareeApiSupport;
@property NSInteger hasCookiesSupport;
@property NSInteger hasForbiddenCharactersSupport;
@property NSInteger hasCapabilitiesSupport;
@property NSInteger hasFedSharesOptionShareSupport;
@property NSInteger hasPublicShareLinkOptionNameSupport;
@property NSInteger hasPublicShareLinkOptionUploadOnlySupport;
@property BOOL imageInstantUpload;
@property BOOL videoInstantUpload;
@property BOOL backgroundInstantUpload;
@property (nonatomic, copy) NSString *pathInstantUpload;
@property BOOL onlyWifiInstantUpload;
@property NSTimeInterval timestampInstantUploadImage;
@property NSTimeInterval timestampInstantUploadVideo;
@property (nonatomic, copy) NSString *urlRedirected;
@property (nonatomic, strong) OCCapabilities *capabilitiesDto;
@property enumSortingType sortingType;
@property (nonatomic, copy) NSString *predefinedUrl;


- (void)encodeWithCoder:(NSCoder *)aCoder;
- (id)initWithCoder:(NSCoder *)aDecoder;

- (NSString *) nameToDisplay;


@end
