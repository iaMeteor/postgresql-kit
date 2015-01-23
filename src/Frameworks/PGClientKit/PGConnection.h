
// Copyright 2009-2015 David Thorpe
// https://github.com/djthorpe/postgresql-kit
//
// Licensed under the Apache License, Version 2.0 (the "License"); you may not
// use this file except in compliance with the License. You may obtain a copy
// of the License at http://www.apache.org/licenses/LICENSE-2.0
//
// Unless required by applicable law or agreed to in writing, software
// distributed under the License is distributed on an "AS IS" BASIS, WITHOUT
// WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied. See the
// License for the specific language governing permissions and limitations
// under the License.

// externs
extern NSUInteger PGClientDefaultPort;
extern NSUInteger PGClientMaximumPort;
extern NSString* PGClientErrorDomain;

// forward declarations
@protocol PGConnectionDelegate;

@interface PGConnection : NSObject {
	void* _connection;
	NSLock* _lock;
	PGConnectionStatus _status;
}

////////////////////////////////////////////////////////////////////////////////
// static methods

/**
 *  Returns an array of URL schemes that can be used to connect to the remote
 *  server
 *
 *  @return An array of valid URL schemes
 */
+(NSArray* )allURLSchemes;

/**
 *  Returns the default URL scheme which can be used to connect to the remote
 *  server
 *
 *  @return The name of the default URL scheme
 */
+(NSString* )defaultURLScheme;

////////////////////////////////////////////////////////////////////////////////
// constructors

/**
 *  Create connection object and connect to remote endpoint in foreground. This
 *  is a convenience method which allocates the PGConnection object, initializes
 *  it, and connects to the remote server all at once. In general, you should
 *  perform these three steps separately.
 *
 *  @param url The endpoint for PostgreSQL server communication
 *  @param error  A pointer to an NSError object
 *
 *  @return Will return a PGConnection reference on successful connection, 
 *          or nil on failure, and return the error via the argument.
 */
+(PGConnection* )connectionWithURL:(NSURL* )url error:(NSError** )error;

////////////////////////////////////////////////////////////////////////////////
// properties

/**
 *  The currently set delegate
 */
@property (weak, nonatomic) id<PGConnectionDelegate> delegate;

/**
 *  Tag for the connection object
 */
@property NSInteger tag;

/**
 *  The currently connected user, or nil if a connection has not yet been made
 */
@property (readonly) NSString* user;

/**
 *  The currently connected database, or nil if no database has been selected
 */
@property (readonly) NSString* database;

/**
 *  The current database connection status
 */
@property (readonly) PGConnectionStatus status;

/**
 *  The current server process ID
 */
@property (readonly) int serverProcessID;

////////////////////////////////////////////////////////////////////////////////
// connection, ping and disconnection methods

-(BOOL)connectWithURL:(NSURL* )url error:(NSError** )error;
-(BOOL)connectInBackgroundWithURL:(NSURL* )url whenDone:(void(^)(NSError* error)) callback;
-(BOOL)pingWithURL:(NSURL* )url error:(NSError** )error;
-(BOOL)reset;
-(BOOL)resetInBackgroundWhenDone:(void(^)(NSError* error)) callback;
-(BOOL)disconnect;
-(BOOL)connectionUsedPassword;

////////////////////////////////////////////////////////////////////////////////
// execute statements

-(PGResult* )execute:(NSString* )query format:(PGClientTupleFormat)format error:(NSError** )error;
-(PGResult* )execute:(NSString* )query format:(PGClientTupleFormat)format values:(NSArray* )values error:(NSError** )error;
-(PGResult* )execute:(NSString* )query format:(PGClientTupleFormat)format value:(id)value error:(NSError** )error;
-(PGResult* )execute:(NSString* )query error:(NSError** )error;
-(PGResult* )execute:(NSString* )query values:(NSArray* )values error:(NSError** )error;
-(PGResult* )execute:(NSString* )query value:(id)value error:(NSError** )error;

@end

// delegate for PGConnection
@protocol PGConnectionDelegate <NSObject>
@optional
-(void)connection:(PGConnection* )connection willOpenWithParameters:(NSMutableDictionary* )dictionary;
-(void)connection:(PGConnection* )connection willExecute:(NSString* )theQuery values:(NSArray* )values;
-(void)connection:(PGConnection* )connection error:(NSError* )theError;
-(void)connection:(PGConnection* )connection statusChange:(PGConnectionStatus)status;

@end

