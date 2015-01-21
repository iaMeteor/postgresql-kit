
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

#import "PGSourceViewTree.h"

@implementation PGSourceViewTree

////////////////////////////////////////////////////////////////////////////////
// constructors

-(id)init {
	self = [super init];
	if(self) {
		_tags = [NSMutableDictionary new];
		_children = [NSMutableDictionary new];
		_counter = 0;
		NSParameterAssert(_tags && _children);
	}
	return self;
}

////////////////////////////////////////////////////////////////////////////////
// properties

@dynamic count;

-(NSUInteger)count {
	return [_tags count];
}

////////////////////////////////////////////////////////////////////////////////
// private methods

-(id)_keyForTag:(NSInteger)tag {
	return [NSNumber numberWithInteger:tag];
}

-(id)_rootKey {
	return @0;
}

-(PGSourceViewNode* )_nodeForTagKey:(id)key {
	NSParameterAssert(key);
	return [_tags objectForKey:key];
}

-(id)_tagKeyForNode:(PGSourceViewNode* )node {
	NSArray* keys = [_tags allKeysForObject:node];
	if([keys count]) {
		NSParameterAssert([keys count]==1);
		return [keys objectAtIndex:0];
	} else {
		return nil;
	}
}

-(id)_getNewTagKey {
	do {
		NSInteger tag = ++_counter;
		id key = [self _keyForTag:tag];
		if([self _nodeForTagKey:key]==nil) {
			// no existing tag
			return key;
		}
	} while(_counter <= NSIntegerMax);
	return nil;
}

-(id)_addNode:(PGSourceViewNode* )node {
	NSParameterAssert(node);
	id key = [self _getNewTagKey];
	if(key) {
		[_tags setObject:node forKey:key];
	}
	return key;
}

-(NSMutableArray* )_childrenForKey:(id)key {
	return [_children objectForKey:((key==nil) ? [self _rootKey] : key)];
}

-(void)_addChildKey:(id)key parentKey:(id)parentKey {
	// TODO: check key is not there yet
	NSMutableArray* children = [self _childrenForKey:parentKey];
	if(children==nil) {
		children = [NSMutableArray new];
		NSParameterAssert(children);
		[_children setObject:children forKey:(parentKey ? parentKey : [self _rootKey])];
	}
	[children addObject:key];
}

////////////////////////////////////////////////////////////////////////////////
// public methods

-(void)removeAllNodes {
	[_tags removeAllObjects];
	[_children removeAllObjects];
	_counter = 0;
}

-(void)addNode:(PGSourceViewNode* )node parent:(PGSourceViewNode* )parent {
	// ensure parent is in the tree, and node isn't
	NSParameterAssert(parent==nil || [self _tagKeyForNode:parent]);
	NSParameterAssert(node && [self _tagKeyForNode:node]==nil);
	// if parent==nil, than use tag 0 or else determine tag for this node
	id key = [self _addNode:node];
	NSParameterAssert(key);
	[self _addChildKey:key parentKey:[self _tagKeyForNode:parent]];
}

// TODO -(void)removeNode:(PGSourceViewNode* )parent {
//
//}

-(PGSourceViewNode* )nodeAtIndex:(NSInteger)index parent:(PGSourceViewNode* )parent {
	id key = parent ? [self _tagKeyForNode:parent] : [self _rootKey];
	if(key==nil) {
		// parent not found, return nil
		return nil;
	}
	NSArray* children = [self _childrenForKey:key];
	NSParameterAssert(children);
	NSParameterAssert(index >= 0 && index < [children count]);
	PGSourceViewNode* node = [self _nodeForTagKey:[children objectAtIndex:index]];
	NSParameterAssert(node);
	return node;
}

-(NSInteger)numberOfChildrenOfParent:(PGSourceViewNode* )parent {
	id key = parent ? [self _tagKeyForNode:parent] : [self _rootKey];
	if(key==nil) {
		// parent not found, return nil
		return NSNotFound;
	}
	return [[self _childrenForKey:key] count];
}

////////////////////////////////////////////////////////////////////////////////
// public methods - NSUserDefaults

-(BOOL)loadFromUserDefaults {
	NSUserDefaults* defaults = [NSUserDefaults standardUserDefaults];
	NSArray* nodes = [defaults arrayForKey:@"nodes"];
	NSDictionary* children = [defaults dictionaryForKey:@"children"];
	if(nodes==nil || children==nil) {
		return NO;
	}
	
	// remove existing data
	[self removeAllNodes];
	
	// add in the nodes
	for(NSDictionary* data in nodes) {
		if([data isKindOfClass:[NSDictionary class]]==NO) {
			continue;
		}
		PGSourceViewNode* node = [PGSourceViewNode nodeFromDictionary:data];
		if(node==nil) {
			continue;
		}
		NSNumber* tag = [data objectForKey:@"key"];
		if([tag isKindOfClass:[NSNumber class]]==NO) {
			continue;
		}
		[_tags setObject:node forKey:tag];
	}
	
	// add the children
	for(NSString* key in children) {
		NSInteger tag = [key integerValue];
		if(tag < 0) {
			continue;
		}
		NSMutableArray* array = [NSMutableArray arrayWithArray:[children objectForKey:key]];
		[_children setObject:array forKey:[self _keyForTag:tag]];
	}
	return YES;
}

-(BOOL)saveToUserDefaults {
	NSUserDefaults* defaults = [NSUserDefaults standardUserDefaults];
	
	// get nodes
	NSMutableArray* nodes = [NSMutableArray arrayWithCapacity:[_tags count]];
	NSParameterAssert(nodes);
	for(id key in _tags) {
		PGSourceViewNode* node = [self _nodeForTagKey:key];
		NSParameterAssert(node);
		[nodes addObject:[node dictionaryWithKey:key]];
	}

	NSMutableDictionary* children = [NSMutableDictionary dictionaryWithCapacity:[_children count]];
	NSParameterAssert(children);
	for(NSNumber* key in _children) {
		NSParameterAssert([key isKindOfClass:[NSNumber class]]);
		[children setObject:[_children objectForKey:key] forKey:[key description]];
	}
	
	// save nodes and children in defaults
	[defaults setObject:nodes forKey:@"nodes"];
	[defaults setObject:children forKey:@"children"];

	// synchronize to disk
	return [defaults synchronize];
}

@end