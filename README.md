# dldkey

`dldkey` is a tool that shipped with a relatively obscure Linux distribution
in 1993/1994 called Deutsche Linux Distribution (DLD). The utility  was used
by the install script to install commercial software. The software was
encrypted and `dldkey` was used to decrypt the contents of the encrypted
tar.gz file as it installed.

The purpose of this repo is to reverse engineer `dldkey` and determine the
install key used or write a replacement dldkey utility that doesn't need a
key. The code in this repo may not necessarily be very high quality since we
are attempting to match the original binary (where it makes sense) using
reverse engineering techniques. Since the tool was staticly linked with the C
library at the time, the tool developed here will not be byte for byte
compatible with the original binary.

# Debugging / Disassembly

Use gdb, set a breakpoint at 0x564 (main)

```
b *0x564
disassemble 0x564 0x570
info registers
```

ndisasm may also work but you may need to subtract 0x400 from all
calls/addresses.

```
ndisasm -b 32 -k 0x400,0 dldkey
```
