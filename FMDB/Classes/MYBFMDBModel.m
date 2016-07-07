//
//  MYBFMDBModel.m
//  FMDB
//
//  Created by 王向召 on 16/7/6.
//  Copyright © 2016年 王向召. All rights reserved.
//

#import "MYBFMDBModel.h"
#import <objc/runtime.h>

static NSString * const DATE_FORMAT = @"yyyy-MM-dd'T'HH:mm:ss.SSSZ";
static NSString * const LOCALE_IDENTIFIER = @"zh_CN";
static NSString * const SQL_DATABASE = @"MEIYEBANG";


@implementation MYBFMDBModel


#pragma mark - save or update

- (BOOL)saveOrUpdateInTransaction:(BOOL)inTransaction db:(FMDatabase *)db {
    id primaryValue = [self valueForKey:PRIMARY_KEY];
    if (![self.class findByCode:primaryValue]) {
        return [self saveInTransaction:inTransaction db:db];
    }
    return [self updateInTransaction:inTransaction db:db];
}

- (BOOL)saveOrUpdateByColumnName:(NSString*)columnName AndColumnValue:(NSString*)columnValue {
    id record = [self.class findFirstByCriteria:[NSString stringWithFormat:@"where %@ = %@",columnName,columnValue]];
    if (record) {
        id primaryValue = [record valueForKey:PRIMARY_KEY];
        if ([[self.class string:primaryValue] length] == 0) {
            return [self saveInTransaction:YES db:nil];
        } else {
            self.code = primaryValue;
            return [self updateInTransaction:YES db:nil];
        }
    } else {
        return [self saveInTransaction:YES db:nil];
    }
}

+ (BOOL)saveOrUpdateObjects:(NSArray *)array {
    
    if (![self.class checkResultOfTheSaveOrUpdateData:array]) return NO;
    __block BOOL res = YES;
    // 如果要支持事务
    [[FMDatabaseQueue databaseQueueWithPath:self.class.dbPath] inTransaction:^(FMDatabase *db, BOOL *rollback) {
        for (MYBFMDBModel *model in array) {
            [model initConfig];
            NSString *tableName = NSStringFromClass(model.class);
            NSString *primaryValue = [model valueForKey:PRIMARY_KEY];
            NSString *sql = [NSString stringWithFormat:@"SELECT * FROM %@ %@",tableName,[NSString stringWithFormat:@"WHERE %@='%@'",PRIMARY_KEY,primaryValue]];
            FMResultSet *resultSet = [db executeQuery:sql];
            sql = @"";
            NSArray *values = @[];
            BOOL flag = NO;
            if ([resultSet next]) {
                [model updateSql:&sql values:&values];
                flag = [db executeUpdate:sql withArgumentsInArray:values];
            } else {
                [model insertSql:&sql values:&values];
                flag = [db executeUpdate:sql withArgumentsInArray:values];
            }
            NSLog(flag ? @"成功" : @"失败");
            if (!flag) {
                res = NO;
                *rollback = YES;
                return;
            }
        }
    }];
    return res;
}


#pragma mark - save

- (BOOL)saveInTransaction:(BOOL)inTransaction db:(FMDatabase *)db1 {
    __block BOOL res = NO;
    NSString *sql= @"";
    NSArray *insertValues = @[];
    [self insertSql:&sql values:&insertValues];
    if (inTransaction) {
        [[FMDatabaseQueue databaseQueueWithPath:[[self class] dbPath]] inDatabase:^(FMDatabase *db) {
            res = [db executeUpdate:sql withArgumentsInArray:insertValues];
        }];
    } else {
        res = [db1 executeUpdate:sql withArgumentsInArray:insertValues];
    }
    NSLog(res ? @"插入成功" : @"插入失败");
    
    return res;
}

/** 批量保存用户对象 */
+ (BOOL)saveObjects:(NSArray *)array {
    if (![self.class checkResultOfTheSaveOrUpdateData:array]) {
        return NO;
    }
    __block BOOL res = YES;
    [[FMDatabaseQueue databaseQueueWithPath:self.class.dbPath] inTransaction:^(FMDatabase *db, BOOL *rollback) {
        for (MYBFMDBModel *model in array) {
            NSString *sql= @"";
            NSArray *insertValues = @[];
            [model insertSql:&sql values:&insertValues];
            BOOL flag = [db executeUpdate:sql withArgumentsInArray:insertValues];
            NSLog(flag ? @"插入成功" : @"插入失败");
            if (!flag) {
                res = NO;
                *rollback = YES;
                return;
            }
        }
    }];
    return res;
}

