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
#include <string.h>

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
static void sub_6AB0();
static void sub_6D30();
static int sub_7564(const char *arg1, int arg2);

struct unknown stuff = {
  0, 0, 0, 0, 0, sub_6738
};

// String tables:
// 0x54
const char *banner_eng = "DLD - German Linux Distribution -\nUsage: dldkey -k <key>";

// 0x8d
const char *no_eng = "No, no!";
// 0x95
const char *error_eng = "Error: invalid activationkey";

// 0xB2
const char *banner_ger = "DLD - Deutsche Linux Distribution -\nGebrauch: dldkey -k <key>";
// 0xf0
const char *no_ger = "Na, na!";
// 0xF8
const char *error_ger = "Fehler: Ungueltiger Aktivierungsschluessel";

// 0xE000 (sort of)
#if 0
const char *str_table[6] = {
  error_ger,
  no_ger,
  banner_ger,
  error_eng,
  no_eng,
  banner_eng
};
#endif

// Number of strings in str table?
static unsigned int dword_124 = 6;

// 0xE8F0
static int done_init = 0;

unsigned int data_E920 = 0xbffffddc;
unsigned int data_E924 = 0;
// E928 (no idea how large this is)
unsigned int data_E928[] = { 0, 0, 0, 0, 0, 0, 0, 0, 0, 0 };

// 0xEAB0
struct off_EAB0_s {
  unsigned int *data;
};

struct off_EAB0_s off_EAB0 = {
  data_E928
};

unsigned int data_EB28[] = { };
unsigned int data_EB78[] = { 0xFBAD2086, 0 };

// Function pointers?
unsigned int data_EC48[] = { };

// 0xEEC4
static int g_dword_EEC4 = 0;

static int dword_F750 = 0;

static void sub_444(int arg1)
{
  // getenv = 0x2E94
  char *lang = getenv("LANG");
  if (strncmp(lang, "german", 7) != 0) {

  }

  unsigned int val = dword_124;
  val = val >> 0x1F;
  val += dword_124;

  val = val >> 1;

  arg1 += val;

  /*
  0xEB78;
  dword_E000;
  sub_7564();
  */
  sub_7564(banner_eng, 0xEB78);
  sub_7564("\n", 0xEB78); // 0x437 = "\n"

//  printf("%s: 0x457 not implemented!\n", __func__);
//  exit(1);
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
  // var4 loaded into EBX ? (contains argc)
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
  data_E928[ret] = 2;
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
  if (data[1] != 0) {
    // 0x1F3E
    printf("%s: 0x1F3E not implemented!\n", __func__);
    exit(1);
  }

  // 0x1F5C
  if (data[1] > 0x1F) {
    // 0x1F62
    printf("%s: 0x1F62 not implemented!\n", __func__);
    exit(1);
  }
  // 1FAC
  int ret = data[1];
  data[1]++;
  printf("WARNING - %s: 0x1FAC not completely implemented!\n", __func__);

  return ret + 2; // not correct
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

static void sub_6358()
{
}

void sub_6738()
{
}

int sub_6798(const char *arg1, int arg2, int arg3)
{
  // esi = arg1
  // edi = strlen(arg1) arg2
  //
  if (arg2 == 0) {
    return 0;
  }

  // 0x67C8
  //
  sub_6AB0();
}

static void sub_6AB0()
{
  // eax = EB78
  // edx = EC48
  // ecx = -1
  sub_6358();
}

static void sub_6D30()
{
}

static int sub_7564(const char *arg1, int arg2)
{
  printf("Strlen: %zu\n", strlen(arg1));

  return 1;
}

// 0x564
// ebx = argc, edi = argv
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
    sub_444(3);
    printf("%s: 0x5C8 not implemented!\n", __func__);
    exit(1);
  }

  dword_F750 = 1;

  // 0x510, edi, ebx
  getopt(argc, argv, "k:"); // 0x39F4
  // 5F0
  printf("%s: 0x5F0 not implemented!\n", __func__);
  exit(1);

  return 0;
}
