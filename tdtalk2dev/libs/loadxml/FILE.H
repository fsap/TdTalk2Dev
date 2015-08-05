#import <Foundation/Foundation.h>    
#import <stdio.h>	// for printf,fgets,puts
#import <ctype.h>	// for isspace, tolower
#import <string.h>	// for strcmp, strncpy, strlen
#import <stdlib.h>	// for atoi

#define BRLDOC_TAB_MAP_SIZE	10
#define BRLDOC_REV_MAP_SIZE	4
#define BRLDOC_SUBTTL_SIZE	30
#define SEP_NAME_SIZE	192
#define BES_FILE_ATTR	4	// ＩＢＭ－ＢＥＳ形式(*.bes)
#define BET_FILE_ATTR	5	// ＢＥ形式(*.bet)
#define BRLDOC_DAT_SIZE	256
#define BRLDOC_DAT_LENGTH 254
#define BRLDOC_MAX_DAT_INDEX 254
#define CR_MARK	0x0d
#define PR_MARK	0x0c

// 行属性
#define NOMAL_LINE_ATTR	0	// 通常
#define TOC_LINE_ATTR	1	// 見出し行
#define PR_LINE_ATTR	2	// 強制改ページ行
#define CL_STAB_ATTR	8	// 折れ線行
#define CL_LINE_ATTR	12	// 折れ線行
#define PAGE_LINE_ATTR	4	// ページ行

#define BR3_ED_MARK	0x13
#define BRLDOC_HEAD_SIZE	256

// データヘッダ領域
typedef struct {
	unsigned short AllPage;	// 総頁
	unsigned short CurLine;		// Cur行
	unsigned char MaxCol;	// 最大マス数
	unsigned char Col;		// Curマス数
	unsigned char MaxLine;	// １頁行数
	unsigned char Line;		// Cur行数
	unsigned char InitPage;	// 頁付けフラグ
	unsigned char DatAttr;	// データ識別	(0x00ならⅡ0x13ならⅢ)
}BRLDOC_DAT_HEAD;
// ブレイルスターⅢ追加情報
typedef struct {
	unsigned char SubTitol[BRLDOC_SUBTTL_SIZE];	// 文書備考
	unsigned short MaxRec;			// 最大レコード数
	unsigned char TabTbl[BRLDOC_TAB_MAP_SIZE];	// タブ位置ビットマップ
}BRLDOC_DAT_INFO;
// 墨字プリンタ制御領域(A4ｻｲｽﾞ固定)
typedef struct {
	unsigned char Attr;		// プリンタ種別
	unsigned char Form;		// 印字方式
	unsigned char LFiller;	// 左マージン
	unsigned char Rv;	// 0:凸面 1:凹面
}BRLDOC_DAT_SPRT;
// 点字プリンタ制御領域
typedef struct {
	unsigned char Attr;	// プリンタ種別
	unsigned char Form;	//印刷方式(片面:0x00 奇数頁:0x01 偶数頁:0x02 両面:0x03)
						// 上位４ビットは出力制御情報
						// 0x80:両面フラグ
						// 0x40:立っていればｲﾝﾀｰﾎﾟｲﾝﾄそうでなければｲﾝﾀｰﾗｲﾝ
						// 0x20:BT5000用立っていればかな同時印刷
	unsigned char LFiller;	// 左マージン
	unsigned char Port;		// 出力先
/*****出力先について・・・
0x00ならセントロニクスそれ以外はRS-232C
RS-232Cの場合この項目は設定として使用する
0Bit:未使用
1Bit:ストップビット0:8Bit 1:7Bit
2-3Bit:チャンネル番号
4-7Bit:ボーレート(300,600,1200,2400,4800,9600)の順で１オリジンで格納
300BPS:001,600:010,1200:011,2400:100,4800:101,9600:110,19200:111(将来用)
********/
	unsigned char RvMap[BRLDOC_REV_MAP_SIZE];	// 折線行最大３つまで（１オリジンのバイナリ形式）
}BRLDOC_DAT_PPRT;
// ファイルヘッダ領域
typedef struct {
	BRLDOC_DAT_HEAD DatHead;	// データヘッダ
	BRLDOC_DAT_INFO DatInfo;	// Ⅲ追加情報
	BRLDOC_DAT_SPRT SPrtCtrl;	// 墨字プリンタ制御情報
	BRLDOC_DAT_PPRT PPrtCtrl;	// 点字プリンタ制御情報
	char SepName[SEP_NAME_SIZE];	// 読み換えファイルネーム
}BRLDOC_HEAD;

// 文字のデータレイアウト
typedef union {
	char Code;
	char Dat;
}BRLDOC_DAT_CHAR;

// 行属性領域
typedef union {
	unsigned char Attr;
	struct BLINE_ATTR {
		unsigned char Page:1;
		unsigned char Mark:1;
		unsigned char Level:4;
		unsigned char Midashi:2;
	}Map;
}BRLDOC_LINE_ATTR;

// 補助行属性
typedef union {
	unsigned char Attr;
	struct BSUBLINE_ATTR {
		unsigned char Mark:1;
		unsigned char Index:1;
		unsigned char IndentCnt:6;
	}Map;
}BRLDOC_SUB_LINE_ATTR;

// データブロック領域
typedef union {
	char Line[BRLDOC_DAT_LENGTH];
	BRLDOC_DAT_CHAR Dat[BRLDOC_MAX_DAT_INDEX];
}BRLDOC_DATA_LINE;

// １行のデータレイアウト
typedef struct {
	BRLDOC_LINE_ATTR LineAttr;
	BRLDOC_SUB_LINE_ATTR SubAttr;
	BRLDOC_DATA_LINE Data;
}BRLDOC_DAT_BLOCK;
typedef union {
	char Data[BRLDOC_DAT_SIZE];
	BRLDOC_DAT_BLOCK Block;
}BRLDOC_DAT;

@interface File : NSObject {
	id m_EditBuffer;
	BRLDOC_HEAD m_EditHeadder;	// 文書ヘッダ
	BRLDOC_DAT m_EditData;	// １行バッファ
}
- (void)DataSet:(id)Bufid;
- (int)LoadXmlFile:(const char *)filename ReadMode:(int)RMode;
- (int)SaveTdvFile:(const char *)filename;
// カーソル位置を保存する
// 行内の最大文字取得関数
- (int)sSearch:(char *)Str1 Str2:(char *)Str2 Start:(int)Start;
- (int)IsKugiri:(char *)Str;
- (void)SetRuby:(char *)Str rStr:(char *)rStr;
- (void)SetSpan:(char *)Str rStr:(char *)rStr;
- (void)SetBuf:(char *)Str;
@end
