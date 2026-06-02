#include <errno.h>
#include <openssl/des.h>
#include <stdint.h>
#include <stdio.h>
#include <stdlib.h>
#include <string.h>

#define DEFAULT_MAX_HITS 20

static void usage(const char *argv0)
{
  fprintf(stderr, "usage: %s <ALPHA> <16-hex-bytes> [start] [end] [max-hits]\n", argv0);
  fprintf(stderr, "example: %s MMRUN 67ebaff44bfc0e3b4315f9365d5dca22\n", argv0);
}

static int hexval(int c)
{
  if (c >= '0' && c <= '9') return c - '0';
  if (c >= 'a' && c <= 'f') return c - 'a' + 10;
  if (c >= 'A' && c <= 'F') return c - 'A' + 10;
  return -1;
}

static int parse_hex_bytes(const char *text, unsigned char *out, size_t out_len)
{
  size_t nibbles = 0;
  int high = -1;

  while (*text) {
    int value = hexval((unsigned char)*text++);
    if (value < 0) {
      continue;
    }
    if (nibbles / 2 >= out_len) {
      return -1;
    }
    if (high < 0) {
      high = value;
    } else {
      out[nibbles / 2] = (unsigned char)((high << 4) | value);
      high = -1;
    }
    nibbles++;
  }

  return high < 0 && nibbles / 2 == out_len ? 0 : -1;
}

static void des_encrypt_block(const unsigned char key[8], unsigned char block[8])
{
  DES_cblock des_key;
  DES_cblock in;
  DES_cblock out;
  DES_key_schedule schedule;

  memcpy(des_key, key, 8);
  memcpy(in, block, 8);
  DES_set_key_unchecked(&des_key, &schedule);
  DES_ecb_encrypt(&in, &out, &schedule, DES_ENCRYPT);
  memcpy(block, out, 8);
}

static void derive_dld_key(const char *password, unsigned char key[8])
{
  unsigned char initial_key[8];
  unsigned char block[8];
  size_t len = strlen(password);
  size_t first_len = len > 8 ? 8 : len;
  size_t offset = first_len;
  size_t i;

  for (i = 0; i < first_len; i++) {
    initial_key[i] = (unsigned char)(password[i] << 1);
  }
  for (; i < 8; i++) {
    initial_key[i] = 0x40;
  }

  memset(key, 0, 8);

  while (len - offset > 8) {
    for (i = 0; i < 8; i++) {
      key[i] ^= (unsigned char)password[offset + i];
    }
    des_encrypt_block(initial_key, key);
    offset += 8;
  }

  memset(block, 0x20, 8);
  for (i = 0; i < len - offset; i++) {
    block[i] = (unsigned char)password[offset + i];
  }
  for (i = 0; i < 8; i++) {
    key[i] ^= block[i];
  }
  des_encrypt_block(initial_key, key);
}

static void decrypt_prefix(const char *password, const unsigned char ciphertext[16], unsigned char plaintext[16])
{
  unsigned char key[8];
  unsigned char feedback[8] = {0};
  size_t i;

  derive_dld_key(password, key);
  des_encrypt_block(key, feedback);

  for (i = 0; i < 8; i++) {
    plaintext[i] = feedback[i] ^ ciphertext[i];
  }

  memcpy(feedback, ciphertext, 8);
  des_encrypt_block(key, feedback);
  for (i = 0; i < 8; i++) {
    plaintext[8 + i] = feedback[i] ^ ciphertext[8 + i];
  }
}

static int gzip_score(const unsigned char plaintext[16])
{
  int score = 0;

  if (plaintext[0] == 0x1f) score++;
  if (plaintext[1] == 0x8b) score++;
  if (plaintext[2] == 0x08) score += 4;
  if ((plaintext[3] & 0xE0) == 0) score += 2;
  if (plaintext[8] <= 4) score++;
  if (plaintext[9] == 0x03 || plaintext[9] == 0x00 || plaintext[9] == 0xff) score++;
  if ((plaintext[3] & 0x04) == 0 || plaintext[10] || plaintext[11]) score++;

  return score;
}

static int gzip_magic(const unsigned char plaintext[16])
{
  return plaintext[0] == 0x1f && plaintext[1] == 0x8b && plaintext[2] == 0x08;
}

static unsigned int key_rand(unsigned int checksum)
{
  uint64_t state = ((uint64_t)0x4142 << 32) | ((uint64_t)0x4D55 << 16) | 0x330E;
  unsigned int skips = checksum % 0x47F;
  unsigned int i;

  for (i = 0; i <= skips; i++) {
    state = (state * 0x5DEECE66DULL + 0xB) & 0xFFFFFFFFFFFFULL;
  }

  return (unsigned int)(state >> 17);
}

static void print_install_key(const char *alpha, unsigned long derived_suffix, unsigned int checksum)
{
  unsigned int random_value = key_rand(checksum);
  unsigned long body = 2220000000UL + derived_suffix - random_value;
  char body_text[32];
  size_t i;

  snprintf(body_text, sizeof(body_text), "%lu", body);

  printf(" install_key=%s", alpha);
  for (i = strlen(body_text); i > 0; i--) {
    putchar(body_text[i - 1]);
  }
  printf("%06u", checksum);
}

static int parse_ulong_arg(const char *text, unsigned long max, unsigned long *out)
{
  char *endptr;

  errno = 0;
  *out = strtoul(text, &endptr, 10);
  return !errno && *endptr == '\0' && *out <= max;
}

int main(int argc, char **argv)
{
  unsigned char ciphertext[16];
  unsigned char plaintext[16];
  const char *alpha;
  unsigned long start = 0;
  unsigned long end = 9999999;
  unsigned long max_hits = DEFAULT_MAX_HITS;
  unsigned long hits = 0;
  unsigned long value;
  char password[128];

  if (argc != 3 && argc != 5 && argc != 6) {
    usage(argv[0]);
    return 2;
  }

  alpha = argv[1];
  if (parse_hex_bytes(argv[2], ciphertext, sizeof(ciphertext)) != 0) {
    fprintf(stderr, "expected exactly 16 hex bytes\n");
    return 2;
  }

  if (argc >= 5) {
    if (!parse_ulong_arg(argv[3], 9999999, &start)) {
      fprintf(stderr, "invalid start value\n");
      return 2;
    }
    if (!parse_ulong_arg(argv[4], 9999999, &end) || end < start) {
      fprintf(stderr, "invalid end value\n");
      return 2;
    }
  }

  if (argc == 6 && (!parse_ulong_arg(argv[5], 10000000, &max_hits) || max_hits == 0)) {
    fprintf(stderr, "invalid max-hits value\n");
    return 2;
  }

  for (value = start; value <= end; value++) {
    int n = snprintf(password, sizeof(password), "%s222%07lu", alpha, value);
    if (n < 0 || (size_t)n >= sizeof(password)) {
      fprintf(stderr, "candidate password too long\n");
      return 2;
    }

    decrypt_prefix(password, ciphertext, plaintext);
    if (gzip_magic(plaintext)) {
      printf("hit score=%d derived_key=%s plaintext=", gzip_score(plaintext), password);
      for (size_t i = 0; i < sizeof(plaintext); i++) {
        printf("%02x", plaintext[i]);
      }
      print_install_key(alpha, value, 0);
      putchar('\n');

      hits++;
      if (hits >= max_hits) {
        return 0;
      }
    }
  }

  return hits ? 0 : 1;
}
