//
//  ManageFilesDB.m
//  Owncloud iOs Client
//
//  Created by Javier Gonzalez on 6/21/13.
//

/*
 Copyright (C) 2016, ownCloud GmbH.
 This code is covered by the GNU Public License Version 3.
 For distribution utilizing Apple mechanisms please see https://owncloud.org/contribute/iOS-license-exception/
 You should have received a copy of this license
 along with this program. If not, see <http://www.gnu.org/licenses/gpl-3.0.en.html>.
 */

#import "ManageFilesDB.h"
#import "FMDatabaseQueue.h"
#import "FMDatabase.h"
#import "FileDto.h"
#import "UtilsUrls.h"
#import "OCSharedDto.h"
#import "ManageUsersDB.h"
#import "UserDto.h"
#import "ManageThumbnails.h"

#ifdef CONTAINER_APP
#import "AppDelegate.h"
#import "Owncloud_iOs_Client-Swift.h"
#elif FILE_PICKER
#import "ownCloudExtApp-Swift.h"
#elif SHARE_IN
#import "OC_Share_Sheet-Swift.h"
#else
#import "ownCloudExtAppFileProvider-Swift.h"
#endif

@implementation ManageFilesDB


+ (NSMutableArray *) getFilesByFileIdForActiveUser:(NSInteger) fileId {

    UserDto *mUser;
    
#ifdef CONTAINER_APP
    AppDelegate *app = (AppDelegate *)[[UIApplication sharedApplication] delegate];
    mUser = app.activeUser;
#else
    mUser = [ManageUsersDB getActiveUser];
#endif
    __block NSMutableArray *output = [NSMutableArray new];

    DLog(@"getFilesByFileId: %ld for active user %ld, %@",(long)fileId, mUser.userId, mUser.username);

    FMDatabaseQueue *queue = Managers.sharedDatabase;
    
    [queue inDatabase:^(FMDatabase *db) {
        FMResultSet *rs = [db executeQuery:@"SELECT * FROM files WHERE file_id = ? AND user_id = ? ORDER BY file_name ASC", [NSNumber numberWithInteger:fileId], [NSNumber numberWithInteger:mUser.userId]];
        while ([rs next]) {
            
            FileDto *currentFile = [[FileDto alloc] init];
            
            currentFile.idFile = [rs intForColumn:@"id"];
            currentFile.ocId = [rs stringForColumn:@"oc_id"];
            currentFile.filePath = [NSString stringWithFormat:@"%@%@",[UtilsUrls getRemovedPartOfFilePathAnd:mUser],[rs stringForColumn:@"file_path"]];
            currentFile.fileName = [rs stringForColumn:@"file_name"];
            currentFile.isDirectory = [rs intForColumn:@"is_directory"];
            currentFile.userId = [rs intForColumn:@"user_id"];
            currentFile.isDownload = [rs intForColumn:@"is_download"];
            currentFile.size = [rs longForColumn:@"size"];
            currentFile.fileId = [rs intForColumn:@"file_id"];
            currentFile.date = [rs longForColumn:@"date"];
            currentFile.etag = [rs stringForColumn:@"etag"];
            currentFile.isFavorite = [rs intForColumn:@"is_favorite"];
            currentFile.localFolder = [UtilsUrls getLocalFolderByFilePath:currentFile.filePath andFileName:currentFile.fileName andUserDto:mUser];
            currentFile.isNecessaryUpdate = [rs boolForColumn:@"is_necessary_update"];
            currentFile.sharedFileSource = [rs intForColumn:@"shared_file_source"];
            currentFile.permissions = [rs stringForColumn:@"permissions"];
            currentFile.taskIdentifier = [rs intForColumn:@"task_identifier"];
            currentFile.providingFileId = [rs intForColumn:@"providing_file_id"];
            
            [output addObject:currentFile];
        }
        [rs close];
    }];
    
    return output;
}


+ (NSMutableArray *) getFoldersByFileIdForActiveUser:(NSInteger) fileId {
    
    UserDto *mUser;
    
#ifdef CONTAINER_APP
    AppDelegate *app = (AppDelegate *)[[UIApplication sharedApplication] delegate];
    mUser = app.activeUser;
#else
    mUser = [ManageUsersDB getActiveUser];
#endif
    
    __block NSMutableArray *output = [NSMutableArray new];
    
    FMDatabaseQueue *queue = Managers.sharedDatabase;
    
    [queue inDatabase:^(FMDatabase *db) {

        FMResultSet *rs = [db executeQuery:@"SELECT * FROM files WHERE file_id = ? AND is_directory = 1 AND user_id = ? ORDER BY file_name ASC", [NSNumber numberWithInteger:fileId], [NSNumber numberWithInteger:mUser.userId]];

        while ([rs next]) {
            
            FileDto *currentFile = [[FileDto alloc] init];
            
            currentFile.idFile = [rs intForColumn:@"id"];
            currentFile.ocId = [rs stringForColumn:@"oc_id"];
            currentFile.filePath = [NSString stringWithFormat:@"%@%@",[UtilsUrls getRemovedPartOfFilePathAnd:mUser],[rs stringForColumn:@"file_path"]];
            currentFile.fileName = [rs stringForColumn:@"file_name"];
            currentFile.isDirectory = [rs intForColumn:@"is_directory"];
            currentFile.userId = [rs intForColumn:@"user_id"];
            currentFile.isDownload = [rs intForColumn:@"is_download"];
            currentFile.size = [rs longForColumn:@"size"];
            currentFile.fileId = [rs intForColumn:@"file_id"];
            currentFile.date = [rs longForColumn:@"date"];
            currentFile.etag = [rs stringForColumn:@"etag"];
            currentFile.isFavorite = [rs intForColumn:@"is_favorite"];
            currentFile.localFolder = [UtilsUrls getLocalFolderByFilePath:currentFile.filePath andFileName:currentFile.fileName andUserDto:mUser];
            currentFile.isNecessaryUpdate = [rs boolForColumn:@"is_necessary_update"];
            currentFile.sharedFileSource = [rs intForColumn:@"shared_file_source"];
            currentFile.permissions = [rs stringForColumn:@"permissions"];
            currentFile.taskIdentifier = [rs intForColumn:@"task_identifier"];
            currentFile.providingFileId = [rs intForColumn:@"providing_file_id"];
            
            [output addObject:currentFile];
        }
        [rs close];
    }];
    
    return output;
}


+ (NSMutableArray *) getFilesByFileId:(NSInteger) fileId {
    
    __block NSMutableArray *output = [NSMutableArray new];
    
    UserDto *mUser = [ManageUsersDB getActiveUser];
    
    FMDatabaseQueue *queue = Managers.sharedDatabase;
    
    [queue inDatabase:^(FMDatabase *db) {
        FMResultSet *rs = [db executeQuery:@"SELECT * FROM files WHERE file_id = ? ORDER BY file_name ASC", [NSNumber numberWithInteger:fileId]];
        while ([rs next]) {
            
            FileDto *currentFile = [[FileDto alloc] init];
            
            currentFile.idFile = [rs intForColumn:@"id"];
            currentFile.ocId = [rs stringForColumn:@"oc_id"];
            currentFile.filePath = [NSString stringWithFormat:@"%@%@",[UtilsUrls getRemovedPartOfFilePathAnd:mUser],[rs stringForColumn:@"file_path"]];
            currentFile.fileName = [rs stringForColumn:@"file_name"];
            currentFile.isDirectory = [rs intForColumn:@"is_directory"];
            currentFile.userId = [rs intForColumn:@"user_id"];
            currentFile.isDownload = [rs intForColumn:@"is_download"];
            currentFile.size = [rs longForColumn:@"size"];
            currentFile.fileId = [rs intForColumn:@"file_id"];
            currentFile.date = [rs longForColumn:@"date"];
            currentFile.etag = [rs stringForColumn:@"etag"];
            currentFile.isFavorite = [rs intForColumn:@"is_favorite"];
            currentFile.localFolder = [UtilsUrls getLocalFolderByFilePath:currentFile.filePath andFileName:currentFile.fileName andUserDto:mUser];
            currentFile.isNecessaryUpdate = [rs boolForColumn:@"is_necessary_update"];
            currentFile.sharedFileSource = [rs intForColumn:@"shared_file_source"];
            currentFile.permissions = [rs stringForColumn:@"permissions"];
            currentFile.taskIdentifier = [rs intForColumn:@"task_identifier"];
            currentFile.providingFileId = [rs intForColumn:@"providing_file_id"];
            
            [output addObject:currentFile];
        }
        [rs close];
    }];
    
    return output;
}


+ (FileDto *) getFileDtoByIdFile:(NSInteger) idFile {
    
    __block FileDto *output = nil;
    
    UserDto *mUser = [ManageUsersDB getActiveUser];
    
    DLog(@"getFileByIdFile: %ld", (long)idFile);
    
    FMDatabaseQueue *queue = Managers.sharedDatabase;
    
    [queue inDatabase:^(FMDatabase *db) {

        FMResultSet *rs = [db executeQuery:@"SELECT * FROM files WHERE id = ? AND user_id = ? ORDER BY file_name ASC", [NSNumber numberWithInteger:idFile], [NSNumber numberWithInteger:mUser.userId]];

        while ([rs next]) {
            
            output = [FileDto new];
            
            output.idFile = [rs intForColumn:@"id"];
            output.ocId = [rs stringForColumn:@"oc_id"];
            output.filePath = [NSString stringWithFormat:@"%@%@",[UtilsUrls getRemovedPartOfFilePathAnd:mUser],[rs stringForColumn:@"file_path"]];
            output.fileName = [rs stringForColumn:@"file_name"];
            output.isDirectory = [rs intForColumn:@"is_directory"];
            output.userId = [rs intForColumn:@"user_id"];
            output.isDownload = [rs intForColumn:@"is_download"];
            output.size = [rs longForColumn:@"size"];
            output.fileId = [rs intForColumn:@"file_id"];
            output.date = [rs longForColumn:@"date"];
            output.isFavorite = [rs intForColumn:@"is_favorite"];
            output.localFolder = [UtilsUrls getLocalFolderByFilePath:output.filePath andFileName:output.fileName andUserDto:mUser];
            output.etag = [rs stringForColumn:@"etag"];
            output.isRootFolder = [rs intForColumn:@"is_root_folder"];
            output.isNecessaryUpdate = [rs intForColumn:@"is_necessary_update"];
            output.sharedFileSource = [rs intForColumn:@"shared_file_source"];
            output.permissions = [rs stringForColumn:@"permissions"];
            output.taskIdentifier = [rs intForColumn:@"task_identifier"];
            output.providingFileId = [rs intForColumn:@"providing_file_id"];
        }
        [rs close];
    }];
    
    return output;
}


