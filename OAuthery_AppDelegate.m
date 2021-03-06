//
//  OAuthery_AppDelegate.m
//  OAuthery
//
//  Licensed under the Apache License, Version 2.0 (the "License");
//  you may not use this file except in compliance with the License.
//  You may obtain a copy of the License at
//
//  http://www.apache.org/licenses/LICENSE-2.0
//
//  Unless required by applicable law or agreed to in writing, software
//  distributed under the License is distributed on an "AS IS" BASIS,
//  WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
//  See the License for the specific language governing permissions and
//  limitations under the License.
//

#import "OAuthery_AppDelegate.h"

@implementation OAuthery_AppDelegate

@synthesize window;
@synthesize consumerKeyField, consumerSecretField;

-(OAConsumer *)consumer{
	return [[[OAConsumer alloc] initWithKey:[consumerKeyField stringValue]
									 secret:[consumerSecretField stringValue]] autorelease];
}

/**
 Returns the support directory for the application, used to store the Core Data
 store file.  This code uses a directory named "OAuthery" for
 the content, either in the NSApplicationSupportDirectory location or (if the
 former cannot be found), the system's temporary directory.
 */

- (NSString *)applicationSupportDirectory {
	
    NSArray *paths = NSSearchPathForDirectoriesInDomains(NSApplicationSupportDirectory, NSUserDomainMask, YES);
    NSString *basePath = ([paths count] > 0) ? [paths objectAtIndex:0] : NSTemporaryDirectory();
    return [basePath stringByAppendingPathComponent:@"OAuthery"];
}

/**
 Implementation of dealloc, to release the retained variables.
 */

- (void)dealloc {
	
    [window release];
	
    [super dealloc];
}

#pragma mark 1. Get Request Token

-(IBAction)getRequestToken:sender{
	if(consumer){
		[consumer release];
		consumer = nil;
	}
	
	consumer = [[self consumer] retain];
	
	NSURL *url = [NSURL URLWithString:@"https://twitter.com/oauth/request_token"];
	
	OAMutableURLRequest *request = [[OAMutableURLRequest alloc] initWithURL:url
																   consumer:consumer
																	  token:[[[SSToken alloc] init] autorelease]   // we don't have a Token yet
																	  realm:nil   // our service provider doesn't specify a realm
														  signatureProvider:nil]; // use the default method, HMAC-SHA1	
	
	[request setHTTPMethod:@"GET"];
	
	OADataFetcher *fetcher = [[OADataFetcher alloc] init];
	
	[fetcher fetchDataWithRequest:request
						 delegate:self
				didFinishSelector:@selector(requestTokenTicket:didFinishWithData:)
				  didFailSelector:@selector(requestTokenTicket:didFailWithError:)];
	
	[fetcher autorelease];
}

#pragma mark 2. Finished loading Request Token

- (void)requestTokenTicket:(OAServiceTicket *)ticket didFailWithError:(NSError *)error{
	if(!ticket.didSucceed){
		NSLog(@"Failed to get request ticket: %@",error);
	}
}

- (void)requestTokenTicket:(OAServiceTicket *)ticket didFinishWithData:(NSData *)data {
	NSLog(@"Finished");
	if (ticket.didSucceed) {
		NSString *responseBody = [[NSString alloc] initWithData:data
													   encoding:NSUTF8StringEncoding];
		[self authorizeWithRequestToken:[[[SSToken alloc] initWithHTTPResponseBody:responseBody] autorelease]];
	}
}

#pragma mark 3. Authorize from Request Token

-(void)authorizeWithRequestToken:(SSToken *)token{
	[requestToken autorelease];
	requestToken = [token retain];
	
	[requestTokenField setStringValue:[requestToken key]];
	
	NSURL *authorizeURL = [NSURL URLWithString:[NSString stringWithFormat:@"https://twitter.com/oauth/authorize?oauth_token=%@",[requestToken key]]];
	
	[[NSWorkspace sharedWorkspace] openURL:authorizeURL];
}

#pragma mark 4. Get Access Token from Reuest Token + PIN

-(IBAction)getAccessToken:sender{
	[requestToken setPin:[pinNumberField stringValue]];
	
    NSURL *url = [NSURL URLWithString:@"https://twitter.com/oauth/access_token"];
	
    OAMutableURLRequest *request = [[OAMutableURLRequest alloc] initWithURL:url
                                                                   consumer:consumer
                                                                      token:requestToken   // we don't have a Token yet
                                                                      realm:nil   // our service provider doesn't specify a realm
                                                          signatureProvider:nil]; // use the default method, HMAC-SHA1
	
    [request setHTTPMethod:@"GET"];
	
	
    OADataFetcher *fetcher = [[OADataFetcher alloc] init];
	
    [fetcher fetchDataWithRequest:request
                         delegate:self
                didFinishSelector:@selector(accessTokenTicket:didFinishWithData:)
                  didFailSelector:@selector(accessTokenTicket:didFailWithError:)];
	
	[fetcher autorelease];	
}

#pragma mark 5. Finished loading Access Token

- (void)accessTokenTicket:(OAServiceTicket *)ticket didFailWithError:(NSError *)error{
	if(!ticket.didSucceed){
		NSLog(@"Failed to get access ticket: %@",error);
	}
}

- (void)accessTokenTicket:(OAServiceTicket *)ticket didFinishWithData:(NSData *)data {
	if (ticket.didSucceed) {
		NSString *responseBody = [[NSString alloc] initWithData:data
													   encoding:NSUTF8StringEncoding];
		
		accessToken = [[SSToken alloc] initWithHTTPResponseBody:responseBody];
		[accessKeyField setStringValue:[accessToken key]];
		[accessSecretField setStringValue:[accessToken secret]];
		
		[screenNameField setStringValue:[accessToken screenName]];
		[userIDField setStringValue:[[NSNumber numberWithLongLong:[accessToken userID]] stringValue]];
	}
}

@end
