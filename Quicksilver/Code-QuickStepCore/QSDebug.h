/*
 *  QSDebug.h
 *  Quicksilver
 *
 *  Created by Alcor on 2/2/05.
 *  Copyright 2005 Blacktree. All rights reserved.
 *
 */

#ifdef DEBUG
#define VERBOSE (NSInteger) getenv("verbose")

#define DEBUG_RANKING (NSInteger) getenv("QSDebugRanking")
#define DEBUG_MNEMONICS (NSInteger) getenv("QSDebugMnemonics")
#define DEBUG_PLUGINS (NSInteger) getenv("QSDebugPlugIns")
#define DEBUG_MEMORY (NSInteger) getenv("QSDebugMemory")
#define DEBUG_STARTUP (NSInteger) getenv("QSDebugStartup")
#define DEBUG_CATALOG (NSInteger) getenv("QSDebugCatalog")
#define DEBUG_LOCALIZATION (NSInteger) getenv("QSDebugLocalization")
#define DEBUG_UNPACKING (NSInteger) getenv("QSDebugUnpacking")

#endif