+(FileDto *) getFileDtoByFileName:(NSString *) fileName andFilePath:(NSString *) filePath andUser:(UserDto *) user {
    
    __block FileDto *output = nil;
    
    FMDatabaseQueue *queue = Managers.sharedDatabase;
    
    [queue inDatabase:^(FMDatabase *db) {
        FMResultSet *rs = [db executeQuery:@"SELECT * FROM files WHERE file_name = ? AND file_path= ? AND user_id = ? ORDER BY file_name ASC",fileName, filePath, [NSNumber numberWithInteger:user.userId]];
        
        while ([rs next]) {
            
            output = [FileDto new];
            
            output.idFile = [rs intForColumn:@"id"];
            output.ocId = [rs stringForColumn:@"oc_id"];
            output.filePath = [NSString stringWithFormat:@"%@%@",[UtilsUrls getRemovedPartOfFilePathAnd:user],[rs stringForColumn:@"file_path"]];
            output.fileName = [rs stringForColumn:@"file_name"];
            output.isDirectory = [rs intForColumn:@"is_directory"];
            output.userId = [rs intForColumn:@"user_id"];
            output.isDownload = [rs intForColumn:@"is_download"];
            output.size = [rs longForColumn:@"size"];
            output.fileId = [rs intForColumn:@"file_id"];
            output.date = [rs longForColumn:@"date"];
            output.isFavorite = [rs intForColumn:@"is_favorite"];
            output.localFolder = [UtilsUrls getLocalFolderByFilePath:output.filePath andFileName:output.fileName andUserDto:user];
            output.etag = [rs stringForColumn:@"etag"];
            output.isRootFolder = [rs intForColumn:@"is_root_folder"];
            output.isNecessaryUpdate = [rs intForColumn:@"is_necessary_update"];
            output.sharedFileSource = [rs intForColumn:@"shared_file_source"];
            output.permissions = [rs stringForColumn:@"permissions"];
            output.taskIdentifier = [rs intForColumn:@"task_identifier"];
            output.providingFileId = [rs intForColumn:@"providing_file_id"];
    
        }
        [rs close];
    }];
    
    return output;
}


+(NSMutableArray *) getAllFoldersByBeginFilePath:(NSString *) beginFilePath {
    
    DLog(@"getAllFoldersByBeginFilePath");
    
    //To the like SQL nedd a % charcter in the sintaxis
    beginFilePath = [NSString stringWithFormat:@"%@%%", beginFilePath];
    
    UserDto *mUser;
    
#ifdef CONTAINER_APP
    AppDelegate *app = (AppDelegate *)[[UIApplication sharedApplication] delegate];
    mUser = app.activeUser;
#else
    mUser = [ManageUsersDB getActiveUser];
#endif
    
    __block NSMutableArray *output = [NSMutableArray new];
    
    FMDatabaseQueue *queue = Managers.sharedDatabase;
    
    [queue inDatabase:^(FMDatabase *db) {
        FMResultSet *rs = [db executeQuery:@"SELECT DISTINCT file_path, file_name, id FROM files WHERE user_id = ? AND file_path LIKE ? ORDER BY file_name ASC", [NSNumber numberWithInteger:mUser.userId], beginFilePath];
        while ([rs next]) {
            
            FileDto *currentFile = [FileDto new];
            
            currentFile.filePath = [rs stringForColumn:@"file_path"];
            currentFile.fileName = [rs stringForColumn:@"file_name"];
            currentFile.idFile = [rs intForColumn:@"id"];
            
            [output addObject:currentFile];
        }
        [rs close];
    }];
    
    return output;
}


+(void) setFileIsDownloadState: (NSInteger) idFile andState:(enumDownload)downloadState {
    
    DLog(@"_setFileIsDownloadState id =%ld",(long)idFile);
    FMDatabaseQueue *queue = Managers.sharedDatabase;
    
    [queue inTransaction:^(FMDatabase *db, BOOL *rollback) {
        BOOL correctQuery=NO;
        
        correctQuery = [db executeUpdate:@"UPDATE files SET is_download=? WHERE id = ?", [NSNumber numberWithInt:downloadState], [NSNumber numberWithInteger:idFile]];
        
        if (!correctQuery) {
            DLog(@"Error in setFileIsDownloadState id =%ld",(long)idFile);
        }
        
    }];
}


+(void) updateDownloadStateOfFileDtoByFileName:(NSString *) fileName andFilePath: (NSString *) filePath andActiveUser: (UserDto *) aciveUser withState:(enumDownload)downloadState {
    
    DLog(@"setFileIsDownloadState");
    FMDatabaseQueue *queue = Managers.sharedDatabase;
    
    [queue inTransaction:^(FMDatabase *db, BOOL *rollback) {
        BOOL correctQuery=NO;
        
        correctQuery = [db executeUpdate:@"UPDATE files SET is_download=? WHERE file_path = ? AND file_name=? AND user_id = ?", [NSNumber numberWithInt:downloadState], filePath, fileName, [NSNumber numberWithInteger:aciveUser.userId]];
        
        if (!correctQuery) {
            DLog(@"Error in setFileIsDownloadState");
        }
        
    }];
}


+(void) setFilePath: (NSString * ) filePath byIdFile: (NSInteger) idFile {
    
    DLog(@"NewFilePath: %@", filePath);
    FMDatabaseQueue *queue = Managers.sharedDatabase;
    
    [queue inTransaction:^(FMDatabase *db, BOOL *rollback) {
        BOOL correctQuery=NO;
        
        correctQuery = [db executeUpdate:@"UPDATE files SET file_path=? WHERE id = ?", filePath, [NSNumber numberWithInteger:idFile]];
        
        if (!correctQuery) {
            DLog(@"Error in setFilePath");
        }
        
    }];
}


+(void) insertManyFiles:(NSArray *)listOfFiles ofFileId:(NSInteger)fileId andUser:(UserDto *)user {
    
    NSString *sql = @"";
    NSMutableArray *arrayOfSqlRequests = [NSMutableArray new];
    
    NSInteger numberOfInsertEachTime = 0;
    
    //if count == 1 the file is the current folder so there is nothing to insert
    if([listOfFiles count] > 1) {
        for (int i = 0; i < [listOfFiles count]; i++) {
            if(i > 0) {
                
               //INSERT INTO files(file_path, file_name, is_directory,user_id, is_download, size, file_id, date
               FileDto *current = [listOfFiles objectAtIndex:i];
               current.fileId = fileId;
               current.userId = user.userId;
                
                //to jump the first becouse it is not necesary (is the same directory) and the other if is to insert 450 by 450
                if(numberOfInsertEachTime == 0) {
                    sql = [NSString stringWithFormat:@"INSERT INTO files SELECT null as id, '%@' as 'file_path','%@' as 'file_name', %ld as 'user_id', %d as 'is_directory',%ld as 'is_download', %ld as 'file_id', %@ as 'size', %@ as 'date', %d as 'is_favorite','%@' as 'etag', %d as 'is_root_folder', %d as 'is_necessary_update', %ld as 'shared_file_source', '%@' as 'permissions', %ld as 'task_identifier', %ld as 'providing_file_id', '%@' as 'oc_id'",
                           current.filePath,
                           current.fileName,
                           (long)current.userId,
                           current.isDirectory,
                           (long)current.isDownload,
                           (long)current.fileId,
                           [[NSNumber numberWithLong:current.size] stringValue],
                           [[NSNumber numberWithLong:current.date] stringValue],
                           current.isFavorite,
                           current.etag,
                           NO,
                           NO,
                           (long)current.sharedFileSource,
                           current.permissions,
                           (long)current.taskIdentifier,
                           (long)current.providingFileId,
                           current.ocId];

                    //DLog(@"sql!!!: %@", sql);
                } else {
                    sql = [NSString stringWithFormat:@"%@ UNION SELECT null, '%@','%@',%ld,%d,%ld,%ld,%@,%@,%d,'%@',%d,%d,%ld,'%@',%ld,%ld,'%@'",
                           sql,
                           current.filePath,
                           current.fileName,
                           (long)current.userId,
                           current.isDirectory,
                           (long)current.isDownload,
                           (long)current.fileId,
                           [[NSNumber numberWithLong:current.size] stringValue],
                           [[NSNumber numberWithLong:current.date] stringValue],
                           current.isFavorite,
                           current.etag,
                           NO,
                           NO,
                           (long)current.sharedFileSource,
                           current.permissions,
                           (long)current.taskIdentifier,
                           (long)current.providingFileId,
                           current.ocId];

                }
                
                numberOfInsertEachTime++;
                
                //DLog(@"sql: %@", sql);
                
                
                if(numberOfInsertEachTime > 450) {
                    numberOfInsertEachTime = 0;
                    //We add the sql with 450 request to the array
                    [arrayOfSqlRequests addObject:sql];
                }
            }
        }
        
        //We add the sql with less than 450 request to the array
        [arrayOfSqlRequests addObject:sql];
        
        FMDatabaseQueue *queue = Managers.sharedDatabase;
        
        [queue inTransaction:^(FMDatabase *db, BOOL *rollback) {
            
            BOOL correctQuery=NO;
            
            for (int i = 0 ; i < [arrayOfSqlRequests count] ; i++) {
                correctQuery = [db executeUpdate:[arrayOfSqlRequests objectAtIndex:i]];
            }
            
            if (!correctQuery) {
                DLog(@"Error inserting %lu files in DB for file directory id=%ld of user %@", (unsigned long)[listOfFiles count],  (long)fileId, user.username);
            } else {
                DLog(@"Inserted %lu files in DB for file directory id=%ld", (unsigned long)[listOfFiles count], (long)fileId);
            }
            
        }];
    }
}


