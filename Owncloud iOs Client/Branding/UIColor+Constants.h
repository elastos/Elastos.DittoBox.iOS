//
//  UIColor+Constants.h
//  Owncloud iOs Client
//
//  Created by Gonzalo Gonzalez on 10/10/12.
//

/*
 Copyright (C) 2017, ownCloud GmbH.
 This code is covered by the GNU Public License Version 3.
 For distribution utilizing Apple mechanisms please see https://owncloud.org/contribute/iOS-license-exception/
 You should have received a copy of this license
 along with this program. If not, see <http://www.gnu.org/licenses/gpl-3.0.en.html>.
 */

#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>

@interface UIColor (Constants)

//NAVIGATION AND TOOL BAR

//Tint color of navigation bar
+ (UIColor*)colorOfNavigationBar;
//Color of background view in navigation bar, only for iOS 7 for transparency
+ (UIColor*)colorOfBackgroundNavBarImage;
//Color of letters in navigation bar
+ (UIColor*)colorOfNavigationTitle;
//Color of items in navigation bar
+ (UIColor*)colorOfNavigationItems;
//Tint color of tool bar
+ (UIColor*)colorOfToolBar;
//Color of background view in toolBar bar, only for iOS 7 for transparency
+ (UIColor*)colorOfBackgroundToolBarImage;
//Tint color of tool bar buttons
+ (UIColor*)colorOfToolBarButtons;


//TAB BAR

//Tint color of tab bar
+ (UIColor*)colorOfTintUITabBar;
//Tint color fo selected tab bar item
+ (UIColor*)colorOfTintSelectedUITabBar;
//Tint color for non selected tab bar item
+ (UIColor*)colorOfTintNonSelectedUITabBar;
    
//SETTINGS VIEW

//Text color in some cells of settings view
+ (UIColor*)colorOfDetailTextSettings;
//Cell background color in some cells of settings view
+(UIColor*)colorOfBackgroundButtonOnList;
//Text color in some cells of settings view
+(UIColor*)colorOfTextButtonOnList;

//LOGIN VIEW

//Background color of login view
+ (UIColor*)colorOfLoginBackground;
//Text color of url in login view
+ (UIColor*)colorOfURLUserPassword;
//Text color of login text, used in Help Guide texts
+ (UIColor*)colorOfLoginText ;
//Text color of error credentials
+ (UIColor*)colorOfLoginErrorText;
//Background color of top of login view, in logo image view
+ (UIColor*)colorOfLoginTopBackground;
//Background color of login button
+(UIColor *)colorOfLoginButtonBackground;
//Text color of the text of the login button
+(UIColor *)colorOfLoginButtonTextColor;


//FILE LIST

//Section index color, Color of the letter separators shown when there are more than 20 files.
+ (UIColor*)colorOfSectionIndexColorFileList;


//WEB VIEW

//Color of webview background
+ (UIColor*)colorOfWebViewBackground;


//DETAIL VIEW (iPAD)

//Color of background in detail view when there are not file selected
+ (UIColor*)colorOfBackgroundDetailViewiPad;


//SHARE VIEW Public Link, backgroung of cell to warning about sharing public link
+ (UIColor*)colorOfBackgroundWarningSharingPublicLink;

@end


