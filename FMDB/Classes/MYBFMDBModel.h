//
//  MYBFMDBModel.h
//  FMDB
//
//  Created by 王向召 on 16/7/6.
//  Copyright © 2016年 王向召. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "FMDB.h"

@interface MYBFMDBModel : NSObject

//主键
@property (nonatomic, copy) NSString *code;
/** 列名 */
@property (retain, readonly, nonatomic) NSMutableArray *columeNames;
/** 列类型 */
@property (retain, readonly, nonatomic) NSMutableArray *columeTypes;

- (BOOL)saveOrUpdateInTransaction:(BOOL)inTransaction db:(FMDatabase *)db;
+ (BOOL)saveOrUpdateObjects:(NSArray *)array;

- (BOOL)saveInTransaction:(BOOL)inTransaction db:(FMDatabase *)db;
+ (BOOL)saveObjects:(NSArray *)array;

- (BOOL)updateInTransaction:(BOOL)inTransaction db:(FMDatabase *)db;
+ (BOOL)updateObjects:(NSArray *)array;

- (BOOL)deleteObjectInTransaction:(BOOL)inTransaction db:(FMDatabase *)db1;
+ (BOOL)deleteObjects:(NSArray *)array;

+ (instancetype)findByCode:(NSString *)code;
+ (NSArray *)findAll;
+ (instancetype)findFirstByCriteria:(NSString *)criteria;
+ (NSArray *)findByCriteria:(NSString *)criteria;
+ (instancetype)findMaxByPropertyName:(NSString *)propertyName criteria:(NSString *)criteria;

+ (BOOL)clearTable;

//忽略属性
+ (NSArray *)transients;

@end


extern NSString * const SQLTEXT;
extern NSString * const SQLDATE;
extern NSString * const SQLINTEGER;
extern NSString * const SQLREAL;
extern NSString * const SQLBLOB;
extern NSString * const SQLNULL;
extern NSString * const PRIMARY_KEY;
