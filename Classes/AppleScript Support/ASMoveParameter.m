//
//  ALLeftParameter.m
//  USB Missile Launcher NZ
//
//  Created by David Wilson on 15/04/07.
//  Copyright 2007 David G. Wilson. All rights reserved.
//

#import "ASMoveParameter.h"

#define	kUSBLauncherCommandUp			'mvup'
#define	kUSBLauncherCommandDown			'mvdn'
#define	kUSBLauncherCommandLeft			'mvle'
#define	kUSBLauncherCommandRight		'mvri'
#define	kUSBLauncherCommandUpLeft		'mvul'
#define	kUSBLauncherCommandUpRight		'mvur'
#define	kUSBLauncherCommandDownLeft		'mvdl'
#define	kUSBLauncherCommandDownRight	'mvdr'


// debug terminal command
// defaults write NSGlobalDomain NSScriptingDebugLogLevel 1

@implementation ASMoveParameter

//NSScriptCommand override
- (id)performDefaultImplementation;
{
	// Original event: <NSAppleEventDescriptor: 
	//                         'mlNZ'\'move'{ '----':'mvri', &'subj':''null''(), &'csig':65536 }
	
	SInt32	theError = noErr;
	id		directParameter = [self directParameter];
	
//	NSLog(@"ALLeftParameter directParameter = %@", directParameter);

	NSMutableArray*	returnValue = [NSMutableArray array];
//	NSLog(@"ALLeftParameter arguments = %@", [self arguments]);
	
	NSDictionary*	theArgs = [self evaluatedArguments];
	NSNumber*		moveTimerSeconds = [theArgs objectForKey:@"moveTimerSeconds"];
//	NSLog(@"ALLeftParameter moveTimerSeconds = %@", moveTimerSeconds);

	NSDictionary*  userInfo = [NSDictionary dictionaryWithObjectsAndKeys:
		[NSNumber numberWithInt:[moveTimerSeconds longValue]], @"moveTimerSeconds", nil];
	
	if ( [moveTimerSeconds isKindOfClass:[NSNumber class]] != NO )
	{
		//long	moveTimerSecondsValue = [moveTimerSeconds longValue];
		switch ( [directParameter longValue] )
		{
			case	kUSBLauncherCommandUp:
				//NSLog(@"ALLeftParameter: Move Up");
				[[NSNotificationCenter defaultCenter] postNotificationName: @"ASUp" object: nil userInfo:userInfo]; 
				break;
				
			case	kUSBLauncherCommandDown:
				//NSLog(@"ALLeftParameter: Move Down");
				[[NSNotificationCenter defaultCenter] postNotificationName: @"ASDown" object: nil userInfo:userInfo];
				break;
				
			case	kUSBLauncherCommandLeft:
				//NSLog(@"ALLeftParameter: Move Left");
				[[NSNotificationCenter defaultCenter] postNotificationName: @"ASLeft" object:nil userInfo:userInfo];
				break;
				
			case	kUSBLauncherCommandRight:
				//NSLog(@"ALLeftParameter: Move Right");
				[[NSNotificationCenter defaultCenter] postNotificationName: @"ASRight" object: nil userInfo:userInfo]; 
				break;
				
			case	kUSBLauncherCommandUpLeft:
				//NSLog(@"ALLeftParameter: Move Up Left");
				[[NSNotificationCenter defaultCenter] postNotificationName: @"ASUpLeft" object: nil userInfo:userInfo]; 
				break;

			case	kUSBLauncherCommandUpRight:
				//NSLog(@"ALLeftParameter: Move Up Right");
				[[NSNotificationCenter defaultCenter] postNotificationName: @"ASUpRight" object: nil userInfo:userInfo]; 
				break;

			case	kUSBLauncherCommandDownLeft:
				//NSLog(@"ALLeftParameter: Move Down Left");
				[[NSNotificationCenter defaultCenter] postNotificationName: @"ASDownLeft" object: nil userInfo:userInfo]; 
				break;

			case	kUSBLauncherCommandDownRight:
				//NSLog(@"ALLeftParameter: Move Down Right");
				[[NSNotificationCenter defaultCenter] postNotificationName: @"ASDownRight" object: nil userInfo:userInfo]; 
				break;
				
			default:
				theError = errAECoercionFail;
				break;
		}
	}
	
	if ( theError != noErr )
	{
		//ME	report the error, if any
		[self setScriptErrorNumber:theError];
	}
	
	return	returnValue;
}


@end


//	[[NSNotificationCenter defaultCenter] postNotificationName: @"ASLeft" object: nil]; //this is your Cocoa call
//	return nil;

