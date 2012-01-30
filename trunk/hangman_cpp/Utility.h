#ifndef __UTILITY_H__
#define __UTILITY_H__

#include <string>
#include <algorithm>
#include <cctype>
#include <string.h>
#include <stdio.h>

using namespace std;

inline string toUpperCase(const string & str) {
  string ret = str;
  transform(ret.begin(), ret.end(), ret.begin(), toupper);
  return ret;
}

inline string readWord(FILE * f) {
  char wordbuf[1024];
  int len = 0;
  if (fgets(wordbuf, 1024, f)) {
    wordbuf[1023] = '\0';
    len = strlen(wordbuf);
    if (wordbuf[len - 1] == '\n') {
      wordbuf[len - 1] = '\0';
      len--;
    }
    transform(wordbuf, wordbuf + len, wordbuf, toupper);
  }
  return string(wordbuf, len);
}

#endif
