
#import "SController.h"
#import	"SokoView.h"

#define JOLLY_SOKOBANWINDOW "jollys_sokoban_window"

@implementation SController

- showInfoPanel:sender
{
	if( infoPanel==nil && ![NXApp	loadNibSection:"Info.nib" owner:self withNames: NO])
		return nil;
	[infoPanel makeKeyAndOrderFront:nil];
    return self;
}


- appDidInit:sender
{
	char	*level;
	char 	first[]="1";
	
	sokoView=[[SokoView alloc]initFrame:NULL];
	[sokoView setSokoWindow:sokoWindow];
	[sokoView setWaitPanel:waitPanel];
	[[sokoWindow setContentView:sokoView] free];
	[sokoWindow setDelegate:sokoView];
	[sokoWindow setFrameAutosaveName:JOLLY_SOKOBANWINDOW];
	
	if( (level=(char *)NXGetDefaultValue([NXApp appName],"Level"))==NULL)
	{
		level=first;
		NXWriteDefault([NXApp appName],"Level",level);
	}
	[sokoView readLevelFromFile:level];

	return self;
}

- restartLevel:sender;
{
	[sokoView restartLevel];
	return self;
}

- undo:sender;
{
	[sokoView restorePosition];
	return self;
}



@end
