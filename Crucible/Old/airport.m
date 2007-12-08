/*
 *  airport.m
 *
 *  802.11b airport control app 020516 ragge@nada.kth.se
 */

#include <CoreFoundation/CoreFoundation.h>
#include <Foundation/Foundation.h>
#include <stdio.h>

#include "Apple80211.h"

//#include "hermes_info.h"

WirelessContextPtr gWCtxt = NULL;
char *gProgname;


void
printWirelessNetworkInfoHeader(void)
{
  printf("Chan Nois Sign");
  printf("  Address          ");
  printf("  Beac Flgs");
  printf("  SLen  SSID\n");
}


void
printWirelessNetworkInfo(WirelessNetworkInfo *d)
{
  printf("%4d %4d %4d", d->channel, d->noise, d->signal);
  printf("  %02x:%02x:%02x:%02x:%02x:%02x",
	 d->macAddress[0], d->macAddress[1], d->macAddress[2], 
	 d->macAddress[3], d->macAddress[4], d->macAddress[5]);
  printf("  %4d %04x", d->beaconInterval, d->flags);
  printf("  %4d: %s\n", d->nameLen, d->name);
}

WIErr
wlGetInfo(void)
{
  WIErr err;
  WirelessInfo i;
  
  err = WirelessGetInfo(gWCtxt, &i);
  if(err)
    return err;

  printf("Sign  Qual Sign Nois\n");
  printf("%3d%%  %4d %4d %4d\n",
	 i.link_qual, i.comms_qual, i.signal, i.noise);
  printf("Network Name: %s\n", i.name);
  printf("AP Address:   %02x:%02x:%02x:%02x:%02x:%02x\n",
	 i.macAddress[0], i.macAddress[1], i.macAddress[2],
	 i.macAddress[3], i.macAddress[4], i.macAddress[5]);
  printf("Client mode:  0x%04x - %s\n", i.client_mode,
	 i.client_mode == 1 ? "BSS (Client)" : 
	 (i.client_mode == 4 ? "Create IBSS (Ad Hoc)" : "Unknown!"));
  printf("Power state:  0x%04x - %s\n", i.power,
	 i.power == 1 ? "On" :
	 (i.power == 0 ? "Off" : "Unknown!"));
  printf("Port state:   0x%04x - %s\n", i.port_stat,
	 i.port_stat == 1 ? "Off?" :
	 (i.port_stat == 2 ? "Connection bad?" :
	  (i.port_stat == 3 ? "IBSS (Ad Hoc)?" :
	   (i.port_stat == 4 ? "BSS (Client)?" :
	    (i.port_stat == 5 ? "Out of range? & BSS (Client)?" : "Unknown")))));
  printf("u7: 0x%04x, u9: 0x%04x\n", i.u7, i.u9);

  return 0;
}


WIErr
wlGetChannels(void)
{
  WIErr err;
  UInt16 channels;
  int i;
  
  err = WirelessGetChannels(gWCtxt, &channels);
  if(err)
    return err;

  printf("Valid channels for ad hoc networking:\n");
  printf("Mask: %04x\n", channels);
  for(i = 0; i < 14; i++)
    printf("%2d ", i + 1);
  printf("\n");
  for(i = 0; i < 14; i++) {
    printf("%2s ", channels & 0x1 ? "OK" : " ");
    channels = channels >> 1;
  }
  printf("\n");
  
  return 0;
}


WIErr
wlGetBestChannel(void)
{
  WIErr err;
  UInt16 channel;
  
  err = WirelessGetBestChannel(gWCtxt, &channel);
  if(err)
    return err;

  printf("Best ad hoc network channel: %d\n", channel);
  
  return 0;
}


WIErr
wlMakeIBSS(char *name, char *key, int channel)
{
  WIErr err;
  CFStringRef n = CFStringCreateWithCString(NULL, name, kCFStringEncodingISOLatin1);
  CFStringRef k = CFStringCreateWithCString(NULL, key, kCFStringEncodingISOLatin1);

  
  err = WirelessMakeIBSS(gWCtxt, n, k, channel);

  CFRelease(n);
  CFRelease(k);
  
  return err;
}


WIErr
wlGetPower(int *retval)
{
  WIErr err;
  UInt8 power;
  
  err = WirelessGetPower(gWCtxt, &power);
  if(err)
    return err;

  if(power) {
    printf("Power is on.\n");
    *retval = 0;
  } else {
    printf("Power is off.\n");
    *retval = 1;
  }

  return 0;
}


WIErr
wlSetPower(int power)
{
  WIErr err;
  
  err = WirelessSetPower(gWCtxt, power);

  return err;
}