+(void) deleteFileByIdFileOfActiveUser:(NSInteger) idFile {
    
    UserDto *mUser;
    
#ifdef CONTAINER_APP
    AppDelegate *app = (AppDelegate *)[[UIApplication sharedApplication] delegate];
    mUser = app.activeUser;
#else
    mUser = [ManageUsersDB getActiveUser];
#endif
    
    FMDatabaseQueue *queue = Managers.sharedDatabase;
    
    [queue inTransaction:^(FMDatabase *db, BOOL *rollback) {
        BOOL correctQuery=NO;
        
        correctQuery = [db executeUpdate:@"DELETE FROM files WHERE id = ? AND user_id = ?",[NSNumber numberWithInteger:idFile], [NSNumber numberWithInteger:mUser.userId]];
        
        if (!correctQuery) {
            DLog(@"Error in deleteFileByIdFile");
        }
        
    }];
}


+(void) deleteFileByIdFile:(NSInteger) idFile {
    
    FMDatabaseQueue *queue = Managers.sharedDatabase;
    
    [queue inTransaction:^(FMDatabase *db, BOOL *rollback) {
        BOOL correctQuery=NO;
        
        correctQuery = [db executeUpdate:@"DELETE FROM files WHERE id = ?",[NSNumber numberWithInteger:idFile]];
        
        if (!correctQuery) {
            DLog(@"Error in deleteFileByIdFile");
        }
        
    }];
}


+(void) deleteFilesFromDBBeforeRefreshByFileId: (NSInteger) fileId {
    
    DLog(@"deleteFilesFromDBBeforeRefreshByFileId");
    
    UserDto *mUser;
    
#ifdef CONTAINER_APP
    AppDelegate *app = (AppDelegate *)[[UIApplication sharedApplication] delegate];
    mUser = app.activeUser;
#else
    mUser = [ManageUsersDB getActiveUser];
#endif
    
    FMDatabaseQueue *queue = Managers.sharedDatabase;
    
    [queue inTransaction:^(FMDatabase *db, BOOL *rollback) {
        BOOL correctQuery=NO;
        
        correctQuery = [db executeUpdate:@"DELETE FROM files WHERE file_id = ? AND user_id = ?", [NSNumber numberWithInteger:fileId], [NSNumber numberWithInteger:mUser.userId]];
        
        if (!correctQuery) {
            DLog(@"Error in deleteFilesFromDBBeforeRefreshByFileId");
        }
        
    }];
}


+ (void) backupOfTheProcessingFilesAndFoldersByFileId:(NSInteger) fileId {
    
    UserDto *mUser;
    
#ifdef CONTAINER_APP
    AppDelegate *app = (AppDelegate *)[[UIApplication sharedApplication] delegate];
    mUser = app.activeUser;
#else
    mUser = [ManageUsersDB getActiveUser];
#endif
    
    FMDatabaseQueue *queue = Managers.sharedDatabase;
    
    [queue inTransaction:^(FMDatabase *db, BOOL *rollback) {
        BOOL correctQuery=NO;
        
        correctQuery = [db executeUpdate:@"INSERT INTO files_backup SELECT * FROM files WHERE user_id =? and file_id=?", [NSNumber numberWithInteger:mUser.userId], [NSNumber numberWithInteger:fileId]];
        
        if (!correctQuery) {
            DLog(@"Error in backupFoldersDownloadedFavoritesByFileId");
        }
    }];
}

+(void) updateRelatedFilesFromBackup {
    
    UserDto *mUser;
    
#ifdef CONTAINER_APP
    AppDelegate *app = (AppDelegate *)[[UIApplication sharedApplication] delegate];
    mUser = app.activeUser;
#else
    mUser = [ManageUsersDB getActiveUser];
#endif
    
    NSMutableArray *listFilesToUpdate = [NSMutableArray new];
    
    FMDatabaseQueue *queue = Managers.sharedDatabase;
    
    [queue inDatabase:^(FMDatabase *db) {
        FMResultSet *rs = [db executeQuery:@"SELECT files.id, back.file_id, back.etag, back.is_favorite FROM files, (SELECT DISTINCT files.file_id, files_backup.file_path, files_backup.file_name, files_backup.etag, files_backup.is_favorite FROM files_backup, files WHERE files.file_id = files_backup.id AND files_backup.is_directory = 1) back WHERE user_id = ? AND files.file_path = back.file_path AND files.file_name = back.file_name ORDER BY id DESC", [NSNumber numberWithInteger:mUser.userId]];
        while ([rs next]) {
            
            FileDto *currentFile = [[FileDto alloc] init];
            
            currentFile.idFile = [rs intForColumn:@"id"];
            currentFile.fileId = [rs intForColumn:@"file_id"];
            currentFile.etag = [rs stringForColumn:@"etag"];
            currentFile.isFavorite = [rs boolForColumn:@"is_favorite"];
            
            DLog(@"currentFile.idFile: %ld", (long)currentFile.idFile);
            DLog(@"currentFile.fileId %ld", (long)currentFile.fileId);
            DLog(@"currentFile.etag %@", currentFile.etag);
            
            [listFilesToUpdate addObject:currentFile];
        }
        [rs close];
    }];
    
    
    [queue inTransaction:^(FMDatabase *db, BOOL *rollback) {
        BOOL correctQuery=YES;
        
        for(int i = 0 ; i < [listFilesToUpdate count] ; i++) {

            FileDto *currentFile = [listFilesToUpdate objectAtIndex:i];
        
            correctQuery = [db executeUpdate:@"UPDATE files SET id = ?, etag = ? WHERE id = ?", [NSNumber numberWithInteger:currentFile.fileId], currentFile.etag, [NSNumber numberWithInteger:currentFile.idFile]];
            
        }
        
        if (!correctQuery) {
            DLog(@"Error in updateRelatedFilesFromBackup");
        }
    }];
}


+(void) updateFilesFromBackup {
    
    //1 - Select the files from the files_backup DB that want to be updated on the files DB
    NSMutableArray *listFilesToUpdate = [NSMutableArray new];
    
    FMDatabaseQueue *queue = Managers.sharedDatabase;
    
    [queue inDatabase:^(FMDatabase *db) {
        FMResultSet *rs = [db executeQuery:@"SELECT f.id, f.user_id, b.etag, b.is_necessary_update, b.is_download, b.shared_file_source, b.permissions, b.task_identifier, b.providing_file_id FROM files f, (SELECT id, user_id, file_path, file_name, etag, is_necessary_update, is_download, shared_file_source, permissions, task_identifier, providing_file_id FROM files_backup WHERE (files_backup.is_download != 0 or files_backup.shared_file_source != 0 or files_backup.providing_file_id != 0)) b WHERE b.file_path = f.file_path AND b.file_name = f.file_name AND b.user_id = f.user_id"];
        while ([rs next]) {
            
            FileDto *currentFile = [[FileDto alloc] init];
            currentFile.idFile = [rs intForColumn:@"f.id"];
            currentFile.etag = [rs stringForColumn:@"b.etag"];
            currentFile.isNecessaryUpdate = [rs boolForColumn:@"b.is_necessary_update"];
            currentFile.isDownload = [rs intForColumn:@"b.is_download"];
            currentFile.sharedFileSource = [rs intForColumn:@"b.shared_file_source"];
            currentFile.permissions = [rs stringForColumn:@"b.permissions"];
            currentFile.taskIdentifier = [rs intForColumn:@"b.task_identifier"];
            currentFile.providingFileId = [rs intForColumn:@"b.providing_file_id"];
            
            
            DLog(@"files share source = %ld", (long)currentFile.sharedFileSource);
            DLog(@"currentFile.idFile: %ld", (long)currentFile.idFile);
            DLog(@"currentFile.etag: %@", currentFile.etag);
            
            [listFilesToUpdate addObject:currentFile];
        }
        [rs close];
    }];
    
    DLog(@"Size list: %lu", (unsigned long)[listFilesToUpdate count]);

    //2 - Update the files DB with the selected datas from the files_backup DB
    [queue inTransaction:^(FMDatabase *db, BOOL *rollback) {
        BOOL correctQuery=YES;
        
        for(int i = 0 ; i < [listFilesToUpdate count] ; i++) {
            
            FileDto *currentFile = [listFilesToUpdate objectAtIndex:i];
            
            correctQuery = [db executeUpdate:@"UPDATE files SET is_download = ?, etag = ?, shared_file_source = ?, providing_file_id = ? WHERE id = ?", [NSNumber numberWithInteger:currentFile.isDownload],currentFile.etag ,[NSNumber numberWithInteger:currentFile.sharedFileSource], [NSNumber numberWithInteger:currentFile.providingFileId], [NSNumber numberWithInteger:currentFile.idFile]];
        
            if (!correctQuery) {
                DLog(@"Error in updateDownloadedFilesFromBackup");
            }
        }
    }];
}


+(void) setUpdateIsNecessaryFromBackup:(NSInteger) idFile {
    
    //1-Select the files from the files_backup DB
    NSMutableArray *listFilesToUpdate = [NSMutableArray new];
    
    NSMutableArray *listFilesFromFiles = [self getFilesByFileIdForActiveUser:idFile];
    NSMutableArray *listFilesFromFilesBackup = [NSMutableArray new];
    
    FMDatabaseQueue *queue = Managers.sharedDatabase;
    
    [queue inDatabase:^(FMDatabase *db) {
        FMResultSet *rs = [db executeQuery:@"SELECT file_name, etag, is_download, is_directory, is_favorite FROM files_backup WHERE is_download = 1 OR is_download = 2 OR is_download = 3 OR (is_directory = 1 AND is_favorite = 1)"];
        while ([rs next]) {
            
            FileDto *currentFile = [[FileDto alloc] init];
            
            currentFile.fileName = [rs stringForColumn:@"file_name"];
            currentFile.etag = [rs stringForColumn:@"etag"];
            currentFile.isDownload = [rs intForColumn:@"is_download"];
            
            DLog(@"currentFile.idFile: %ld", (long)currentFile.idFile);

            
            [listFilesFromFilesBackup addObject:currentFile];
        }
        [rs close];
    }];
    
    //2-Save the files that have different etag from files_backup DB
    for (FileDto *currentBackup in listFilesFromFilesBackup) {
        for (FileDto *currentFile in listFilesFromFiles) {
            if ((![currentBackup.etag isEqual: currentFile.etag]) && [currentBackup.fileName isEqualToString:currentFile.fileName]) {
                if (![currentBackup.etag isEqual:@""]) {
                    currentFile.isDownload = currentBackup.isDownload;
                    [listFilesToUpdate addObject:currentFile];
                }
            }
        }
    }

    DLog(@"Size list: %lu", (unsigned long)[listFilesToUpdate count]);

    //3-Set all the files that need update less the overwritten ones
    [queue inTransaction:^(FMDatabase *db, BOOL *rollback) {
        BOOL correctQuery=YES;
        
        for(int i = 0 ; i < [listFilesToUpdate count] ; i++) {
            FileDto *currentFile = [listFilesToUpdate objectAtIndex:i];
            //Only update the field isNecessary update if it is not an overwritten file
            if (!(currentFile.isDownload == overwriting)) {
                correctQuery = [db executeUpdate:@"UPDATE files SET is_necessary_update = 1 WHERE id = ?", [NSNumber numberWithInteger:currentFile.idFile]];
            }
        }
        if (!correctQuery) {
            DLog(@"Error in setUpdateIsNecessaryFromBackup");
        }
    }];
    
    //Releasing memory
    listFilesToUpdate = nil;
    listFilesFromFiles = nil;
    listFilesFromFilesBackup = nil;
}