- (void)insertSql:(NSString **)sql values:(NSArray **)values {
    [self initConfig];
    NSString *tableName = NSStringFromClass(self.class);
    NSMutableString *keyString = [NSMutableString string];
    NSMutableString *valueString = [NSMutableString string];
    NSMutableArray *insertValues = [NSMutableArray  array];
    self.code = self.code ? self.code : [NSString stringWithFormat:@"CODE%@",[[self class] format:[NSDate date]]];
    for (int i = 0; i < self.columeNames.count; i++) {
        NSString *proname = [self.columeNames objectAtIndex:i];
        [keyString appendFormat:@"%@,", proname];
        [valueString appendString:@"?,"];
        id value = [self valueForKey:proname];
        NSString *type = self.columeTypes[i];
        if ([type isEqualToString:SQLDATE]) {
            value = [self.class format:value];
        }
        if (!value) value = @"";
        
        [insertValues addObject:value];
    }
    
    [keyString deleteCharactersInRange:NSMakeRange(keyString.length - 1, 1)];
    [valueString deleteCharactersInRange:NSMakeRange(valueString.length - 1, 1)];
    *sql = [NSString stringWithFormat:@"INSERT INTO %@(%@) VALUES (%@);", tableName, keyString, valueString];
    *values = insertValues;
}



#pragma mark - update

- (BOOL)updateInTransaction:(BOOL)inTransaction db:(FMDatabase *)db1 {
    __block BOOL res = NO;
    NSString *sql = @"";
    NSArray *updateValues = @[];
    [self updateSql:&sql values:&updateValues];
    if (!inTransaction) {
        res = [db1 executeUpdate:sql withArgumentsInArray:updateValues];
    } else {
        [[FMDatabaseQueue databaseQueueWithPath:self.class.dbPath] inDatabase:^(FMDatabase *db) {
            res = [db executeUpdate:sql withArgumentsInArray:updateValues];
        }];
    }
    NSLog(res ? @"更新成功" : @"更新失败");
    return res;
}

+ (BOOL)updateObjects:(NSArray *)array {
    if (![self.class checkResultOfTheSaveOrUpdateData:array]) {
        return NO;
    }
    __block BOOL res = YES;
    [[FMDatabaseQueue databaseQueueWithPath:self.class.dbPath] inTransaction:^(FMDatabase *db, BOOL *rollback) {
        for (MYBFMDBModel *model in array) {
            NSString *sql = @"";
            NSArray *updateValues = @[];
            [model updateSql:&sql values:&updateValues];
            BOOL flag = [db executeUpdate:sql withArgumentsInArray:updateValues];
            NSLog(flag ? @"更新成功" : @"更新失败");
            if (!flag) {
                res = NO;
                *rollback = YES;
                return;
            }
        }
    }];
    
    return res;
}

- (void)updateSql:(NSString **)sql values:(NSArray **)vaules {
    [self initConfig];
    NSString *tableName = NSStringFromClass(self.class);
    id primaryValue = [self valueForKey:PRIMARY_KEY];
    NSMutableString *keyString = [NSMutableString string];
    NSMutableArray *updateValues = [NSMutableArray  array];
    for (int i = 0; i < self.columeNames.count; i++) {
        NSString *proname = [self.columeNames objectAtIndex:i];
        if ([proname isEqualToString:PRIMARY_KEY]) continue;
        [keyString appendFormat:@" %@=?,", proname];
        id value = [self valueForKey:proname];
        NSString *type = self.columeTypes[i];
        if ([type isEqualToString:SQLDATE]) {
            value = [self.class format:value];
        }
        if (!value) value = @"";
        [updateValues addObject:value];
    }
    //删除最后那个逗号
    [keyString deleteCharactersInRange:NSMakeRange(keyString.length - 1, 1)];
    *sql = [NSString stringWithFormat:@"UPDATE %@ SET %@ WHERE %@ = ?;", tableName, keyString, PRIMARY_KEY];
    [updateValues addObject:primaryValue];
    *vaules = updateValues;
}



#pragma mark - delete

