
#import <appkit/appkit.h>
#import "version.h"

#define MAXGAMESIZE_X	40
#define MAXGAMESIZE_Y	40
#define MAXGOLD			40

#define NOWAY	0
#define EAST	'E'
#define WEST	'W'
#define NORTH	'N'
#define SOUTH	'S'
#define MYWAY	'*'

#define	WOMEN	'@'
#define BRICK	'#'
#define GOLD	'$'
#define BASE	'.'

#define G_O_B	'*'
#define W_O_B	'+'
#define FREE	' '
#define ILLEGAL	'X'

#define JOLLY 	1


@interface SokoView:View
{
	id		sokoWindow;
	id		waitPanel;
	
	id		background;
	id		women,brick,gold,base;

	char	*way,*cway;
	int *east;
	int *west;
	int *north;
	int *south;
	int *wayDescription;
	int *knownWays;
	int *testWays;
	int *waysToTest;

	char	field[MAXGAMESIZE_X*MAXGAMESIZE_Y];
	int		fieldX,fieldY;
	int pieces;
	
	int		goldPosition[MAXGOLD];
	int		basePosition[MAXGOLD];
	int		goldN,baseN,initSolved;
	int		womenPosition;
	int		solved;
	int		last_goldPosition[MAXGOLD];
	int		last_basePosition[MAXGOLD];
	int		last_goldN,last_baseN;
	int		last_womenPosition;
	int		last_solved;

	
	NXSize	matrix;
	NXSize	winOverhead;
}

- setSokoWindow:sender;
- setWaitPanel:sender;
- initFrame:(const NXRect *)rect;

- readLevelFromFile:(char *)level;
- restartLevel;
- restorePosition;
- savePosition;

- setupWayfinder;
- (int)findWay:(int)end;
- findWayWithoutConflicts:(int)end;
- (int)findPositionFromDirection:(int)begin :(int)direction;

- moveWomen:(int)end;
- animateWomen:(int)newPosition;
- animateWomenWithGold:(int)newPosition :(int)behind;


/************ class methods */
- (BOOL)acceptsFirstResponder;
- (BOOL)acceptsFirstMouse;

- rightMouseDown:(NXEvent *)event;
- mouseDown:(NXEvent *)event;
- keyDown:(NXEvent *)event;
- sizeTo:(NXCoord)width:(NXCoord)height;
- drawSelf:(NXRect *)rect :(int)count;


/************ delegated methods */
- windowWillResize:sender toSize:(NXSize *)frameSize;

@end