+ (void) setIsNecessaryUpdateOfTheFile: (NSInteger) idFile {
    DLog(@"setIsNecessaryUpdateOfTheFile");
    FMDatabaseQueue *queue = Managers.sharedDatabase;
    
    [queue inTransaction:^(FMDatabase *db, BOOL *rollback) {
        BOOL correctQuery=NO;
        
        correctQuery = [db executeUpdate:@"UPDATE files SET is_necessary_update = 1 WHERE id = ?", [NSNumber numberWithInteger:idFile]];
        
        if (!correctQuery) {
            DLog(@"Error in update the field setIsNecessaryUpdateOfTheFile");
        }
    }];
}


+ (void) deleteOffspringOfThisFolder:(FileDto *)folder{
    
    //Get Files of the Folder
    NSArray *files = [ManageFilesDB getFilesByFileId:folder.idFile];
    
    for (FileDto *tempFile in files) {
        //Check if the item is a directory
        if (tempFile.isDirectory) {
            //Recursive called for the next folder
            [self deleteOffspringOfThisFolder:tempFile];
        }else{
            //Delete a file inside the folder
            [ManageFilesDB deleteFileByIdFile:tempFile.idFile];
        }
    }
    //Finally we delete the folder of the database
    [ManageFilesDB deleteFileByIdFile:folder.idFile];
}


+(void) deleteAllFilesAndFoldersThatNotExistOnServerFromBackup {
    
    DLog(@"deleteAllFilesAndFoldersThatNotExistOnServerFromBackup");
    
    UserDto *mUser;
    
#ifdef CONTAINER_APP
    AppDelegate *app = (AppDelegate *)[[UIApplication sharedApplication] delegate];
    mUser = app.activeUser;
#else
    mUser = [ManageUsersDB getActiveUser];
#endif
    
    NSMutableArray *listFilesToDelete = [NSMutableArray new];
    
    FMDatabaseQueue *queue = Managers.sharedDatabase;
    
    [queue inDatabase:^(FMDatabase *db) {
        FMResultSet *rs = [db executeQuery:@"SELECT files_backup.id, files_backup.file_path, files_backup.file_name, files_backup.is_directory FROM files_backup WHERE files_backup.id NOT IN (SELECT back.id FROM (SELECT id, file_path, file_name FROM files_backup) back, (SELECT id, file_path, file_name FROM files WHERE user_id = ?) files WHERE files.file_path = back.file_path AND files.file_name = back.file_name)", [NSNumber numberWithInteger:mUser.userId]];
        while ([rs next]) {
            
            FileDto *currentFile = [[FileDto alloc] init];
            
            currentFile.idFile = [rs intForColumn:@"id"];
            currentFile.filePath = [NSString stringWithFormat:@"%@%@",[UtilsUrls getRemovedPartOfFilePathAnd:mUser],[rs stringForColumn:@"file_path"]];
            currentFile.fileName = [rs stringForColumn:@"file_name"];
            currentFile.isDirectory = [rs intForColumn:@"is_directory"];
            
            [listFilesToDelete addObject:currentFile];
        }
        [rs close];
    }];
    
    // Create file manager
    NSFileManager *fileMgr = [[NSFileManager alloc] init];
    
    for(NSInteger i = 0 ; i < [listFilesToDelete count] ; i++) {
        
        FileDto *currentFile = [listFilesToDelete objectAtIndex:i];
        
        currentFile.localFolder = [UtilsUrls getLocalFolderByFilePath:currentFile.filePath andFileName:currentFile.fileName andUserDto:mUser];
        
        DLog(@"File download to delete");
        NSError *error;
        
        DLog(@"FileName: %@", currentFile.fileName);
        DLog(@"Delete: %@", currentFile.localFolder);
        
        //if file is directory
        if (currentFile.isDirectory) {
            //Delete the offspring of this directory
            [self deleteOffspringOfThisFolder:currentFile];
        }
        
        // Attempt to delete the file at filePath2
        if ([fileMgr removeItemAtPath:currentFile.localFolder error:&error] != YES) {
            DLog(@"Unable to delete file: %@", [error localizedDescription]);
        } else {
            DLog(@"Deleted");
        }
    }
}


+(void) deleteAllThumbnailsWithDifferentEtagFromBackup {
    
    DLog(@"deleteAllThumbnailsWithDifferentEtagFromBackup");
    
    NSMutableArray *listFilesToDelete = [NSMutableArray new];
    
    FMDatabaseQueue *queue = Managers.sharedDatabase;
    
    [queue inDatabase:^(FMDatabase *db) {
        FMResultSet *rs = [db executeQuery:@"SELECT b.user_id, b.oc_id, b.file_name, b.file_path FROM files_backup b, files f WHERE b.user_id=f.user_id AND b.file_path=f.file_path AND b.file_name=f.file_name AND b.etag!=f.etag"];
        while ([rs next]) {
            
            FileDto *currentFile = [FileDto new];
            
            currentFile.userId = [rs intForColumn:@"user_id"];
            currentFile.ocId = [rs stringForColumn:@"oc_id"];
            
            [listFilesToDelete addObject:currentFile];
        }
        [rs close];
    }];
    
    for (FileDto *current in listFilesToDelete) {
        [[ManageThumbnails sharedManager] removeStoredThumbnailForFile:current];
    }
}


+(void) updateFavoriteFilesFromBackup {
    
    
    NSMutableArray *listFilesToUpdate = [NSMutableArray new];
   
    FMDatabaseQueue *queue = Managers.sharedDatabase;
    
    [queue inDatabase:^(FMDatabase *db) {
        FMResultSet *rs = [db executeQuery:@"SELECT f.id FROM files f, (SELECT id, file_path, user_id, file_name FROM files_backup WHERE files_backup.is_favorite = 1) b WHERE b.file_path = f.file_path AND b.file_name=f.file_name AND f.user_id = b.user_id"];
        
        while ([rs next]) {
                        
            FileDto *currentFile = [FileDto new];
            
            currentFile.idFile = [rs intForColumn:@"f.id"];
            
            [listFilesToUpdate addObject:currentFile];
        }
        [rs close];
    }];
    
    
    [queue inTransaction:^(FMDatabase *db, BOOL *rollback) {
        BOOL correctQuery=YES;
        
        for(NSInteger i = 0 ; i < [listFilesToUpdate count] ; i++) {
            FileDto *currentFile = [listFilesToUpdate objectAtIndex:i];
            correctQuery = [db executeUpdate:@"UPDATE files SET is_favorite = 1 WHERE id = ?", [NSNumber numberWithInteger:currentFile.idFile]];
        }
        
        if (!correctQuery) {
            DLog(@"Error in updateFavoriteFilesFromBackup");
        }
    }];
}


+ (void) deleteFilesBackup {
    
    FMDatabaseQueue *queue = Managers.sharedDatabase;
    
    [queue inTransaction:^(FMDatabase *db, BOOL *rollback) {
        BOOL correctQuery=NO;
        
        correctQuery = [db executeUpdate:@"DELETE FROM files_backup"];
        
        if (!correctQuery) {
            DLog(@"Error in deleteFilesBackup");
        }
        
    }];
}


+(void) renameFileByFileDto:(FileDto *) file andNewName:(NSString *) mNewName {
    
    FMDatabaseQueue *queue = Managers.sharedDatabase;
    
    [queue inTransaction:^(FMDatabase *db, BOOL *rollback) {
        BOOL correctQuery=NO;
        
        correctQuery = [db executeUpdate:@"UPDATE files SET file_name=? WHERE id = ?", mNewName, [NSNumber numberWithInteger:file.idFile]];
        
        if (!correctQuery) {
            DLog(@"Error in renameFileByFileDto");
        }
        
    }];
}


+(void) renameFolderByFileDto:(FileDto *) file andNewName:(NSString *) mNewName {
    
    mNewName=[NSString stringWithFormat:@"%@/", mNewName];
    
    FMDatabaseQueue *queue = Managers.sharedDatabase;
    
    [queue inTransaction:^(FMDatabase *db, BOOL *rollback) {
        BOOL correctQuery=NO;
        
        correctQuery = [db executeUpdate:@"UPDATE files SET file_name=? WHERE id = ?", mNewName, [NSNumber numberWithInteger:file.idFile]];
        
        if (!correctQuery) {
            DLog(@"Error in renameFolderByFileDto");
        }
        
    }];
}


+(BOOL) isFileOnDataBase: (FileDto *)fileDto {
    
    __block int size = 0;
    
    BOOL output = NO;
    DLog(@"File path: %@",fileDto.fileName);
    
    FMDatabaseQueue *queue = Managers.sharedDatabase;
    
    [queue inDatabase:^(FMDatabase *db) {
        FMResultSet *rs = [db executeQuery:@"SELECT COUNT(*) as NUM FROM files WHERE etag = ? AND user_id = ?", fileDto.etag, [NSNumber numberWithInteger:fileDto.userId]];
        while ([rs next]) {
            size = [rs intForColumn:@"NUM"];
        }
        [rs close];
    }];
    
    if(size > 0) {
        output = YES;
    }
    
    return output;
}