- (BOOL)deleteObjectInTransaction:(BOOL)inTransaction db:(FMDatabase *)db1 {
    __block BOOL res = NO;
    NSString *tableName = NSStringFromClass(self.class);
    id primaryValue = [self valueForKey:PRIMARY_KEY];
    NSString *sql = [NSString stringWithFormat:@"DELETE FROM %@ WHERE %@ = ?",tableName,PRIMARY_KEY];
    if (inTransaction) {
        [[FMDatabaseQueue databaseQueueWithPath:[[self class] dbPath]] inDatabase:^(FMDatabase *db) {
            res = [db executeUpdate:sql withArgumentsInArray:@[primaryValue]];
        }];
    } else {
        res = [db1 executeUpdate:sql withArgumentsInArray:@[primaryValue]];
    }
    NSLog(res ? @"删除成功": @"删除失败");
    return res;
}

+ (BOOL)deleteObjects:(NSArray *)array {
    __block BOOL res = YES;
    [[FMDatabaseQueue databaseQueueWithPath:[[self class] dbPath]] inTransaction:^(FMDatabase *db, BOOL *rollback) {
        for (MYBFMDBModel *model in array) {
            BOOL flag = [model deleteObjectInTransaction:NO db:db];
            if (!flag) {
                res = NO;
                *rollback = YES;
                return;
            }
        }
    }];
    
    return res;
}


#pragma mark - find

+ (instancetype)findByCode:(NSString *)code {
    NSString *condition = [NSString stringWithFormat:@"WHERE %@='%@'",PRIMARY_KEY,code];
    return [self.class findFirstByCriteria:condition];
}

/** 查询全部数据 */
+ (NSArray *)findAll {
    return [self.class findByCriteria:nil];
}

/** 查找某条数据 */
+ (instancetype)findFirstByCriteria:(NSString *)criteria {
    NSArray *results = [self.class findByCriteria:criteria];
    if (results.count < 1) return nil;
    return [results firstObject];
}

/** 通过条件查找数据 */
+ (NSArray *)findByCriteria:(NSString *)criteria {
    __block NSArray *results = nil;
    [[FMDatabaseQueue databaseQueueWithPath:self.class.dbPath] inDatabase:^(FMDatabase *db) {
        NSString *sql = @"";
        NSString *tableName = NSStringFromClass(self.class);
        if (criteria.length > 0) {
            sql = [NSString stringWithFormat:@"SELECT * FROM %@ %@",tableName,criteria];
        } else {
            sql = [NSString stringWithFormat:@"SELECT * FROM %@",tableName];
        }
        results = [self.class executeFind:^FMResultSet *{
            return [db executeQuery:sql];
        }];
    }];
    
    return results;
}

+ (instancetype)findMaxByPropertyName:(NSString *)propertyName criteria:(NSString *)criteria {
    __block NSArray *results = nil;
    NSString *sql = @"";
    NSString *tableName = NSStringFromClass(self.class);
    if (criteria.length > 0) {
        sql = [NSString stringWithFormat:@"SELECT * FROM %@ WHERE %@ = (SELECT MAX(%@) FROM %@ %@)",tableName,propertyName,propertyName,tableName,criteria];
    } else {
        sql = [NSString stringWithFormat:@"SELECT * FROM %@ WHERE %@ = (SELECT MAX(%@) FROM %@)",tableName,propertyName,propertyName,tableName];
    }
    [[FMDatabaseQueue databaseQueueWithPath:self.class.dbPath] inDatabase:^(FMDatabase *db) {
        results = [self.class executeFind:^FMResultSet *{
            return [db executeQuery:sql];
        }];
    }];
    return results.firstObject;
}

+ (NSArray *)executeFind:(FMResultSet *(^)())execute {
    NSMutableArray *users = [NSMutableArray array];
    FMResultSet *resultSet;
    if (execute) {
        resultSet = execute();
    }
    while ([resultSet next]) {
        MYBFMDBModel *model = [[self.class alloc] init];
        for (int i=0; i< model.columeNames.count; i++) {
            NSString *columeName = [model.columeNames objectAtIndex:i];
            NSString *columeType = [model.columeTypes objectAtIndex:i];
            if ([columeType isEqualToString:SQLTEXT]) {
                [model setValue:[resultSet stringForColumn:columeName] forKey:columeName];
            } else if ([columeType isEqualToString:SQLDATE]) {
                NSDate *date = [[self class] parse:[resultSet stringForColumn:columeName]];
                [model setValue:date ? date : @"" forKey:columeName];
            } else {
                [model setValue:[NSNumber numberWithLongLong:[resultSet longLongIntForColumn:columeName]] forKey:columeName];
            }
        }
        [users addObject:model];
        FMDBRelease(model);
    }
    return users;
}


#pragma mark - table operation

/**
 * 创建表
 * 如果已经创建，返回YES
 */