/*

 
#define	kSKTAlignCommandEdgeTop			'top '
#define	kSKTAlignCommandEdgeBottom		'bott'
#define	kSKTAlignCommandEdgeVertical	'verc'
#define	kSKTAlignCommandEdgeLeft		'left'
#define	kSKTAlignCommandEdgeRight		'righ'
#define	kSKTAlignCommandEdgeHorizontal	'horc'
 
@implementation SKTAlignCommand : NSScriptCommand

-(id)performDefaultImplementation
{
	myLog1(@"ME SKTAlignCommand performDefaultImplementation");
	
	SInt32	theError = noErr;
	id		directParameter = [self directParameter];
	
	myLog2(@"ME SKTAlignCommand performDefaultImplementation directParameter = %@",directParameter);
	
	NSMutableArray*	returnValue = [NSMutableArray array];
	
	if ( [directParameter isKindOfClass:[NSArray class]] != NO )
	{
		NSEnumerator*	objectEnumerator = [directParameter objectEnumerator];
		id				anObject = nil;
		
		while ( ( anObject = [objectEnumerator nextObject] ) != nil )
		{
			if ( [anObject isKindOfClass:[NSScriptObjectSpecifier class]] != NO )
			{
				id	resolvedObject = [anObject objectsByEvaluatingSpecifier];
				
				myLog2(@"ME SKTAlignCommand performDefaultImplementation resolvedObject = %@",resolvedObject);
				
				if ( [resolvedObject isKindOfClass:[NSArray class]] != NO )
				{
					[returnValue addObjectsFromArray:resolvedObject];
				}
				else
				{
					[returnValue addObject:resolvedObject];
				}
			}
		}
	}
	
	NSDictionary*	theArgs = [self evaluatedArguments];
	NSNumber*		theEdgeObject = [theArgs objectForKey:@"toEdge"];
	
	if ( [theEdgeObject isKindOfClass:[NSNumber class]] != NO )
	{
		long	theEdgeValue = [theEdgeObject longValue];
		
		unsigned	j, m;
		NSRect		firstBounds = [[returnValue objectAtIndex:0] bounds];
		
		switch ( theEdgeValue )
		{
			case	kSKTAlignCommandEdgeTop:
				
				for ( j = 0, m = [returnValue count]; m > 0; j++, m-- )
				{
					SKTGraphic*	curGraphic = [returnValue objectAtIndex:j];
					NSRect		curBounds = [curGraphic bounds];
					
					if ( curBounds.origin.y != firstBounds.origin.y )
					{
						curBounds.origin.y = firstBounds.origin.y;
						[curGraphic setBounds:curBounds];
					}
				}
				break;
				
			case	kSKTAlignCommandEdgeBottom:
				
				for ( j = 0, m = [returnValue count]; m > 0; j++, m-- )
				{
					SKTGraphic*	curGraphic = [returnValue objectAtIndex:j];
					NSRect		curBounds = [curGraphic bounds];
					
					if ( NSMaxY( curBounds ) != NSMaxY( firstBounds ) )
					{
						curBounds.origin.y = NSMaxY( firstBounds ) - curBounds.size.height;
						[curGraphic setBounds:curBounds];
					}
				}
				break;
				
			default:
				theError = errAECoercionFail;
				break;
		}
	}
	
	if ( theError != noErr )
	{
		//ME	report the error, if any
		[self setScriptErrorNumber:theError];
	}
	
	return	returnValue;
}




#define	kSKTRectangleScriptingOrientationLandscape	'land'
#define	kSKTRectangleScriptingOrientationPortrait	'port'
#define	kSKTRectangleScriptingOrientationSquare		'squa'
 
@implementation SKTRectangle (SKTRectangleRotate)

-(id)rotate:(NSScriptCommand*)command
{
	myLog2(@"ME SKTRectangleRotate rotate: %@",command);
	SInt32	theError = noErr;
	
	NSDictionary*	theArgs = [command evaluatedArguments];
	NSNumber*		theAngleObject = [theArgs objectForKey:@"byDegrees"];
	
	if ( [theAngleObject isKindOfClass:[NSNumber class]] != NO )
	{
		long	theAngleValue = [theAngleObject longValue];
		
		if ( ( theAngleValue % 90 ) == 0 )
		{
			long	theTurns = ( ( theAngleValue / 90 ) % 4 );
			
			if ( theTurns < 0 )
			{
				theTurns += 4;
			}
			
			switch ( theTurns )
			{
				case	0:
				case	2:
					//ME	nothing to do for case 0 or case 2
					break;
					
				case	1:
				case	3:
					//ME	Algebra!
				{
					float	theHeight = [self height];
					float	theWidth = [self width];
					
					float	theXPosition = [self xPosition];
					float	theYPosition = [self yPosition];
					
					[self setWidth:theHeight];
					[self setHeight:theWidth];
					
					[self setXPosition:theXPosition + ( ( theWidth - theHeight ) / 2 )];
					[self setYPosition:theYPosition + ( ( theHeight - theWidth ) / 2 )];
				}
					break;
					
				default:
					//ME	this can't happen
					theError = errAECorruptData;
					break;
			}
		}
		else
		{
			theError = errAEEventFailed;
		}
	}
	
	if ( theError != noErr )
	{
		//ME	report the error, if any
		[command setScriptErrorNumber:theError];
	}
	
	return	self;
}

 
 
*/

