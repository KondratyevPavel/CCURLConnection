//
//  CCDefaultQueryEncoder.m
//  CCURLConnection
//
//  Created by Kondratyev, Pavel on 3/19/14.
//
//

#import "CCDefaultQueryEncoder.h"
#import "CCFilePostParameter.h"
#import "NSString+EncodeURLParameter.h"
#import "CCURLConnection.h"

@interface CCDefaultQueryEncoder ()

- (BOOL)encodeParameter:(NSString *)prefix object:(id)object to:(NSMutableArray *)parameters error:(NSError **)error;

@end

@implementation CCDefaultQueryEncoder

static CCDefaultQueryEncoder *_encoder;

+ (void)initialize
{
    if (self == [CCDefaultQueryEncoder class]) {
        _encoder = [self new];
    }
}

+ (instancetype)sharedEncoder
{
    return _encoder;
}

- (BOOL)encodeParameter:(NSString *)prefix object:(id)object to:(NSMutableArray *)parameters error:(NSError **)error
{
    __block BOOL fail = NO;
    if ([object respondsToSelector:@selector(enumerateKeysAndObjectsUsingBlock:)]) {
        __block NSError *err;
        [object enumerateKeysAndObjectsUsingBlock:^(id key, id obj, BOOL *stop) {
            *stop = fail = [self encodeParameter:(prefix.length
                                                ? [NSString stringWithFormat:@"%@[%@]", prefix, key]
                                                : key) object:obj to:parameters error:&err];
        }];
        if (error) {
            *error = err;
        }
    } else if ([object respondsToSelector:@selector(enumerateObjectsUsingBlock:)]) {
        __block NSError *err;
        [object enumerateObjectsUsingBlock:^(id obj, NSUInteger unused, BOOL *stop) {
            *stop = fail = [self encodeParameter:[NSString stringWithFormat:@"%@[]", prefix] object:obj to:parameters error:&err];
        }];
        if (error) {
            *error = err;
        }
    } else if ([object isKindOfClass:[NSNull class]]) {
        [parameters addObject:[NSString stringWithFormat:@"%@=", prefix]];
    } else if ([object isKindOfClass:[CCFilePostParameter class]]) {
        if (error) {
            *error = [NSError errorWithDomain:CCREQUEST_BUILDER_ERROR_DOMAIN code:CCRequestBuilderErrorInvalidParameter userInfo:nil];
        }
        fail = YES;
    } else {
        [parameters addObject:[NSString stringWithFormat:@"%@=%@", prefix, [[object description] encodedURLParameter]]];
    }
    return fail;
}

#pragma mark - QueryEncoder

- (NSArray *)queryParametersWithObject:(id)object error:(NSError **)error
{
    NSMutableArray *result = [NSMutableArray array];
    return ([self encodeParameter:nil object:object to:result error:error] ? nil : result);
}

@end
