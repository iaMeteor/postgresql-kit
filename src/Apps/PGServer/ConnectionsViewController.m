
#import "ConnectionsViewController.h"
#import <PGClientKit/PGClientKit.h>

@implementation ConnectionsViewController

////////////////////////////////////////////////////////////////////////////////
// properties

-(NSString* )nibName {
	return @"ConnectionsView";
}

-(NSString* )identifier {
	return @"connections";
}

-(PGConnection* )connection {
	return [[self delegate] connection];
}

////////////////////////////////////////////////////////////////////////////////
// private methods

-(void)_startConnectionsTimer {
	PGConnection* connection = [self connection];
	if([connection status] != PGConnectionStatusConnected) {
#ifdef DEBUG
		NSLog(@"_startConnectionsTimer: Unable to start timer, connection is not in a good state");
#endif
		return;
	}
	
	// stop the timer if there's one running
	[self _stopConnectionsTimer];

	// fire the timer
	[self setTimer:[NSTimer scheduledTimerWithTimeInterval:10.0 target:self selector:@selector(refreshConnections:) userInfo:nil repeats:YES]];
	[[self timer] fire];
}

-(void)_stopConnectionsTimer {
	if([self timer]) {
		[[self timer] invalidate];
		[self setTimer:nil];
	}
}

-(void)refreshConnections:(id)sender {
	PGConnection* connection = [self connection];
	NSError* error = nil;
	PGResult* result = [connection execute:@"SELECT datname AS database,procpid AS pid,current_query AS query,usename AS username,client_hostname AS remotehost,application_name,query_start,waiting FROM pg_stat_activity" format:PGClientTupleFormatBinary error:&error];
	if(error) {
#ifdef DEBUG
		NSLog(@"_startConnectionsTimer: Error: %@",error);
		NSLog(@"_startConnectionsTimer: Stopping timer");
#endif
		[self _stopConnectionsTimer];
		result = nil;
	}
	[self setConnections:result];
	[_tableView reloadData];
}

////////////////////////////////////////////////////////////////////////////////
// public methods


-(BOOL)willSelectView:(id)sender {
	// only allow view to be selected if server is running
	PGServer* server = [[self delegate] server];
	if([server state]==PGServerStateAlreadyRunning || [server state]==PGServerStateRunning) {
		// start timer
		[self _startConnectionsTimer];
		return YES;
	} else {
		return NO;
	}
}

-(BOOL)willUnselectView:(id)sender {
	[self _stopConnectionsTimer];
	return YES;
}

////////////////////////////////////////////////////////////////////////////////
// NSTableViewDataSource implementation

-(NSInteger)numberOfRowsInTableView:(NSTableView* )tableView {
	if([self connections]==nil) {
		return 0;
	}
	return [[self connections] size];
}

-(id)tableView:(NSTableView* )tableView objectValueForTableColumn:(NSTableColumn* )tableColumn row:(NSInteger)rowIndex {
	NSParameterAssert([self connections]);
	NSParameterAssert(rowIndex < [[self connections] size]);
	
	// fetch the record
	[[self connections] setRowNumber:rowIndex];
	NSDictionary* row = [[self connections] fetchRowAsDictionary];
	// get cell value
	id cell = [row objectForKey:[tableColumn identifier]];
	if([[tableColumn identifier] isEqualToString:@"waiting"]) {
		NSParameterAssert([cell isKindOfClass:[NSNumber class]]);
		return [cell boolValue] ? [NSImage imageNamed:@"red"] : [NSImage imageNamed:@"green"];
	}
	return cell ? cell : [NSNull null];
}


@end