WIErr
wlGetEnabled(int *retval)
{
  WIErr err;
  UInt8 enabled;
  
  err = WirelessGetEnabled(gWCtxt, &enabled);
  if(err)
    return err;

  if(enabled) {
    printf("Airport is enabled.\n");
    *retval = 0;
  } else {
    printf("Airport is disabled.\n");
    *retval = 1;
  }

  return 0;
}


WIErr
wlSetEnabled(int enabled)
{
  WIErr err;
  
  err = WirelessSetEnabled(gWCtxt, enabled);

  return err;
}


WIErr
wlScan(void)
{
  WIErr err;
  WirelessNetworkInfo *data;
  int i;
  CFArrayRef list1 = NULL;

  err = WirelessScan(gWCtxt, &list1, 0);

  if(err) {
    fprintf(stderr, "Error: WirelessScan: %d\n", (int) err);
    return err;
  }

  if(list1 == 0) {
    // this means either the scan failed, or there were no APs in range. there isn't any way to tell the difference
    return -1;
  } else {
    printWirelessNetworkInfoHeader();

    for(i=0; i < CFArrayGetCount(list1); i++) {
      data = (WirelessNetworkInfo *) CFDataGetBytePtr(CFArrayGetValueAtIndex(list1, i));
      // do something with the data (these are managed networks)
      printWirelessNetworkInfo(data);
    }
  }

  return err;
}


WIErr
wlScanSplit(void)
{
  WIErr err;
  WirelessNetworkInfo *data;
  int i;
  CFArrayRef list1 = NULL;
  CFArrayRef list2 = NULL;

  err = WirelessScanSplit(gWCtxt, &list1, &list2, 0);

  if(err) {
    fprintf(stderr, "Error: WirelessScanSplit: %d\n", (int) err);
    return err;
  }

  if(list1 == 0 || list2 == 0) {
    // this means either the scan failed, or there were no APs in range. there isn't any way to tell the difference
    return -1;
  } else {
    printWirelessNetworkInfoHeader();
    printf("[Access points]\n");
    for(i=0; i < CFArrayGetCount(list1); i++) {
      data = (WirelessNetworkInfo *) CFDataGetBytePtr(CFArrayGetValueAtIndex(list1, i));
      // do something with the data (these are managed networks)
      printWirelessNetworkInfo(data);
    }
    printf("[Ad hoc networks]\n");
    for(i=0; i < CFArrayGetCount(list2); i++) {
      data = (WirelessNetworkInfo *) CFDataGetBytePtr(CFArrayGetValueAtIndex(list2, i));
      // do something with the data (these are adhoc networks)
      printWirelessNetworkInfo(data);
    }
  }

  return err;
}


WIErr
wlJoin(char *network)
{
  WIErr err;
  CFStringRef n = CFStringCreateWithCString(NULL, network, kCFStringEncodingISOLatin1);
  
  err = WirelessJoin(gWCtxt, n);

  CFRelease(n);

  return err;
}


WIErr
wlJoinWEP(char *network, char *pass)
{
  WIErr err;
  CFStringRef n = CFStringCreateWithCString(NULL, network, kCFStringEncodingISOLatin1);
  CFStringRef p = CFStringCreateWithCString(NULL, pass, kCFStringEncodingISOLatin1);
  
  err = WirelessJoinWEP(gWCtxt, n, p);

  CFRelease(n);
  CFRelease(p);

  return err;
}


WIErr
wlDetach(void)
{
  WIErr err = 0;

  if(gWCtxt != NULL) {
    err = WirelessDetach(gWCtxt);
    if(err) fprintf(stderr, "Error: WirelessDetach: %d\n", (int) err);
  }

  return err;
}


WIErr
wlEncrypt(char *string, int length)
{
  WIErr err = 0;
  WirelessKey key;
  int i, len;
  
  err = WirelessEncrypt(CFStringCreateWithCString(NULL, string, kCFStringEncodingISOLatin1),
			&key, length);
  if(err) {
    fprintf(stderr, "Error: WirelessEncrypt: %d\n", (int) err);
    return err;
  }

  printf("Key (%s bits): ", length == 0 ? "40" : (length == 1 ? "104" : "Unknown number of"));

  if(length == 0)
    len = 5;
  else
    len = 13;
  
  for(i = 0; i < len; i++)
    printf("%.2X", key[i]);

  printf("\n");

  return err;
}


