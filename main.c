/*
 * Copyright (c) 2023 Devin Smith <devin@devinsmith.net>
 *
 * Permission to use, copy, modify, and distribute this software for any
 * purpose with or without fee is hereby granted, provided that the above
 * copyright notice and this permission notice appear in all copies.
 *
 * THE SOFTWARE IS PROVIDED "AS IS" AND THE AUTHOR DISCLAIMS ALL WARRANTIES
 * WITH REGARD TO THIS SOFTWARE INCLUDING ALL IMPLIED WARRANTIES OF
 * MERCHANTABILITY AND FITNESS. IN NO EVENT SHALL THE AUTHOR BE LIABLE FOR
 * ANY SPECIAL, DIRECT, INDIRECT, OR CONSEQUENTIAL DAMAGES OR ANY DAMAGES
 * WHATSOEVER RESULTING FROM LOSS OF USE, DATA OR PROFITS, WHETHER IN AN
 * ACTION OF CONTRACT, NEGLIGENCE OR OTHER TORTIOUS ACTION, ARISING OUT OF
 * OR IN CONNECTION WITH THE USE OR PERFORMANCE OF THIS SOFTWARE.
 */

#include <stdint.h>
#include <stdlib.h>
#include <stdio.h>

/* 0xEC48 */
struct unknown {
  uint32_t unknown1; // 0
  uint32_t unknown2; // 4
  uint32_t unknown3; // 8
  uint32_t unknown4; // 12
  uint32_t unknown5; // 16
  void (*func)();    // 20
};

static int sub_1EFC(int arg1);
static int sub_1F2C();
static void sub_6738();

struct unknown stuff = {
  0, 0, 0, 0, 0, sub_6738
};

// 0xE8F0
static int done_init = 0;

// E928 (no idea how large this is)
unsigned int data_E928[] = { 0, 0, 0, 0, 0, 0, 0, 0, 0, 0 };

// 0xEAB0
struct off_EAB0_s {
  unsigned int *data;
};

struct off_EAB0_s off_EAB0 = {
  data_E928
};

// 0xEEC4
static int g_dword_EEC4 = 0;

void sub_444()
{
}

static void sub_1A8C()
{
  int var4;

  // ebx = 0xEEC4
  if (g_dword_EEC4 != 0) {
    // 1AA0
  }
  // 1AAC:
  // 0x1A3C
  sub_1EFC(0x1A3C);
  // var4 loaded into EBX ?
  printf("%s: 0x1AB6 not implemented (var4 unhandled)!\n", __func__);
//  exit(1);
}

static void sub_1ACC()
{
  if (!done_init) {
    done_init = 1;
    sub_1A8C();
  }
}

static int sub_1EFC(int arg1)
{
  int ret = sub_1F2C();
  if (ret == 0) {
    // 1F1C
    return -1;
  }
  // 0x1F05
  data_E928[(ret - 0xE928) / 4] = 2;
  data_E928[ret + 1] = arg1;
  return 0;
}

static int sub_1F2C()
{
  unsigned int *data = off_EAB0.data;
  if (data == NULL) {
    printf("%s: 0x1F68 not implemented!\n", __func__);
    exit(1);
  }
  // 1F38
  if (data[4] == 0) {

    // 1F5C
    if (data[4] <= 0x1F) {
      // 1FAC
      //
      int ret = data[4];
      printf("WARNING - %s: 0x1FAC not completely implemented!\n", __func__);

      return 0xE930; // not correct
    }
    printf("%s: 0x1F5C not implemented!\n", __func__);
    exit(1);

  }
  printf("%s: 0x1F38 not implemented!\n", __func__);
  exit(1);
}

void sub_206C(int arg1)
{
}

void sub_29F4(int arg1, int arg2, int arg3)
{
}

/* 0x5678 */
void sub_5678()
{
}

void sub_61B8()
{
}

void sub_6738()
{
}

void sub_7564()
{
}

// 0x564
int main(int argc, char *argv[])
{
  int var_394;
  int var_398;
  int var_39C;
  int var_3A0;
  int var_3A4;
  int var_3A8;
  int addr_3AC;

  sub_1ACC();

  var_394 = 0;
  var_398 = 0;
  var_39C = 0;

  // 0x59B
  var_3A0 = 0;
  var_3A4 = 1;
  var_3A8 = 0xF340;

  // 0x5B9
  addr_3AC = 0xEF40;
  if (argc != 3) {
    // 0x5C8
    // 5E4
  }

  // 5E4
  printf("%s: 0x5E4 not implemented!\n", __func__);
  exit(1);

  return 0;
}
