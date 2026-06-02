#include <errno.h>
#include <openssl/des.h>
#include <stdio.h>
#include <stdlib.h>
#include <string.h>

#define BUFFER_SIZE 4096

struct dld_stream {
  unsigned char feedback[8];
  unsigned char keystream[8];
  unsigned char cipher_block[8];
  size_t pos;
};

static void usage(const char *argv0)
{
  fprintf(stderr, "usage: %s <derived-key> <input.tgc|-> <output.tgz|->\n", argv0);
  fprintf(stderr, "example: %s MMDEV2228549085 mmdev.tgc mmdev.tgz\n", argv0);
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

static void dld_stream_init(struct dld_stream *stream)
{
  memset(stream, 0, sizeof(*stream));
  stream->pos = 8;
}

static void dld_decrypt_update(
  struct dld_stream *stream,
  const unsigned char key[8],
  const unsigned char *ciphertext,
  unsigned char *plaintext,
  size_t len)
{
  size_t i;

  for (i = 0; i < len; i++) {
    if (stream->pos == 8) {
      memcpy(stream->keystream, stream->feedback, 8);
      des_encrypt_block(key, stream->keystream);
      stream->pos = 0;
    }

    plaintext[i] = ciphertext[i] ^ stream->keystream[stream->pos];
    stream->cipher_block[stream->pos] = ciphertext[i];
    stream->pos++;

    if (stream->pos == 8) {
      memcpy(stream->feedback, stream->cipher_block, 8);
    }
  }
}

static FILE *open_arg(const char *path, const char *mode, FILE *std_file)
{
  if (strcmp(path, "-") == 0) {
    return std_file;
  }

  return fopen(path, mode);
}

int main(int argc, char **argv)
{
  unsigned char key[8];
  unsigned char input[BUFFER_SIZE];
  unsigned char output[BUFFER_SIZE];
  struct dld_stream stream;
  FILE *in;
  FILE *out;

  if (argc != 4) {
    usage(argv[0]);
    return 2;
  }

  derive_dld_key(argv[1], key);
  dld_stream_init(&stream);

  in = open_arg(argv[2], "rb", stdin);
  if (!in) {
    fprintf(stderr, "%s: %s\n", argv[2], strerror(errno));
    return 2;
  }

  out = open_arg(argv[3], "wb", stdout);
  if (!out) {
    fprintf(stderr, "%s: %s\n", argv[3], strerror(errno));
    if (in != stdin) {
      fclose(in);
    }
    return 2;
  }

  while (1) {
    size_t got = fread(input, 1, sizeof(input), in);
    if (got) {
      dld_decrypt_update(&stream, key, input, output, got);
      if (fwrite(output, 1, got, out) != got) {
        fprintf(stderr, "write failed: %s\n", strerror(errno));
        if (in != stdin) fclose(in);
        if (out != stdout) fclose(out);
        return 1;
      }
    }

    if (got < sizeof(input)) {
      if (ferror(in)) {
        fprintf(stderr, "read failed: %s\n", strerror(errno));
        if (in != stdin) fclose(in);
        if (out != stdout) fclose(out);
        return 1;
      }
      break;
    }
  }

  if (in != stdin) fclose(in);
  if (out != stdout && fclose(out) != 0) {
    fprintf(stderr, "close failed: %s\n", strerror(errno));
    return 1;
  }

  return 0;
}
