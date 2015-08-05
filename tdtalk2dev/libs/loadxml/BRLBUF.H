#import <Foundation/Foundation.h>
#import "file.h"

#define BUF_LIST_HEAD	'S'
#define BUF_LIST_END	'E'
#define BUF_DEL_LIST_HEAD	's'
#define BUF_DEL_LIST_END	'E'
#define BUF_LIST_DATA	'D'
#define RBUF_SIZE 1024
#define CR_MARK	0x0d
#define PR_MARK	0x0c

typedef struct {
	unsigned short AllPage;
	unsigned short Page;
	unsigned short Line;
	unsigned short Kan;
	unsigned short KanPage;
}PAGE_INFO;

@interface BrlBuffer : NSObject {
	id m_lpList;
	id m_lpDelList;
	id m_tostr;
	NSString* Word;
	BRLDOC_DAT *Data;
	BRLDOC_LINE_ATTR LineAttr;
}
- (void)Setinit;
- (void)Ins:(unsigned char *)Dat;
- (char *)GetDat;
- (BOOL)NextLine;
- (void)Top;
- (void)End;
@end
