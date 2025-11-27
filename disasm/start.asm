00000400  E89F3B0000        call 0x3fa4
00000405  B82D000000        mov eax,0x2d
0000040A  BB00000000        mov ebx,0x0
0000040F  CD80              int 0x80
00000411  A3E8EB0000        mov [0xebe8],eax
00000416  8B442408          mov eax,[esp+0x8]
0000041A  A320E90000        mov [0xe920],eax
0000041F  0FB705B8EA0000    movzx eax,word [dword 0xeab8]
00000426  50                push eax
00000427  E840200000        call 0x246c
0000042C  83C404            add esp,byte +0x4
0000042F  E8C0290000        call 0x2df4
00000434  E82B050000        call main    ; 0x964
00000439  50                push eax
0000043A  E8D5390000        call 0x3e14
0000043F  5B                pop ebx
00000440  B801000000        mov eax,0x1
00000445  CD80              int 0x80
00000447  EBF7              jmp short 0x440