void usage_exit(void) {
  fprintf(stderr, "usage: %s [options [arg [arg [arg]]]]\n", gProgname);
  fprintf(stderr, "options:\n");
  fprintf(stderr, "         -c               Get connection info (default)\n");
  fprintf(stderr, "         -e               Get enabled state\n");
  fprintf(stderr, "         -p               Get power state\n");
  fprintf(stderr, "         -s               Scan for access points\n");
  fprintf(stderr, "         -l               Scan for access points - split lists\n");
  fprintf(stderr, "         -g               Get valid channels for ad hoc networking\n");
  fprintf(stderr, "         -b               Get best ad hoc network channel\n");
  fprintf(stderr, "         -i               Show link statistics counters from the Hermes chip\n");
  fprintf(stderr, "         -d               Show a bunch of Hermes chip internal data\n");
  fprintf(stderr, "         -x string keytype  Get Apple hash for given string. keytype is\n");
  fprintf(stderr, "                            0 for 40 bit or 1 for 104 bit key.\n");
  fprintf(stderr, "         -E 0|1           Set enabled state\n");
  fprintf(stderr, "         -P 0|1           Set power state\n");
  fprintf(stderr, "         -J name          Join network\n");
  fprintf(stderr, "         -W name key      Join network with WEP encryption\n");
  fprintf(stderr, "         -A name key chn  Create ad hoc network on given channel\n");
  fprintf(stderr, "\n");
  fprintf(stderr, " key - can be in any of these formats:\n");
  fprintf(stderr, " - Hex, with or without preceding 0x, 10 or 26 hexadecimal digits\n");
  fprintf(stderr, " - A string that will be converted to a key with the Apple-hash algoritm\n");
  fprintf(stderr, " - An empty string (\"\") meaning: encryption off\n");
  fprintf(stderr, " - For -W it can also be a 5 or 13 character long string representing\n");
  fprintf(stderr, "   the key itself (for compatibility with other brands)\n");

  wlDetach();

  exit(-1);
}


void
wlCheckAvail(int avail)
{
  if(avail)
    return;

  fprintf(stderr, "%s: Error: Wireless interface not available!\n",
	  gProgname);

  exit(-2);
}

/*
int
main(int argc, char **argv)
{
  WIErr err = 0;
  NSAutoreleasePool *pool;
  int retVal = 0;
  int avail = 0;

  gProgname = argv[0];

  pool = [[NSAutoreleasePool alloc] init];

  if(argc > 1 && (argv[1][0] != '-' || strlen(argv[1]) != 2))
      usage_exit();

  avail = WirelessIsAvailable();

  if(avail) {
    err = WirelessAttach(&gWCtxt, 0);
    if(err) {
      fprintf(stderr, "Error: WirelessAttach: %d\n", (int) err);
      exit(-1);
    }
  }

  switch(argc) {

  case 1:
    wlCheckAvail(avail);
    err = wlGetInfo();
    break;
  
  case 2:
    switch(argv[1][1]) {
    case 'c':
      wlCheckAvail(avail);
      err = wlGetInfo();
      break;
    case 'e':
      wlCheckAvail(avail);
      err = wlGetEnabled(&retVal);
      break;
    case 'p':
      wlCheckAvail(avail);
      err = wlGetPower(&retVal);
      break;
    case 's':
      wlCheckAvail(avail);
      err = wlScan();
      break;
    case 'l':
      wlCheckAvail(avail);
      err = wlScanSplit();
      break;
    case 'g':
      wlCheckAvail(avail);
      err = wlGetChannels();
      break;
    case 'b':
      wlCheckAvail(avail);
      err = wlGetBestChannel();
      break;
    case 'i':
      wlCheckAvail(avail);
      err = wlHermesTallies();
      break;
    case 'd':
      wlCheckAvail(avail);
      err = wlHermesInfo();
      break;
    default:
      usage_exit();
    }
    break;
    
  case 3:
    switch(argv[1][1]) {
    case 'E':
      wlCheckAvail(avail);
      err = wlSetEnabled(atoi(argv[2]));
      break;
    case 'P':
      wlCheckAvail(avail);
      err = wlSetPower(atoi(argv[2]));
      break;
    case 'J':
      wlCheckAvail(avail);
      err = wlJoin(argv[2]);
      break;
    default:
      usage_exit();
    }    
    break;
  
  case 4:
    switch(argv[1][1]) {
    case 'x':
      wlEncrypt(argv[2], atoi(argv[3]));
      break;
    case 'W':
      wlCheckAvail(avail);
      err = wlJoinWEP(argv[2], argv[3]);
      break;
    default:
      usage_exit();
    }    
    break;
  
  case 5:
    switch(argv[1][1]) {
    case 'A':
      wlCheckAvail(avail);
      err = wlMakeIBSS(argv[2], argv[3], atoi(argv[4]));
      break;
    default:
      usage_exit();
    }    
    break;
  
  default:
    usage_exit();
  }
    
  if(err != noErr) {
    fprintf(stderr, "%s: Error: %d\n", gProgname, (int) err);
    retVal = -1;
  }

  wlDetach();
  
  return retVal;
}

*/