
#import <appkit/appkit.h>

@interface SController:Object
{
	id	infoPanel;
	id	sokoWindow;
	id	sokoView;
	id	waitPanel;
}

- appDidInit:sender;
- showInfoPanel:sender;
- restartLevel:sender;
- undo:sender;

@end
