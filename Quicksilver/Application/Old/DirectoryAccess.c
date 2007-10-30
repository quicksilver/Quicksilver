/*
 *  DirectoryAccess.c
 *  Quicksilver
 *
 *  Created by Alcor on Thu Mar 04 2004.
 *  Copyright (c) 2004 Blacktree, Inc.. All rights reserved.
 *
 */

#include "DirectoryAccess.h"

//#import <DirectoryService/DirectoryService.h>

/*
tDirReference gDirRef = NULL;
void main ( )
{
    long dirStatus = eDSNoErr;
    dirStatus = dsOpenDirService( &gDirRef );
    if ( dirStatus == eDSNoErr )
    {
        ListNodes();
    }
    if ( gDirRef != NULL )
    {
        dirStatus = dsCloseDirService( gDirRef );
    }
}
void ListNodes ( void ) {
    bool done = false;
    long dirStatus = eDSNoErr;
    unsigned long index = 0;
    unsigned long nodeCount = 0;
    unsigned long bufferCount = 0;
    tDataBufferPtr dataBuffer = NULL;
    tDataListPtr nodeName = NULL;
    tContextData context = NULL;
    
    dirStatus = dsGetDirNodeCount( gDirRef, &nodeCount );
    printf( "Registered node count is: %lu\n", nodeCount );
    if ( (dirStatus == eDSNoErr) && (nodeCount != 0) )
    {
        //Allocate a 32k buffer.
        dataBuffer = dsDataBufferAllocate( gDirRef, 32 * 1024 );
        if ( dataBuffer != NULL )
        {
            while ( (dirStatus == eDSNoErr) && (done == false) )
            {
                dirStatus = dsGetDirNodeList( gDirRef, dataBuffer, &bufferCount, &context );
                if ( dirStatus == eDSNoErr )
                {
                    for ( index = 1; index <= bufferCount; index++ )
                    {
                        dirStatus = dsGetDirNodeName( gDirRef, dataBuffer, index, &nodeName );
                        if ( dirStatus == eDSNoErr )
                        {
                            printf( "#%4ld ", index );
                            PrintNodeName( nodeName );
                            //Deallocate the data list containing the node name.
                            dirStatus = dsDataListDeallocate( gDirRef, nodeName );
                            free(nodeName);
                        }
                        else
                        {
                            printf("dsGetDirNodeName error = %ld\n", dirStatus );
                        }
                    }
                }
                done = (context == NULL);
            }
            if (context != NULL)
            {
                dsReleaseContinueData( gDirRef, context );
            }
            dsDataBufferDeAllocate( gDirRef, dataBuffer );
            dataBuffer = NULL;
        }
    }
} // ListNodes
void PrintNodeName ( tDataListPtr inNode ) {
    char* pPath;
    pPath = dsGetPathFromList( gDirRef, inNode, "/" );
    printf( "%s\n", pPath );
    if ( pPath != NULL )
    {
        free( pPath );
        pPath = NULL;
    }
} // PrintNodeName


void main ( )
{
    long dirStatus = eDSNoErr;
    dirStatus = dsOpenDirService( &gDirRef );
    if ( dirStatus == eDSNoErr )
    {
        FindNodes("/NetInfo/root");
    }
    if ( gDirRef != NULL )
    {
        dirStatus = dsCloseDirService( gDirRef );
    }
}
void FindNodes ( char* inNodePath ){
    bool done = false;
    long dirStatus = eDSNoErr;
    unsigned long index = 0;
    unsigned long bufferCount = 0;
    tDataBufferPtr dataBuffer = NULL;
    tDataListPtr nodeName = NULL;
    tContextData context = NULL;
    nodeName = dsBuildFromPath( gDirRef, inNodePath, "/");
    if ( nodeName != NULL )
    {
        //Allocate a 32k buffer.
        dataBuffer = dsDataBufferAllocate( gDirRef, 32 * 1024 );
        if ( dataBuffer != NULL )
        {
            while ( (dirStatus == eDSNoErr) && (done == false) )
            {
                dirStatus = dsFindDirNodes( gDirRef, dataBuffer, nodeName, eDSContains, &bufferCount, &context );
                if ( dirStatus == eDSNoErr )
                {
                    for ( index = 1; index <= bufferCount; index++ )
                    {
                        dirStatus = dsGetDirNodeName( gDirRef, dataBuffer, index, &nodeName );
                        if ( dirStatus == eDSNoErr )
                        {
                            printf( "#%4ld ", index );
                            PrintNodeName( nodeName );
                            //Deallocate the nodes.
                            dirStatus = dsDataListDeallocate( gDirRef, nodeName );
                            free(nodeName);
                        }
                        else
                        {
                            printf("dsGetDirNodeName error = %ld\n", dirStatus );
                        }
                    }
                }
                done = (context == NULL);
            }
            dirStatus = dsDataBufferDeAllocate( gDirRef, dataBuffer );
            dataBuffer = NULL;
        }
    }
} // FindNodes

void main ( )
{
    long dirStatus = eDSNoErr;
    tDirNodeReference nodeRef = NULL;
    dirStatus = dsOpenDirService( &gDirRef );
    if ( dirStatus == eDSNoErr )
    {
        dirStatus = MyOpenDirNode( &nodeRef );
        if ( dirStatus == eDSNoErr )
        {
            dsCloseDirNode( nodeRef );
        }
    }
    if ( gDirRef != NULL )
    {
        dirStatus = dsCloseDirService( gDirRef );
    }
}
long MyOpenDirNode ( tDirNodeReference *outNodeRef )
{
    long dirStatus = eDSNoErr;
    char nodeName[ 256 ] = "\0";
    tDataListPtr nodePath = NULL;
    printf( "Open Node : " );
    fflush( stdout );
    scanf( "%s", nodeName );
    printf( "Opening: %s.\n", nodeName );
    nodePath = dsBuildFromPath( gDirRef, nodeName, "/" );
    if ( nodePath != NULL )
    {
        dirStatus = dsOpenDirNode( gDirRef, nodePath, outNodeRef );
        if ( dirStatus == eDSNoErr )
        {
            printf( "Open succeeded. Node Reference = %lu\n", (unsigned long)outNodeRef );
        }
        else
        {
            printf( "Open node failed. Err = %ld\n", dirStatus );
        }
    }
    dsDataListDeallocate( gDirRef, nodePath );
    free( nodePath );
    return( dirStatus );
} // MyOpenDirNode

void main ( )
{
    long dirStatus = eDSNoErr;
    tDirNodeReference nodeRef = NULL;
    dirStatus = dsOpenDirService( &gDirRef );
    if ( dirStatus == eDSNoErr )
    {
        dirStatus = MyOpenDirNode( &nodeRef );
        if ( dirStatus == eDSNoErr )
        {
            GetRecordList(nodeRef);
            dsCloseDirNode( nodeRef );
        }
    }
    if ( gDirRef != NULL )
    {
        dirStatus = dsCloseDirService( gDirRef );
    }
}
long GetRecordList ( const tDirNodeReference nodeRef )
{
    unsigned long i = 0;
    unsigned long j = 0;
    unsigned long k = 0;
    long dirStatus = eDSNoErr;
    unsigned long recCount = 0; // Get all records.
    tDataBufferPtr dataBuffer = NULL;
    tContextData context = NULL;
    tAttributeListRef attrListRef = NULL;
    tAttributeValueListRef valueRef = NULL;
    tRecordEntry *pRecEntry = NULL;
    tAttributeEntry *pAttrEntry = NULL;
    tAttributeValueEntry *pValueEntry = NULL;
    tDataList recNames;
    tDataList recTypes;
    tDataList attrTypes;
    dataBuffer = dsDataBufferAllocate( gDirRef, 2 * 1024 ); // allocate a 2k buffer
    if ( dataBuffer != NULL )
    {
        // For readability, the sample code does not check dirStatus after 
        // each call, but         // your code should.
        dirStatus = dsBuildListFromStringsAlloc ( gDirRef, &recNames, kDSRecordsAll, NULL );
        dirStatus = dsBuildListFromStringsAlloc ( gDirRef, &recTypes, kDSStdRecordTypeUsers, NULL );
        dirStatus = dsBuildListFromStringsAlloc ( gDirRef, &attrTypes, kDSAttributesAll, NULL );
        do
        {
            dirStatus = dsGetRecordList( nodeRef, dataBuffer, &recNames, eDSExact, &recTypes, &attrTypes, false, &recCount, &context );
            for ( i = 1; i <= recCount; i++ )
            {
                dirStatus = dsGetRecordEntry( nodeRef, dataBuffer, i, &attrListRef, &pRecEntry );
                for ( j = 1; j <= pRecEntry->fRecordAttributeCount; j++ )
                {
                    dirStatus = dsGetAttributeEntry( nodeRef, dataBuffer, attrListRef, j, &valueRef, &pAttrEntry );
                    for ( k = 1; k <= pAttrEntry->fAttributeValueCount; k++ )
                    {
                        dirStatus = dsGetAttributeValue( nodeRef, dataBuffer, k, valueRef, &pValueEntry );
                        printf( "%s\t- %lu\n", pValueEntry->fAttributeValueData.fBufferData, pValueEntry->fAttributeValueID );
                        dirStatus = dsDeallocAttributeValueEntry( gDirRef, pValueEntry );
                        pValueEntry = NULL;
                        // Deallocate pAttrEntry, pValueEntry, and pRecEntry
                        // by calling dsDeallocAttributeEntry,
                        // dsDeallocAttributeValueEntry, and
                        // dsDeallocRecordEntry, respectively.
                    }
                    dirStatus = dsCloseAttributeValueList( valueRef );
                    valueRef = NULL;
                    dirStatus = dsDeallocAttributeEntry( gDirRef, pAttrEntry);
                    pAttrEntry = NULL;
                }
                dirStatus = dsCloseAttributeList( attrListRef );
                attrListRef = NULL;
                dirStatus = dsDeallocRecordEntry( gDirRef, pRecEntry );
                pRecEntry = NULL;
            }
        } while (context != NULL); // Loop until all data has been obtained.
                                   // Call dsDataListDeallocate to deallocate recNames, recTypes, and
                                   // attrTypes.
                                   // Deallocate dataBuffer by calling dsDataBufferDeAllocate.
        dsDataListDeallocate ( gDirRef, &recNames );
        dsDataListDeallocate ( gDirRef, &recTypes );
        dsDataListDeallocate ( gDirRef, &attrTypes );
        dsDataBufferDeallocate ( gDirRef, dataBuffer );
        dataBuffer = NULL;
    }
    return dirStatus;
} // GetRecordList


void main ( )
{
    long dirStatus = eDSNoErr;
    tDirNodeReference nodeRef = NULL;
    dirStatus = dsOpenDirService( &gDirRef );
    if ( dirStatus == eDSNoErr )
    {
        dirStatus = MyOpenDirNode( &nodeRef );
        if ( dirStatus == eDSNoErr )
        {
            GetRecInfo(nodeRef);
            dsCloseDirNode( nodeRef );
        }
    }
    if ( gDirRef != NULL )
    {
        dirStatus = dsCloseDirService( gDirRef );
    }
}
void GetRecInfo ( const tDirNodeReference inDirNodeRef )
{
    long dirStatus = eDSNoErr;
    tRecordReference recRef = NULL;
    tAttributeEntryPtr pAttrInfo = NULL;
    tDataNodePtr recName = NULL;
    tDataNodePtr recType = NULL;
    tDataNodePtr attrType = NULL;
    recName = dsDataNodeAllocateString( gDirRef, "admin" );
    if ( recName != NULL )
    {
        recType = dsDataNodeAllocateString( gDirRef, kDSStdRecordTypeGroups);
        if ( recType != NULL )
        {
            dirStatus = dsOpenRecord( inDirNodeRef, recType, recName, &recRef );
            if ( dirStatus == eDSNoErr )
            {
                attrType = dsDataNodeAllocateString(gDirRef, kDS1AttrPrimaryGroupID );
                if ( attrType != NULL )
                {
                    dirStatus = dsGetRecordAttributeInfo(recRef, attrType, &pAttrInfo );
                    if ( pAttrInfo != NULL )
                    {
                        dirStatus = dsDeallocAttributeEntry( gDirRef, pAttrInfo );
                        pAttrInfo = NULL;
                    }
                    dirStatus = dsDataNodeDeAllocate( gDirRef, attrType );
                    attrType = NULL;
                }
            }
            dirStatus = dsDataNodeDeAllocate( gDirRef, recType );
            recType = NULL;
        }
        dirStatus = dsDataNodeDeAllocate( gDirRef, recName );
        recName = NULL;
    }
} // GetRecInfo


*/