+ (BOOL)createTable {
    __block BOOL res = YES;
    [[FMDatabaseQueue databaseQueueWithPath:[[self class] dbPath]] inTransaction:^(FMDatabase *db, BOOL *rollback) {
        NSString *tableName = NSStringFromClass(self.class);
        NSString *columeAndType = [self.class getColumeAndTypeString];
        NSString *sql = [NSString stringWithFormat:@"CREATE TABLE IF NOT EXISTS %@(%@);",tableName,columeAndType];
        if (![db executeUpdate:sql]) {
            res = NO;
            *rollback = YES;
            return;
        };
        
        NSMutableArray *columns = [NSMutableArray array];
        FMResultSet *resultSet = [db getTableSchema:tableName];
        while ([resultSet next]) {
            NSString *column = [resultSet stringForColumn:@"name"];
            [columns addObject:column];
        }
        NSDictionary *dict = [self.class getAllProperties];
        NSArray *properties = [dict objectForKey:@"name"];
        NSPredicate *filterPredicate = [NSPredicate predicateWithFormat:@"NOT (SELF IN %@)",columns];
        //过滤数组
        NSArray *resultArray = [properties filteredArrayUsingPredicate:filterPredicate];
        for (NSString *column in resultArray) {
            NSUInteger index = [properties indexOfObject:column];
            NSString *proType = [[dict objectForKey:@"type"] objectAtIndex:index];
            NSString *fieldSql = [NSString stringWithFormat:@"%@ %@",column,proType];
            NSString *sql = [NSString stringWithFormat:@"ALTER TABLE %@ ADD COLUMN %@ ",NSStringFromClass(self.class),fieldSql];
            if (![db executeUpdate:sql]) {
                res = NO;
                *rollback = YES;
                return ;
            }
        }
    }];
    return res;
}

/** 清空表 */
+ (BOOL)clearTable {
    __block BOOL res = NO;
    [[FMDatabaseQueue databaseQueueWithPath:[[self class] dbPath]] inDatabase:^(FMDatabase *db) {
        NSString *tableName = NSStringFromClass(self.class);
        NSString *sql = [NSString stringWithFormat:@"DELETE FROM %@",tableName];
        res = [db executeUpdate:sql];
        NSLog(res ? @"清空成功" : @"清空失败");
    }];
    return res;
}

+ (NSString *)dbPath {
    NSString *docsdir = [NSSearchPathForDirectoriesInDomains( NSDocumentDirectory, NSUserDomainMask, YES) lastObject];
    NSFileManager *filemanage = [NSFileManager defaultManager];
    docsdir = [docsdir stringByAppendingPathComponent:SQL_DATABASE];
    BOOL isDir;
    BOOL exit =[filemanage fileExistsAtPath:docsdir isDirectory:&isDir];
    if (!exit || !isDir) {
        [filemanage createDirectoryAtPath:docsdir withIntermediateDirectories:YES attributes:nil error:nil];
    }
    NSString *dbpath = [docsdir stringByAppendingPathComponent:[NSString stringWithFormat:@"%@.sqlite",SQL_DATABASE]];
    return dbpath;
}


#pragma mark - 私有 util

+ (BOOL)checkResultOfTheSaveOrUpdateData:(NSArray *)data {
    for (MYBFMDBModel *model in data) {
        if (![model isKindOfClass:[MYBFMDBModel class]]) {
            return NO;
        }
    }
    return YES;
}

/** 获取所有属性，包含主键pk */
+ (NSDictionary *)getAllProperties {
    NSDictionary *dict = [self.class getPropertys];
    NSMutableArray *proNames = [NSMutableArray array];
    NSMutableArray *proTypes = [NSMutableArray array];
    [proNames addObject:PRIMARY_KEY];
    [proTypes addObject:[NSString stringWithFormat:@"%@",SQLTEXT]];
    [proNames addObjectsFromArray:[dict objectForKey:@"name"]];
    [proTypes addObjectsFromArray:[dict objectForKey:@"type"]];
    return [NSDictionary dictionaryWithObjectsAndKeys:proNames,@"name",proTypes,@"type",nil];
}

/**
 *  获取该类的所有属性
 */
