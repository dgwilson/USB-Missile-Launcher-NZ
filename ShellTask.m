//
//  ShellTask.m
//  
//
//  Created by Vincent Gable on 6/1/07.
//  Copyright 2007 Vincent Gable, you're free to use this code in *any* way you like, but I'd really appreciate it if you told me what you used it for.  It could make my day.
//

#import "ShellTask.h"

@implementation ShellTask


//Returns an NSTask that is equvalent to 
// sh -c <command>
//where <command> is passed directly to sh via argv, and is NOT quoted (so ~ expansion still works).
//stdin for the task is set to /dev/null .
//Note that the PWD for the task is whatever the current PWD for the executable sending the taskForCommand: message.
//Sending the task a - launch message will tell sh to run it.

+ (NSTask *)taskForShellCommand:(NSString *)command
{
	NSTask *task = [[NSTask alloc] init];
    [task setLaunchPath:@"/bin/sh"]; //we are launching sh, it is what will process the command
	[task setStandardInput:[NSFileHandle fileHandleWithNullDevice]]; //stdin is directed to /dev/null
	
	NSArray	*args = [NSArray arrayWithObjects:@"-l", // -l (lowercase L) tells it to “act as if it had been invoked as a login shell”
					 @"-c", //-c tells sh to execute commands from the next argument
					 command, //sh will read and execute the commands in this string.
					 nil];
    [task setArguments:args];

    return task;
}

//Executes the shell command, command, waits for it to finish
//returning it's output to std in and stderr.
//
//NOTE: may deadlock under some circumstances if the output gets so big it fills the pipe.
//See http://dev.notoptimal.net/search/label/NSTask for an overview of the problem, and a solution.
//I have not experienced the problem myself, so I can’t comment.

+ (NSString *)executeShellCommandSynchronously:(NSString *)command
{
	NSLog(@"%@ with command:%@", NSStringFromSelector(_cmd), command);
	
	NSTask *task = [self taskForShellCommand:command];
	
	//we pipe stdout and stderr into a file handle that we read 
    NSPipe *outputPipe = [NSPipe pipe];
    [task setStandardOutput:outputPipe];
	[task setStandardError:outputPipe];
    NSFileHandle *outputFileHandle = [outputPipe fileHandleForReading];
	
    [task launch];

	NSData * data;
	data = [outputFileHandle readDataToEndOfFile];
	
	NSString * output = [[NSString alloc] initWithData:data encoding:NSASCIIStringEncoding];
	//	NSLog(@"%@ output = %@", NSStringFromSelector(_cmd), output);
	return output;
}

+ (oneway void)executeShellCommandAsynchronously:(NSString *)command
{
	[[self taskForShellCommand:command] launch];
	
	return;
}

@end