+(void) deleteFileByFilePath: (NSString *) filePathToDelete andFileName: (NSString*)fileName {
    
    DLog(@"deleteFileByFilePath: %@ filePathToDelete andFileName: %@", filePathToDelete, fileName);
    
    UserDto *mUser;
    
#ifdef CONTAINER_APP
    AppDelegate *app = (AppDelegate *)[[UIApplication sharedApplication] delegate];
    mUser = app.activeUser;
#else
    mUser = [ManageUsersDB getActiveUser];
#endif
    
    FMDatabaseQueue *queue = Managers.sharedDatabase;
    
    [queue inTransaction:^(FMDatabase *db, BOOL *rollback) {
        BOOL correctQuery=NO;
        
        correctQuery = [db executeUpdate:@"DELETE FROM files WHERE file_path = ? AND file_name = ? AND user_id = ?",filePathToDelete, fileName, [NSNumber numberWithInteger:mUser.userId]];
        
        if (!correctQuery) {
            DLog(@"Error in deleteFileByFilePath");
        }
    }];
}


+(FileDto *) getFolderByFilePath: (NSString *) newFilePath andFileName: (NSString *) fileName {

    __block FileDto *output = nil;
    
    UserDto *mUser;
    
#ifdef CONTAINER_APP
    AppDelegate *app = (AppDelegate *)[[UIApplication sharedApplication] delegate];
    mUser = app.activeUser;
#else
    mUser = [ManageUsersDB getActiveUser];
#endif
    
    FMDatabaseQueue *queue = Managers.sharedDatabase;
    
    [queue inDatabase:^(FMDatabase *db) {
        FMResultSet *rs = [db executeQuery:@"SELECT * FROM files WHERE file_path = ? AND file_name = ? AND user_id = ? AND is_directory = 1 ORDER BY file_name ASC", newFilePath, fileName, [NSNumber numberWithInteger:mUser.userId]];
                
        while ([rs next]) {
            
            output = [FileDto new];
            
            output.idFile = [rs intForColumn:@"id"];
            output.ocId = [rs stringForColumn:@"oc_id"];
            output.filePath = [NSString stringWithFormat:@"%@%@",[UtilsUrls getRemovedPartOfFilePathAnd:mUser],[rs stringForColumn:@"file_path"]];
            output.fileName = [rs stringForColumn:@"file_name"];
            output.isDirectory = [rs intForColumn:@"is_directory"];
            output.userId = [rs intForColumn:@"user_id"];
            output.isDownload = [rs intForColumn:@"is_download"];
            output.size = [rs longForColumn:@"size"];
            output.fileId = [rs intForColumn:@"file_id"];
            output.date = [rs longForColumn:@"date"];
            output.isFavorite = [rs intForColumn:@"is_favorite"];
            output.localFolder = [UtilsUrls getLocalFolderByFilePath:output.filePath andFileName:output.fileName andUserDto:mUser];
            
        }
        [rs close];
    }];
    
    return output;
}


+ (void) updateFolderOfFileDtoByNewFilePath:(NSString *) newFilePath andDestinationFileDto:(FileDto *) folderDto andNewFileName:(NSString *)changedFileName andFileDto:(FileDto *) selectedFile {
    
    FMDatabaseQueue *queue = Managers.sharedDatabase;
    
    [queue inTransaction:^(FMDatabase *db, BOOL *rollback) {
        BOOL correctQuery=NO;
        
        correctQuery = [db executeUpdate:@"UPDATE files SET file_path=?, file_id=?, file_name=? WHERE id = ?", [NSString stringWithFormat:@"%@",newFilePath], [NSNumber numberWithInteger:folderDto.idFile], changedFileName, [NSNumber numberWithInteger:selectedFile.idFile]];
        
        if (!correctQuery) {
            DLog(@"Error in updateFolderOfFileDtoByNewFilePath");
        }
        
    }];
}


+(void) updatePath:(NSString *) oldFilePath withNew:(NSString *) newFilePath andFileId:(NSInteger) fileId andSelectedFileId:(NSInteger) selectedFileId andChangedFileName:(NSString *) fileName {
    
    UserDto *mUser;
    
#ifdef CONTAINER_APP
    AppDelegate *app = (AppDelegate *)[[UIApplication sharedApplication] delegate];
    mUser = app.activeUser;
#else
    mUser = [ManageUsersDB getActiveUser];
#endif
    
    FMDatabaseQueue *queue = Managers.sharedDatabase;
    
    [queue inTransaction:^(FMDatabase *db, BOOL *rollback) {
        BOOL correctQuery=NO;
        
        correctQuery = [db executeUpdate:@"UPDATE files SET file_path=?, file_id=?, file_name=? WHERE user_id = ? AND id = ?", newFilePath, [NSNumber numberWithInteger:fileId], fileName, [NSNumber numberWithInteger:mUser.userId], [NSNumber numberWithInteger:selectedFileId]];
                
        if (!correctQuery) {
            DLog(@"Error in updateFolderOfFileDtoByNewFilePath");
        }
        
    }];
}


+(void) updatePathwithNewPath:(NSString *) newFilePath andFileDto:(FileDto *) selectedFile {
    
    UserDto *mUser;
    
#ifdef CONTAINER_APP
    AppDelegate *app = (AppDelegate *)[[UIApplication sharedApplication] delegate];
    mUser = app.activeUser;
#else
    mUser = [ManageUsersDB getActiveUser];
#endif
    
    FMDatabaseQueue *queue = Managers.sharedDatabase;
    
    [queue inTransaction:^(FMDatabase *db, BOOL *rollback) {
        BOOL correctQuery=NO;
        
        correctQuery = [db executeUpdate:@"UPDATE files SET file_path=? WHERE user_id = ? AND id=?", newFilePath, [NSNumber numberWithInteger:mUser.userId], [NSNumber numberWithInteger:selectedFile.idFile]];
        
        if (!correctQuery) {
            DLog(@"Error in updatePathwithNewPath");
        }
        
    }];
}


+(BOOL) isExistRootFolderByUser:(UserDto *) currentUser {
    
    __block int size = 0;
    
    BOOL output = NO;
    
    
    FMDatabaseQueue *queue = Managers.sharedDatabase;
    
    [queue inDatabase:^(FMDatabase *db) {
        FMResultSet *rs = [db executeQuery:@"SELECT COUNT(*) AS NUM FROM files WHERE user_id = ? AND is_root_folder = 1", [NSNumber numberWithInteger:currentUser.userId]];
        while ([rs next]) {
            size = [rs intForColumn:@"NUM"];
        }
        [rs close];
    }];
    
    if(size > 0) {
        output = YES;
    }
    
    return output;
}


+(void) insertFile:(FileDto *)fileDto {
    
    FMDatabaseQueue *queue = Managers.sharedDatabase;
    
    [queue inTransaction:^(FMDatabase *db, BOOL *rollback) {
        BOOL correctQuery=NO;
        
        correctQuery = [db executeUpdate:@"INSERT INTO files(file_path, file_name, is_directory,user_id, is_download, size, file_id, date, is_favorite, etag, is_root_folder, is_necessary_update, shared_file_source, permissions, task_identifier, providing_file_id, oc_id) Values(?,?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?)", fileDto.filePath, fileDto.fileName, [NSNumber numberWithBool:fileDto.isDirectory], [NSNumber numberWithInteger:fileDto.userId], [NSNumber numberWithInteger:fileDto.isDownload], [NSNumber numberWithLong:fileDto.size], [NSNumber numberWithInteger:fileDto.fileId], [NSNumber numberWithLong:fileDto.date], [NSNumber numberWithBool:fileDto.isFavorite], fileDto.etag, [NSNumber numberWithBool:fileDto.isRootFolder], [NSNumber numberWithBool:fileDto.isNecessaryUpdate], [NSNumber numberWithInteger:fileDto.sharedFileSource], fileDto.permissions, [NSNumber numberWithInteger:fileDto.taskIdentifier], [NSNumber numberWithInteger:fileDto.providingFileId], fileDto.ocId];
                        
        if (!correctQuery) {
            DLog(@"Error in insertFile");
        }
    }];
}


+(FileDto *) getRootFileDtoByUser:(UserDto *) currentUser {
    
    __block FileDto *output = nil;
    
    FMDatabaseQueue *queue = Managers.sharedDatabase;
    
    [queue inDatabase:^(FMDatabase *db) {
        FMResultSet *rs = [db executeQuery:@"SELECT * FROM files WHERE user_id = ? AND is_root_folder = 1 ORDER BY file_name ASC", [NSNumber numberWithInteger:currentUser.userId]];
        
        while ([rs next]) {
            
            output = [FileDto new];
            
            output.idFile = [rs intForColumn:@"id"];
            output.ocId = [rs stringForColumn:@"oc_id"];
            output.filePath = [NSString stringWithFormat:@"%@%@",[UtilsUrls getRemovedPartOfFilePathAnd:currentUser],[rs stringForColumn:@"file_path"]];
            output.fileName = [rs stringForColumn:@"file_name"];
            output.isDirectory = [rs intForColumn:@"is_directory"];
            output.userId = [rs intForColumn:@"user_id"];
            output.isDownload = [rs intForColumn:@"is_download"];
            output.size = [rs longForColumn:@"size"];
            output.fileId = [rs intForColumn:@"file_id"];
            output.date = [rs longForColumn:@"date"];
            output.isFavorite = [rs intForColumn:@"is_favorite"];
            output.localFolder = [UtilsUrls getLocalFolderByFilePath:output.filePath andFileName:output.fileName andUserDto:currentUser];
            output.etag = [rs stringForColumn:@"etag"];
            output.isRootFolder = [rs intForColumn:@"is_root_folder"];
            output.isNecessaryUpdate = [rs intForColumn:@"is_necessary_update"];
            output.sharedFileSource = [rs intForColumn:@"shared_file_source"];
            output.permissions = [rs stringForColumn:@"permissions"];
            output.taskIdentifier = [rs intForColumn:@"task_identifier"];
            output.providingFileId = [rs intForColumn:@"providing_file_id"];
            
        }
        [rs close];
    }];
    
    return output;
}