+ (NSDictionary *)getPropertys {
    NSMutableArray *proNames = [NSMutableArray array];
    NSMutableArray *proTypes = [NSMutableArray array];
    NSArray *theTransients = [[self class] transients];
    unsigned int outCount, i;
    objc_property_t *properties = class_copyPropertyList([self class], &outCount);
    for (i = 0; i < outCount; i++) {
        objc_property_t property = properties[i];
        //获取属性名
        NSString *propertyName = [NSString stringWithCString:property_getName(property) encoding:NSUTF8StringEncoding];
        if ([theTransients containsObject:propertyName]) {
            continue;
        }
        [proNames addObject:propertyName];
        //获取属性类型等参数
        NSString *propertyType = [NSString stringWithCString: property_getAttributes(property) encoding:NSUTF8StringEncoding];
        if ([propertyType hasPrefix:@"T@"]) {
            if ([propertyType rangeOfString:@"NSDate"].location != NSNotFound) {
                [proTypes addObject:SQLDATE];
            } else {
                [proTypes addObject:SQLTEXT];
            }
        } else if ([propertyType hasPrefix:@"Ti"]||[propertyType hasPrefix:@"TI"]||[propertyType hasPrefix:@"Ts"]||[propertyType hasPrefix:@"TS"]||[propertyType hasPrefix:@"TB"]||[propertyType hasPrefix:@"Tq"]||[propertyType hasPrefix:@"TQ"]) {
            [proTypes addObject:SQLINTEGER];
        } else {
            [proTypes addObject:SQLREAL];
        }
    }
    free(properties);
    
    return [NSDictionary dictionaryWithObjectsAndKeys:proNames,@"name",proTypes,@"type",nil];
}

+ (NSString *)getColumeAndTypeString {
    NSMutableString* pars = [NSMutableString string];
    NSDictionary *dict = [self.class getAllProperties];
    NSMutableArray *proNames = [dict objectForKey:@"name"];
    NSMutableArray *proTypes = [dict objectForKey:@"type"];
    for (int i=0; i< proNames.count; i++) {
        [pars appendFormat:@"%@ %@",[proNames objectAtIndex:i],[proTypes objectAtIndex:i]];
        if(i+1 != proNames.count)
        {
            [pars appendString:@","];
        }
    }
    return pars;
}

+ (NSString *)format:(NSDate *)date {
    if (!date) return @"";
    NSDateFormatter *formatter =[[NSDateFormatter alloc] init];
    [formatter setLocale:[[NSLocale alloc] initWithLocaleIdentifier:LOCALE_IDENTIFIER]];
    formatter.dateFormat = DATE_FORMAT;
    return [formatter stringFromDate:date];
}

+ (NSDate *)parse:(NSString *)source {
    NSDateFormatter *formatter =[[NSDateFormatter alloc] init];
    [formatter setLocale:[[NSLocale alloc] initWithLocaleIdentifier:LOCALE_IDENTIFIER]];
    formatter.dateFormat = DATE_FORMAT;
    return [formatter dateFromString:[self string:source]];
}

+ (NSString *)string:(NSString *)string {
    if (![string isKindOfClass:[NSString class]]) return @"";
    return string;
}

#pragma mark - override method

+ (void)initialize {
    if (self != [MYBFMDBModel self]) {
        [self createTable];
    }
}

- (instancetype)init {
    self = [super init];
    if (self) {
        [self initConfig];
    }
    
    return self;
}

- (void)initConfig {
    if (!_columeNames) {
        NSDictionary *dic = [self.class getAllProperties];
        _columeNames = [[NSMutableArray alloc] initWithArray:[dic objectForKey:@"name"]];
        _columeTypes = [[NSMutableArray alloc] initWithArray:[dic objectForKey:@"type"]];
    }
}

- (NSString *)description {
    NSString *result = @"";
    NSDictionary *dict = [self.class getAllProperties];
    NSMutableArray *proNames = [dict objectForKey:@"name"];
    for (int i = 0; i < proNames.count; i++) {
        NSString *proName = [proNames objectAtIndex:i];
        id  proValue = [self valueForKey:proName];
        result = [result stringByAppendingFormat:@"%@:%@\n",proName,proValue];
    }
    return result;
}

#pragma mark - must be override method

/** 如果子类中有一些property不需要创建数据库字段，那么这个方法必须在子类中重写
 */
+ (NSArray *)transients {
    return [NSArray array];
}

@end

NSString * const SQLTEXT = @"TEXT";
NSString * const SQLDATE = @"DATE";
NSString * const SQLINTEGER = @"INTEGER";
NSString * const SQLREAL = @"REAL";
NSString * const SQLBLOB = @"BLOB";
NSString * const SQLNULL = @"NULL";
NSString * const PRIMARY_KEY = @"code";
