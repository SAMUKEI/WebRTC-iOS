/*
 * libjingle
 * Copyright 2014, Google Inc.
 *
 * Redistribution and use in source and binary forms, with or without
 * modification, are permitted provided that the following conditions are met:
 *
 *  1. Redistributions of source code must retain the above copyright notice,
 *     this list of conditions and the following disclaimer.
 *  2. Redistributions in binary form must reproduce the above copyright notice,
 *     this list of conditions and the following disclaimer in the documentation
 *     and/or other materials provided with the distribution.
 *  3. The name of the author may not be used to endorse or promote products
 *     derived from this software without specific prior written permission.
 *
 * THIS SOFTWARE IS PROVIDED BY THE AUTHOR ``AS IS'' AND ANY EXPRESS OR IMPLIED
 * WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE IMPLIED WARRANTIES OF
 * MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE ARE DISCLAIMED. IN NO
 * EVENT SHALL THE AUTHOR BE LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL,
 * SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT LIMITED TO,
 * PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES; LOSS OF USE, DATA, OR PROFITS;
 * OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND ON ANY THEORY OF LIABILITY,
 * WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT (INCLUDING NEGLIGENCE OR
 * OTHERWISE) ARISING IN ANY WAY OUT OF THE USE OF THIS SOFTWARE, EVEN IF
 * ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
 */

#import "ARDUtilities.h"

@implementation NSDictionary (ARDUtilites)

+ (NSDictionary *)dictionaryWithJSONString:(NSString *)jsonString {
    NSParameterAssert(jsonString.length > 0);
    NSData *data = [jsonString dataUsingEncoding:NSUTF8StringEncoding];
    NSError *error = nil;
    NSDictionary *dict =
    [NSJSONSerialization JSONObjectWithData:data options:0 error:&error];
    if (error) {
        NSLog(@"Error parsing JSON: %@", error.localizedDescription);
    }
    return dict;
}

+ (NSDictionary *)dictionaryWithJSONData:(NSData *)jsonData {
    NSError *error = nil;
    NSDictionary *dict =
    [NSJSONSerialization JSONObjectWithData:jsonData options:0 error:&error];
    if (error) {
        NSLog(@"Error parsing JSON: %@", error.localizedDescription);
    }
    return dict;
}

@end

@implementation NSURLConnection (ARDUtilities)

+ (void)sendAsyncRequest:(NSURLRequest *)request
       completionHandler:(void (^)(NSURLResponse *response,
                                   NSData *data,
                                   NSError *error))completionHandler {
    // Kick off an async request which will call back on main thread.
    [NSURLConnection sendAsynchronousRequest:request
                                       queue:[NSOperationQueue mainQueue]
                           completionHandler:^(NSURLResponse *response,
                                               NSData *data,
                                               NSError *error) {
                               if (completionHandler) {
                                   completionHandler(response, data, error);
                               }
                           }];
}

// Posts data to the specified URL.
+ (void)sendAsyncPostToURL:(NSURL *)url
                  withData:(NSData *)data
         completionHandler:(void (^)(BOOL succeeded,
                                     NSData *data))completionHandler {
    NSMutableURLRequest *request = [NSMutableURLRequest requestWithURL:url];
    request.HTTPMethod = @"POST";
    request.HTTPBody = data;
    [[self class] sendAsyncRequest:request
                 completionHandler:^(NSURLResponse *response,
                                     NSData *data,
                                     NSError *error) {
                     if (error) {
                         NSLog(@"Error posting data: %@", error.localizedDescription);
                         if (completionHandler) {
                             completionHandler(NO, data);
                         }
                         return;
                     }
                     NSHTTPURLResponse *httpResponse = (NSHTTPURLResponse *)response;
                     if (httpResponse.statusCode != 200) {
                         NSString *serverResponse = data.length > 0 ?
                         [[NSString alloc] initWithData:data encoding:NSUTF8StringEncoding] :
                         nil;
                         NSLog(@"Received bad response: %@", serverResponse);
                         if (completionHandler) {
                             completionHandler(NO, data);
                         }
                         return;
                     }
                     if (completionHandler) {
                         completionHandler(YES, data);
                     }
                 }];
}

@end