+(void) updateEtagOfFileDtoByid:(NSInteger) idFile andNewEtag: (NSString *)etag {

    FMDatabaseQueue *queue = Managers.sharedDatabase;
    
    [queue inTransaction:^(FMDatabase *db, BOOL *rollback) {
        BOOL correctQuery=NO;
        
        correctQuery = [db executeUpdate:@"UPDATE files SET etag=? WHERE id = ?", etag, [NSNumber numberWithInteger:idFile]];
        
        if (!correctQuery) {
            DLog(@"Error in updatePathwithNewPath");
        }
        
    }];
}


+(void) updateEtagOfFileDtoByFileName:(NSString *) fileName andFilePath: (NSString *) filePath andActiveUser: (UserDto *) aciveUser withNewEtag: (NSString *)etag {
    
    FMDatabaseQueue *queue = Managers.sharedDatabase;
    
    [queue inTransaction:^(FMDatabase *db, BOOL *rollback) {
        BOOL correctQuery=NO;
        
        correctQuery = [db executeUpdate:@"UPDATE files SET etag=? WHERE file_path = ? AND file_name=? AND user_id = ?", etag, filePath, fileName, [NSNumber numberWithInteger:aciveUser.userId]];
        
        if (!correctQuery) {
            DLog(@"Error in updatePathwithNewPath");
        }
    }];
}


+ (void) updateFilesWithFileId:(NSInteger) oldFileId withNewFileId:(NSInteger) fileId {
    
    UserDto *mUser;
    
#ifdef CONTAINER_APP
    AppDelegate *app = (AppDelegate *)[[UIApplication sharedApplication] delegate];
    mUser = app.activeUser;
#else
    mUser = [ManageUsersDB getActiveUser];
#endif
    
    FMDatabaseQueue *queue = Managers.sharedDatabase;
    
    [queue inTransaction:^(FMDatabase *db, BOOL *rollback) {
        BOOL correctQuery=NO;
        
        correctQuery = [db executeUpdate:@"UPDATE files SET file_id=? WHERE file_id = ? AND user_id = ?", [NSNumber numberWithInteger:fileId], [NSNumber numberWithInteger:oldFileId], [NSNumber numberWithInteger:mUser.userId]];
        
        if (!correctQuery) {
            DLog(@"Error in updatePathwithNewPath");
        }
        
    }];
}


+ (void) setFile:(NSInteger)idFile isNecessaryUpdate:(BOOL)isNecessaryUpdate {
    FMDatabaseQueue *queue = Managers.sharedDatabase;
    
    [queue inTransaction:^(FMDatabase *db, BOOL *rollback) {
        BOOL correctQuery=NO;
        
        correctQuery = [db executeUpdate:@"UPDATE files SET is_necessary_update=? WHERE id = ?", [NSNumber numberWithInt:isNecessaryUpdate], [NSNumber numberWithInteger:idFile]];
        
        if (!correctQuery) {
            DLog(@"Error in setFile:idFile isNecessaryUpdate:isNecessaryUpdate");
        }
        
    }];
}


+ (BOOL) isGetFilesByDownloadState:(enumDownload)downloadState andByUser:(UserDto *)currentUser andFolder:(NSString *)folder {
    
    __block BOOL output = NO;
    DLog(@"isGetFilesByDownloadState: %d andByUser: %@",downloadState, currentUser);
    
    FMDatabaseQueue *queue = Managers.sharedDatabase;
    
    [queue inDatabase:^(FMDatabase *db) {
     FMResultSet *rs = [db executeQuery:@"SELECT COUNT(*) as NUM FROM files WHERE is_download = ? AND user_id = ? AND file_path LIKE ? ORDER BY file_name ASC", [NSNumber numberWithInteger:downloadState], [NSNumber numberWithInteger:currentUser.userId], [NSString stringWithFormat:@"%@%%", folder]];
        while ([rs next]) {
            int numberOfFiles = [rs intForColumn:@"NUM"];
            if(numberOfFiles > 0) {
                output = YES;
            }
        }
        [rs close];
    }];
    
    return output;
}


+ (BOOL) isThisFile:(NSInteger)idFile ofThisUserId:(NSInteger)userId intoThisFolder:(NSString *)folder{
    
    DLog(@"ManageFiles -> idFile: %ld", (long)idFile);
    DLog(@"ManageFiles -> userId: %ld", (long)userId);

    DLog(@"ManageFiles -> folder: %@", folder);
    
    __block BOOL output = NO;
    
    FMDatabaseQueue *queue = Managers.sharedDatabase;
    
    [queue inDatabase:^(FMDatabase *db) {
        FMResultSet *rs = [db executeQuery:@"SELECT id FROM files WHERE user_id = ? AND file_path LIKE ?", [NSNumber numberWithInteger:userId], [NSString stringWithFormat:@"%@%%", folder]];
       
        
        while ([rs next]) {
            NSInteger tempIdFile = 0;
            tempIdFile = [rs intForColumn:@"id"];
            DLog(@"ManageFiles -> idfile: %ld",(long)tempIdFile);

            if (tempIdFile == idFile) {
                output = YES;
            }
        }
        [rs close];
    }];
    
    return output;
}


+ (void) updateFilesByUser:(UserDto *) currentUser andFolder:(NSString *) folder toDownloadState:(enumDownload)downloadState andIsNecessaryUpdate:(BOOL) isNecessaryUpdate {
    
    FMDatabaseQueue *queue = Managers.sharedDatabase;
    
    [queue inTransaction:^(FMDatabase *db, BOOL *rollback) {
        BOOL correctQuery=NO;
        
        correctQuery = [db executeUpdate:@"UPDATE files SET is_download = ?, is_necessary_update = ? WHERE user_id = ? AND file_path LIKE ? ", [NSNumber numberWithInteger:downloadState],[NSNumber numberWithInt:isNecessaryUpdate], [NSNumber numberWithInteger:currentUser.userId], [NSString stringWithFormat:@"%@%%", folder]];
        
        if (!correctQuery) {
            DLog(@"Error in updateFilesByUserAndFolder");
        }
        
    }];
}


#pragma mark - Share Querys.

+ (void) updateShareFileSource:(NSInteger)value forThisFile:(NSInteger)idFile ofThisUserId:(NSInteger)userId{
    
    FMDatabaseQueue *queue = Managers.sharedDatabase;
    
    [queue inTransaction:^(FMDatabase *db, BOOL *rollback) {
        BOOL correctQuery=NO;
        
        correctQuery = [db executeUpdate:@"UPDATE files SET shared_file_source = ? WHERE id = ? AND user_id= ?", [NSNumber numberWithInteger:value], [NSNumber numberWithInteger:idFile],[NSNumber numberWithInteger:userId]];
        
        if (!correctQuery) {
            DLog(@"Error in update share file source");
        }
        
    }];
}


+ (void) setUnShareAllFilesByUserId:(NSInteger)userId {
    FMDatabaseQueue *queue = Managers.sharedDatabase;
    
    [queue inTransaction:^(FMDatabase *db, BOOL *rollback) {
        BOOL correctQuery=NO;
        
        correctQuery = [db executeUpdate:@"UPDATE files SET shared_file_source = 0 WHERE user_id= ?", [NSNumber numberWithInteger:userId]];
        
        if (!correctQuery) {
            DLog(@"Error in update share file source");
        }
        
    }];
}


+ (void) updateFilesAndSetSharedOfUser:(NSInteger)userId {
    
    NSMutableArray *listOfFileSource = [NSMutableArray new];
    NSMutableArray *listOfidFile = [NSMutableArray new];
    
    FMDatabaseQueue *queue = Managers.sharedDatabase;
    
    [queue inDatabase:^(FMDatabase *db) {
        FMResultSet *rs = [db executeQuery:@"SELECT tmp_shared.file_source AS file_source, tmp_file.id AS id_file FROM (SELECT * FROM shared WHERE share_type=3 OR share_type=0 OR share_type=1 AND user_id=?) AS tmp_shared, (SELECT id, shared_file_source , ('/' || file_path || file_name) full_file_path FROM files WHERE user_id=?) AS tmp_file WHERE tmp_shared.path = tmp_file.full_file_path AND tmp_shared.file_source != tmp_file.shared_file_source",[NSNumber numberWithInteger:userId], [NSNumber numberWithInteger:userId]];
        while ([rs next]) {
            
            [listOfFileSource addObject:[NSNumber numberWithInt:[rs intForColumn:@"file_source"]]];
            [listOfidFile addObject:[NSNumber numberWithInt:[rs intForColumn:@"id_file"]]];
             
        }
        [rs close];
    }];

    DLog(@"listOfFileSource: %lu", (unsigned long)[listOfFileSource count]);
    
    [queue inTransaction:^(FMDatabase *db, BOOL *rollback) {
        BOOL correctQuery=YES;
        
        //listOfFileSource and listOfidFile have the same size
        for(int i = 0 ; i < [listOfFileSource count] ; i++) {
            
            NSNumber *fileSource = [listOfFileSource objectAtIndex:i];
            NSNumber *idFile = [listOfidFile objectAtIndex:i];
            
            correctQuery = [db executeUpdate:@"UPDATE files SET shared_file_source = ? WHERE id = ?", fileSource, idFile];
        }
        
        if (!correctQuery) {
            DLog(@"Error in updateDownloadedFilesFromBackup");
        }
        
    }];
}


+ (void) deleteShareDataOfThisFiles:(NSArray*)pathItems ofUser:(NSInteger)userId{
    
    for (FileDto *file in pathItems) {
         //Update shareFileSource to 0
        [self updateShareFileSource:0 forThisFile:file.idFile ofThisUserId:userId];
        
    }
}


