//
//  UIColor+Constants.m
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

#import "UIColor+Constants.h"

@implementation UIColor(Constants)

//NAVIGATION AND TOOL BAR

//Tint color of navigation bar
+ (UIColor*)colorOfNavigationBar{
    return [UIColor colorWithRed:28/255.0f green:44/255.0f blue:67/255.0f alpha:1.0f];
}
//Color of background view in navigation bar
+ (UIColor*)colorOfBackgroundNavBarImage {
    return [UIColor colorWithRed:28/255.0f green:44/255.0f blue:67/255.0f alpha:0.7f];
}

//Color of letters in navigation bar
+ (UIColor*)colorOfNavigationTitle{
    return [UIColor colorWithRed:255/255.0f green:255/255.0f blue:255/255.0f alpha:1.0f];
}

//Color of items in navigation bar
+ (UIColor*)colorOfNavigationItems{
    return [UIColor colorWithRed:255/255.0f green:255/255.0f blue:255/255.0f alpha:1.0f];
}

//Tint color of tool bar
+ (UIColor*)colorOfToolBar{
    return [UIColor colorWithRed:28/255.0f green:44/255.0f blue:67/255.0f alpha:1.0f];
}

//Color of background view in toolBar bar, only for iOS 7 for transparency
+ (UIColor*)colorOfBackgroundToolBarImage {
    return [UIColor colorWithRed:28/255.0f green:44/255.0f blue:67/255.0f alpha:0.7];
}

//Tint color of tool bar items for detail preview of file view
+ (UIColor*)colorOfToolBarButtons {
    return [UIColor colorWithRed:255/255.0f green:255/255.0f blue:255/255.0f alpha:1.0f];

}


//TAB BAR

//Tint color of tab bar
+ (UIColor*)colorOfTintUITabBar {
    return [UIColor colorWithRed:28/255.0f green:44/255.0f blue:67/255.0f alpha:1.0f];
}

//Tint color for selected tab bar item
+ (UIColor*)colorOfTintSelectedUITabBar {
    return [UIColor colorWithRed:255/255.0f green:255/255.0f blue:255/255.0f alpha:1.0f];

}

//Tint color for non selected tab bar item (only works with the labels)
+ (UIColor*)colorOfTintNonSelectedUITabBar {
   return [UIColor colorWithRed:0/255.0f green:0/255.0f blue:0/255.0f alpha:1.0f];
}


//SETTINGS VIEW

//Text color in some cells of settings view
+ (UIColor*)colorOfDetailTextSettings {
    return [UIColor whiteColor];
}

//Cell background color in some cells of settings view
+(UIColor*)colorOfBackgroundButtonOnList {
    return [UIColor whiteColor];
}

//Text color in some cells of settings view
+(UIColor*)colorOfTextButtonOnList {
    return [UIColor blackColor];
}


//LOGIN VIEW

//Background color of login view
+ (UIColor*)colorOfLoginBackground{
    return [UIColor colorWithRed:255/255.0f green:255/255.0f blue:255/255.0f alpha:1.0f];
}

//Text color of url in login view
+ (UIColor*)colorOfURLUserPassword{
    return [UIColor colorWithWhite:0.0f alpha:0.7f];
}


//Text color of login text
+ (UIColor*)colorOfLoginText {
    return [UIColor colorWithRed:96/255.0f green:133/255.0f blue:154/255.0f alpha:1.0f];
}

//Text color of error credentials
+ (UIColor*)colorOfLoginErrorText{
    return [UIColor colorWithRed:96/255.0f green:133/255.0f blue:154/255.0f alpha:1.0f];
}

//Background color of top of login view, in logo image view
+ (UIColor*)colorOfLoginTopBackground {
    return [UIColor colorWithRed:255/255.0f green:255/255.0f blue:255/255.0f alpha:1.0f];
}

//Background color of login button
+(UIColor *)colorOfLoginButtonBackground{
    return [UIColor colorWithRed:30/255.0f green:44/255.0f blue:67/255.0f alpha:1.0f];
}

//Text color of the text of the login button
+(UIColor *)colorOfLoginButtonTextColor{
    return  [UIColor colorWithRed:255/255.0f green:255/255.0f blue:255/255.0f alpha:1.0f];
}


//FILE LIST

//Section index color, Color of the letter separators shown when there are more than 20 files.
+ (UIColor*)colorOfSectionIndexColorFileList {
    return [UIColor colorWithRed:28/255.0f green:44/255.0f blue:67/255.0f alpha:0.7f];
}


//WEB VIEW

//Color of webview background
+ (UIColor*)colorOfWebViewBackground{
   return [UIColor colorWithRed:26/255.0f green:26/255.0f blue:28/255.0f alpha:1.0f];
}

//Color of background in detail view when there are not file selected
+ (UIColor*)colorOfBackgroundDetailViewiPad{
    return [UIColor whiteColor];
}

+ (UIColor*)colorOfBackgroundWarningSharingPublicLink{
    return [UIColor colorWithRed:224/255.0f green:224/255.0f blue:224/255.0f alpha:1.0f];
}


@end