+ (NSMutableArray *) getFilesByDownloadStatus:(NSInteger) status andUser:(UserDto *) user {
    __block NSMutableArray *output = [NSMutableArray new];
    DLog(@"getFilesByDownloadStatus: %ld",(long)status);
    
    FMDatabaseQueue *queue = Managers.sharedDatabase;
    
    [queue inDatabase:^(FMDatabase *db) {
        
    FMResultSet *rs = [db executeQuery:@"SELECT * FROM files WHERE is_download = ? AND user_id = ? ORDER BY file_name ASC", [NSNumber numberWithInteger:status], [NSNumber numberWithInteger:user.userId]];
        while ([rs next]) {
            
            FileDto *currentFile = [[FileDto alloc] init];
            
            currentFile.idFile = [rs intForColumn:@"id"];
            currentFile.ocId = [rs stringForColumn:@"oc_id"];
            currentFile.filePath = [NSString stringWithFormat:@"%@%@",[UtilsUrls getRemovedPartOfFilePathAnd:user],[rs stringForColumn:@"file_path"]];
            currentFile.fileName = [rs stringForColumn:@"file_name"];
            currentFile.isDirectory = [rs intForColumn:@"is_directory"];
            currentFile.userId = [rs intForColumn:@"user_id"];
            currentFile.isDownload = [rs intForColumn:@"is_download"];
            currentFile.size = [rs longForColumn:@"size"];
            currentFile.fileId = [rs intForColumn:@"file_id"];
            currentFile.date = [rs longForColumn:@"date"];
            currentFile.etag = [rs stringForColumn:@"etag"];
            currentFile.isFavorite = [rs intForColumn:@"is_favorite"];
            currentFile.localFolder = [UtilsUrls getLocalFolderByFilePath:currentFile.filePath andFileName:currentFile.fileName andUserDto:user];
            currentFile.isNecessaryUpdate = [rs boolForColumn:@"is_necessary_update"];
            currentFile.sharedFileSource = [rs intForColumn:@"shared_file_source"];
            currentFile.permissions = [rs stringForColumn:@"permissions"];
            currentFile.taskIdentifier = [rs intForColumn:@"task_identifier"];
            currentFile.providingFileId = [rs intForColumn:@"providing_file_id"];
            
            [output addObject:currentFile];
        }
        [rs close];
    }];
    
    return output;
}


+ (void) setUnShareFilesByUser:(UserDto *) user {
    
    FMDatabaseQueue *queue = Managers.sharedDatabase;
    
    [queue inTransaction:^(FMDatabase *db, BOOL *rollback) {
        BOOL correctQuery=NO;
        
        correctQuery = [db executeUpdate:@"UPDATE files SET shared_file_source = 0 WHERE user_id = ?", [NSNumber numberWithInteger:user.userId]];
        
        if (!correctQuery) {
            DLog(@"Error in update share file source");
        }
    }];
    
    /*for (OCSharedDto *current in listOfRemoved) {
        FMDatabaseQueue *queue;
    
     #ifdef CONTAINER_APP
     queue = [AppDelegate sharedDatabase];
     #elif FILE_PICKER
     queue = [DocumentPickerViewController sharedDatabase];
     #elif SHARE_IN
     queue = Managers.sharedDatabase;
     #else
     queue = [FileProvider sharedDatabase];
     #endif
        
        [queue inTransaction:^(FMDatabase *db, BOOL *rollback) {
            BOOL correctQuery=NO;
            
            correctQuery = [db executeUpdate:@"UPDATE files SET shared_file_source = 0 WHERE shared_file_source = ?", [NSNumber numberWithInt:current.fileSource]];
            
            if (!correctQuery) {
                DLog(@"Error in update share file source");
            }
        }];
    }*/
}


+ (FileDto *) getFileEqualWithShareDtoPath:(NSString*)path andByUser:(UserDto *) user {
    
    UserDto *mUser;
    
#ifdef CONTAINER_APP
    AppDelegate *app = (AppDelegate *)[[UIApplication sharedApplication] delegate];
    mUser = app.activeUser;
#else
    mUser = [ManageUsersDB getActiveUser];
#endif

    FMDatabaseQueue *queue = Managers.sharedDatabase;
    
    __block FileDto *output = nil;
    
    __block NSString *comparePath = nil;
    
    [queue inDatabase:^(FMDatabase *db) {
        FMResultSet *rs = [db executeQuery:@"SELECT * FROM files WHERE user_id = ?", [NSNumber numberWithInteger:user.userId]];
        while ([rs next]) {
            
            comparePath = [NSString stringWithFormat:@"/%@%@", [rs stringForColumn:@"file_path"], [rs stringForColumn:@"file_name"]];
            
            //DLog(@"path = %@ comparePath = %@", path, comparePath);
            
            if ([comparePath isEqualToString:path]) {
                
                //Store the rs file object
                output = [FileDto new];
                
                output.idFile = [rs intForColumn:@"id"];
                output.ocId = [rs stringForColumn:@"oc_id"];
                output.filePath = [NSString stringWithFormat:@"%@%@",[UtilsUrls getRemovedPartOfFilePathAnd:mUser],[rs stringForColumn:@"file_path"]];
                output.fileName = [rs stringForColumn:@"file_name"];
                output.isDirectory = [rs intForColumn:@"is_directory"];
                output.userId = [rs intForColumn:@"user_id"];
                output.isDownload = [rs intForColumn:@"is_download"];
                output.size = [rs longForColumn:@"size"];
                output.fileId = [rs intForColumn:@"file_id"];
                output.date = [rs longForColumn:@"date"];
                output.isFavorite = [rs intForColumn:@"is_favorite"];
                output.localFolder = [UtilsUrls getLocalFolderByFilePath:output.filePath andFileName:output.fileName andUserDto:mUser];
                output.etag = [rs stringForColumn:@"etag"];
                output.isRootFolder = [rs intForColumn:@"is_root_folder"];
                output.isNecessaryUpdate = [rs intForColumn:@"is_necessary_update"];
                output.sharedFileSource = [rs intForColumn:@"shared_file_source"];
                output.permissions = [rs stringForColumn:@"permissions"];
                output.taskIdentifier = [rs intForColumn:@"task_identifier"];
                output.providingFileId = [rs intForColumn:@"providing_file_id"];
                
            }
        }
        [rs close];
    }];
    
    return output;
}


+ (BOOL) isCatchedInDataBaseThisPath: (NSString*)path{
    
    //Ex: /folder1/folder1_1/folder1_1_1/folder1_1_1_1
    
    UserDto *mUser;
    
#ifdef CONTAINER_APP
    AppDelegate *app = (AppDelegate *)[[UIApplication sharedApplication] delegate];
    mUser = app.activeUser;
#else
    mUser = [ManageUsersDB getActiveUser];
#endif
    
    FMDatabaseQueue *queue = Managers.sharedDatabase;
    
    __block NSString *comparePath = nil;
    
    __block BOOL isExist = NO;
    
    [queue inDatabase:^(FMDatabase *db) {

    FMResultSet *rs = [db executeQuery:@"SELECT * FROM files WHERE user_id = ? AND is_directory = 1", [NSNumber numberWithInteger:mUser.userId]];

        while ([rs next]) {
            
            comparePath = [NSString stringWithFormat:@"%@%@", [rs stringForColumn:@"file_path"], [rs stringForColumn:@"file_name"]];
            
            // DLog(@"path is: %@ - compare path is: %@", path, comparePath);
            
            if ([path isEqualToString:comparePath]) {
                isExist = YES;
            }
            
            
        }
        [rs close];
    }];

    return isExist;
}


+ (void) setUnShareFilesOfFolder:(FileDto *) folder {
    FMDatabaseQueue *queue = Managers.sharedDatabase;
    
    [queue inTransaction:^(FMDatabase *db, BOOL *rollback) {
        BOOL correctQuery=NO;
        
        correctQuery = [db executeUpdate:@"UPDATE files SET shared_file_source = 0 WHERE file_id = ?", [NSNumber numberWithInteger:folder.idFile]];
        
        if (!correctQuery) {
            DLog(@"Error in update share file source");
        }
    }];
}

#pragma mark - Favorites method

+ (void) updateTheFileID: (NSInteger)idFile asFavorite: (BOOL) isFavorite {
    DLog(@"updateTheFavoriteFile");
    FMDatabaseQueue *queue = Managers.sharedDatabase;
    
    [queue inTransaction:^(FMDatabase *db, BOOL *rollback) {
        BOOL correctQuery=NO;
        
        correctQuery = [db executeUpdate:@"UPDATE files SET is_favorite = ? WHERE id = ?", [NSNumber numberWithInt:isFavorite], [NSNumber numberWithInteger:idFile]];
        
        if (!correctQuery) {
            DLog(@"Error in update favorite file source");
        }
    }];
}


+ (NSArray*) getAllFavoritesFilesOfUserId:(NSInteger)userId {
    
    FMDatabaseQueue *queue = Managers.sharedDatabase;
    
    NSMutableArray *tempArray = [NSMutableArray new];
    //Get the user
    UserDto *mUser = [ManageUsersDB getUserByUserId:userId];
    
    [queue inDatabase:^(FMDatabase *db) {
        FMResultSet *rs = [db executeQuery:@"SELECT * FROM files WHERE is_favorite = 1 AND user_id = ? AND is_directory = 0", [NSNumber numberWithInteger:userId]];
        while ([rs next]) {
            
            FileDto *currentFile = [[FileDto alloc] init];
            
            currentFile.idFile = [rs intForColumn:@"id"];
            currentFile.ocId = [rs stringForColumn:@"oc_id"];
            currentFile.filePath = [NSString stringWithFormat:@"%@%@",[UtilsUrls getRemovedPartOfFilePathAnd:mUser],[rs stringForColumn:@"file_path"]];
            currentFile.fileName = [rs stringForColumn:@"file_name"];
            currentFile.isDirectory = [rs intForColumn:@"is_directory"];
            currentFile.userId = [rs intForColumn:@"user_id"];
            currentFile.isDownload = [rs intForColumn:@"is_download"];
            currentFile.size = [rs longForColumn:@"size"];
            currentFile.fileId = [rs intForColumn:@"file_id"];
            currentFile.date = [rs longForColumn:@"date"];
            currentFile.etag = [rs stringForColumn:@"etag"];
            currentFile.isFavorite = [rs intForColumn:@"is_favorite"];
            currentFile.localFolder = [UtilsUrls getLocalFolderByFilePath:currentFile.filePath andFileName:currentFile.fileName andUserDto:mUser];
            currentFile.isNecessaryUpdate = [rs boolForColumn:@"is_necessary_update"];
            currentFile.sharedFileSource = [rs intForColumn:@"shared_file_source"];
            currentFile.permissions = [rs stringForColumn:@"permissions"];
            currentFile.taskIdentifier = [rs intForColumn:@"task_identifier"];
            currentFile.providingFileId = [rs intForColumn:@"providing_file_id"];
            
            [tempArray addObject:currentFile];

        }
        [rs close];
    }];
    
    NSArray *output = [NSArray arrayWithArray:tempArray];
    tempArray = nil;
    
    return output;
}


+ (NSArray*) getAllFavoritesByFolder:(FileDto *) folder {
    
    FMDatabaseQueue *queue = Managers.sharedDatabase;
    
    NSMutableArray *tempArray = [NSMutableArray new];
    //Get the user
    UserDto *mUser = [ManageUsersDB getActiveUser];
    
    [queue inDatabase:^(FMDatabase *db) {
        FMResultSet *rs = [db executeQuery:@"SELECT * FROM files WHERE is_favorite = 1 AND file_id = ?", [NSNumber numberWithInteger:folder.idFile]];
        while ([rs next]) {
            
            FileDto *currentFile = [[FileDto alloc] init];
            
            currentFile.idFile = [rs intForColumn:@"id"];
            currentFile.ocId = [rs stringForColumn:@"oc_id"];
            currentFile.filePath = [NSString stringWithFormat:@"%@%@",[UtilsUrls getRemovedPartOfFilePathAnd:mUser],[rs stringForColumn:@"file_path"]];
            currentFile.fileName = [rs stringForColumn:@"file_name"];
            currentFile.isDirectory = [rs intForColumn:@"is_directory"];
            currentFile.userId = [rs intForColumn:@"user_id"];
            currentFile.isDownload = [rs intForColumn:@"is_download"];
            currentFile.size = [rs longForColumn:@"size"];
            currentFile.fileId = [rs intForColumn:@"file_id"];
            currentFile.date = [rs longForColumn:@"date"];
            currentFile.etag = [rs stringForColumn:@"etag"];
            currentFile.isFavorite = [rs intForColumn:@"is_favorite"];
            currentFile.localFolder = [UtilsUrls getLocalFolderByFilePath:currentFile.filePath andFileName:currentFile.fileName andUserDto:mUser];
            currentFile.isNecessaryUpdate = [rs boolForColumn:@"is_necessary_update"];
            currentFile.sharedFileSource = [rs intForColumn:@"shared_file_source"];
            currentFile.permissions = [rs stringForColumn:@"permissions"];
            currentFile.taskIdentifier = [rs intForColumn:@"task_identifier"];
            currentFile.providingFileId = [rs intForColumn:@"providing_file_id"];
            
            [tempArray addObject:currentFile];
            
        }
        [rs close];
    }];
    
    NSArray *output = [NSArray arrayWithArray:tempArray];
    tempArray = nil;
    
    return output;
}


+ (void) setNoFavoritesAllFilesOfAFolder:(FileDto *) folder {
    FMDatabaseQueue *queue = Managers.sharedDatabase;
    
    [queue inTransaction:^(FMDatabase *db, BOOL *rollback) {
        BOOL correctQuery=NO;
        
        correctQuery = [db executeUpdate:@"UPDATE files SET is_favorite = 0 WHERE file_id = ?", [NSNumber numberWithInteger:folder.idFile]];
        
        if (!correctQuery) {
            DLog(@"Error in setNoFavoritesAllFilesOfAFolder");
        }
    }];
}


///-----------------------------------
/// @name getFavoriteOfPath:path andUserId:userId
///-----------------------------------

/**
 * This method return favorites files of a specific path and user
 *
 * @param path -> NSString
 * @param userId -> NSInteger
 *
 * @return NSArray
 *
 */
+(NSArray*) getFavoritesOfPath:(NSString*)path andUserId:(NSInteger)userId{
    
    FMDatabaseQueue *queue = Managers.sharedDatabase;
    
    NSMutableArray *tempArray = [NSMutableArray new];
    
    //Get the user
    UserDto *mUser = [ManageUsersDB getUserByUserId:userId];
    
    __block NSString *comparePath = nil;
    
    [queue inDatabase:^(FMDatabase *db) {
        FMResultSet *rs = [db executeQuery:@"SELECT * FROM files WHERE is_favorite = 1 AND user_id = ?", [NSNumber numberWithInteger:userId]];
        
        while ([rs next]) {
            
            comparePath = [NSString stringWithFormat:@"%@%@",[UtilsUrls getRemovedPartOfFilePathAnd:mUser],[rs stringForColumn:@"file_path"]];
            
            DLog(@"path = %@ comparePath = %@", path, comparePath);
            
            if ([comparePath isEqualToString:path]) {
                
                FileDto *currentFile = [[FileDto alloc] init];
                
                currentFile.idFile = [rs intForColumn:@"id"];
                currentFile.ocId = [rs stringForColumn:@"oc_id"];
                currentFile.filePath = [NSString stringWithFormat:@"%@%@",[UtilsUrls getRemovedPartOfFilePathAnd:mUser],[rs stringForColumn:@"file_path"]];
                currentFile.fileName = [rs stringForColumn:@"file_name"];
                currentFile.isDirectory = [rs intForColumn:@"is_directory"];
                currentFile.userId = [rs intForColumn:@"user_id"];
                currentFile.isDownload = [rs intForColumn:@"is_download"];
                currentFile.size = [rs longForColumn:@"size"];
                currentFile.fileId = [rs intForColumn:@"file_id"];
                currentFile.date = [rs longForColumn:@"date"];
                currentFile.etag = [rs stringForColumn:@"etag"];
                currentFile.isFavorite = [rs intForColumn:@"is_favorite"];
                currentFile.localFolder = [UtilsUrls getLocalFolderByFilePath:currentFile.filePath andFileName:currentFile.fileName andUserDto:mUser];
                currentFile.isNecessaryUpdate = [rs boolForColumn:@"is_necessary_update"];
                currentFile.sharedFileSource = [rs intForColumn:@"shared_file_source"];
                currentFile.permissions = [rs stringForColumn:@"permissions"];
                currentFile.taskIdentifier = [rs intForColumn:@"task_identifier"];
                currentFile.providingFileId = [rs intForColumn:@"providing_file_id"];
                
                [tempArray addObject:currentFile];
                
            }
        }
        [rs close];
    }];
    
    NSArray *output = [NSArray arrayWithArray:tempArray];
    tempArray = nil;
    
    return output;
}


+(void) deleteAlleTagOfTheDirectoties {
    
    FMDatabaseQueue *queue = Managers.sharedDatabase;
    
    [queue inTransaction:^(FMDatabase *db, BOOL *rollback) {
        BOOL correctQuery=NO;
        
        correctQuery = [db executeUpdate:@"UPDATE files SET etag = \"\" WHERE is_directory = 1"];
        
        if (!correctQuery) {
            DLog(@"Error in deleteAlleTagOfTheDirectoties");
        }
    }];
}

#pragma mark - TaskIdentifier methods

+ (void) updateFile:(NSInteger)idFile withTaskIdentifier:(NSInteger)taskIdentifier {

    FMDatabaseQueue *queue = Managers.sharedDatabase;
    
    [queue inTransaction:^(FMDatabase *db, BOOL *rollback) {
        BOOL correctQuery=NO;
        
        correctQuery = [db executeUpdate:@"UPDATE files SET task_identifier = ? WHERE id = ?", [NSNumber numberWithInteger:taskIdentifier], [NSNumber numberWithInteger:idFile]];
        
        if (!correctQuery) {
            DLog(@"Error in update task identifier file source");
        }
    }];
}

#pragma mark - Providing Files

+ (void) updateFile:(NSInteger)idFile withProvidingFile:(NSInteger)providingFileId{
   
    FMDatabaseQueue *queue = Managers.sharedDatabase;
    
    [queue inTransaction:^(FMDatabase *db, BOOL *rollback) {
        BOOL correctQuery=NO;
        
        correctQuery = [db executeUpdate:@"UPDATE files SET providing_file_id = ? WHERE id = ?", [NSNumber numberWithInteger:providingFileId], [NSNumber numberWithInteger:idFile]];
        
        if (!correctQuery) {
            DLog(@"Error in update providing file");
        }
    }];
}

+ (FileDto *) getFileDtoRelatedWithProvidingFileId:(NSInteger)providingFileId ofUser:(NSInteger)userId{
    
    FMDatabaseQueue *queue = Managers.sharedDatabase;
    
    __block FileDto *fileTemp = nil;
    
    //Get the user
    UserDto *user = [ManageUsersDB getUserByUserId:userId];
    
    [queue inDatabase:^(FMDatabase *db) {
        FMResultSet *rs = [db executeQuery:@"SELECT * FROM files WHERE providing_file_id = ?", [NSNumber numberWithInteger:providingFileId]];
        
        while ([rs next]) {
            
            fileTemp = [FileDto new];
            
            fileTemp.idFile = [rs intForColumn:@"id"];
            fileTemp.ocId = [rs stringForColumn:@"oc_id"];
            fileTemp.filePath = [NSString stringWithFormat:@"%@%@",[UtilsUrls getRemovedPartOfFilePathAnd:user],[rs stringForColumn:@"file_path"]];
            fileTemp.fileName = [rs stringForColumn:@"file_name"];
            fileTemp.isDirectory = [rs intForColumn:@"is_directory"];
            fileTemp.userId = [rs intForColumn:@"user_id"];
            fileTemp.isDownload = [rs intForColumn:@"is_download"];
            fileTemp.size = [rs longForColumn:@"size"];
            fileTemp.fileId = [rs intForColumn:@"file_id"];
            fileTemp.date = [rs longForColumn:@"date"];
            fileTemp.etag = [rs stringForColumn:@"etag"];
            fileTemp.isFavorite = [rs intForColumn:@"is_favorite"];
            fileTemp.localFolder = [UtilsUrls getLocalFolderByFilePath:fileTemp.filePath andFileName:fileTemp.fileName andUserDto:user];
            fileTemp.isNecessaryUpdate = [rs boolForColumn:@"is_necessary_update"];
            fileTemp.sharedFileSource = [rs intForColumn:@"shared_file_source"];
            fileTemp.permissions = [rs stringForColumn:@"permissions"];
            fileTemp.taskIdentifier = [rs intForColumn:@"task_identifier"];
            fileTemp.providingFileId = [rs intForColumn:@"providing_file_id"];
        
        }
        
        [rs close];
    }];
    
    return fileTemp;
}

@end
