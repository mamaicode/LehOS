ORG 0x7c00 ;origin
BITS 16 ;16bit code only
CODE_SEG equ gdt_code - gdt_start ;gives us the 0x8 and 0x10 offsets
DATA_SEG equ gdt_data - gdt_start

_start: ;new label that jumps to our start label
    jmp short start
    nop ;no operation block required by our BIOS https://wiki.osdev.org/FAT

times 33 db 0 ;creates 33 bytes after short jump, 33 because adding up BIOS parameter block bytes
;so the line 9 is our BIOS parameter block, so if our BIOS starts filling in the values
;it doesnt corrupt our code it just fills in our nobytes
start:
    jmp 0:step2 ;makes our code segment will change to 0 when it does the jump, and our offset 0xc007 will work fine

step2:
    cli ;clear interrupts
    mov ax, 0x00 ;data segment
    mov ds, ax    ;and 
    mov es, ax    ;extra segment. By changing the segment register we are taking control, rather hoping BIOS sets it up for us
    mov ss, ax
    mov sp, 0x7c00 ;setting stack pointer 
    sti ;enable interrupt

    

.load_protected:
    cli ;clear interrupts
    lgdt[gdt_descriptor] ;load global descriptor table, it will go down to our gdt_descriptor it will find size and offset and load our gdt_code and gdt_data
    mov eax, cr0
    or eax, 0x1
    mov cr0, eax ;reseting the register now that we have set a bit
    jmp CODE_SEG:load32 ;switches to code selector and jumps load32 absolute address and then we jump forever
    
;GDT
gdt_start: ;label to reference it later
gdt_null: ;null descriptor
    dd 0x0
    dd 0x0

; offset 0x8, offset in the table      
gdt_code:  ;CS should point to this   WE ARE USING DEFAULTS, WE ARE DOING THIS JUST SO WE CAN ACCESS MEMORY
    dw 0xffff ;segment limit first 0-15bits                
    dw 0 ;base first 0-15 bits
    db 0 ;base 166-23 bits
    db 0x9a ;access byte    CHECK:https://wiki.osdev.org/Global_Descriptor_Table
    db 11001111b ;high 4 bit flags and the low 4 bit flags
    db 0 ;base 24-31 bits


; offset 0x10, for our data segment and stack segment and all that type of stuff
gdt_data: ;should be linked to DS,SS,ES,FS,GS
    dw 0xffff ;segment limit first 0-15bits                
    dw 0 ;base first 0-15 bits
    db 0 ;base 166-23 bits
    db 0x92 ;access byte    CHECK:https://wiki.osdev.org/Global_Descriptor_Table
    db 11001111b ;high 4 bit flags and the low 4 bit flags
    db 0 ;base 24-31 bits

gdt_end:

gdt_descriptor:
    dw gdt_end - gdt_start-1 ;gives us the size of descriptor
    dd gdt_start ;this is our offset

[BITS 32] ;just to mention when we are in 32 bit protected mode we can no longer use BIOS!
load32:
    mov eax, 1 ;represents the startng sector, 1
    mov ecx, 100 ;total number of sectors we want to load
    mov edi, 0x0100000 ;edi contanins address we want to load sectors into
    call ata_lba_read ;label that talks with drive and loads sectors into memory

ata_lba_read: ;writing the driver to get the kernel loaded
    mov ebx, eax, ;backup the LBA
    ;send the highest 8 bits of the lba to hard disk controller
    shr eax, 24 ;eax will be shifted 24 bits so it will contain 8 highest bits now 32-24
    mov dx, 0x1F6 ;port it expects to write 8 bits into
    out dx, al 
    ;finished sending the highest 8 bits of the LBA

;sending total sectors to read to the hard disk controller
mov eax,ecx
mov dx, 0x1F2
out dx, al
;finished sending the total sectors to read

;send more bits of the LBA
mov eax, ebx ;restoring the backup LBA
mov dx, 0x1F3
out dx, al
;finished sending more bits of the LBA

;send more bits of the LBA
mov dx, 0x1F4
mov eax, ebx;
shr eax, 8
out dx, al
;finished sending moer bits of the LBA

;send upper 16 bits of LBA
mov dx, 0x1F5
mov eax, ebx ;restore the backup LBA
shr eax, 16 ;shift by 16bits
out dx, al ;output to controller
;finished sending upper 16 bits of LBA


mov dx, 0x1f7
mov al, 0x20
out dx, al

;read all sectors into memory
.next_sector:
    push ecx ;pushing ecx register to stack



;checking if we need to read
.try_again:
    mov dx, 0x1f7
    in al, dx ;read port 0x1f7 into the al register
    test al, 8 
    jz .try_again ;jump back if it doesnt fail


;need to read 256 words at a time
    mov ecx, 256
    mov dx, 0x1F0
    rep insw ;reading the word from the port 0x1F0 and storing it into 0x0100000
     


times 510-($ - $$) db 0 ; fill at least 510 bytes of data
dw 0xAA55 ;since intel machine is little endian 
;bytes get flipped when working with words
;we go for 0xAA55 aka 0x55AA AKA 511/512 byte, because
;it should contain a boot signature 
;if BIOS finds the signature 
;it will load that sector into origin address 
;and will execute interrupt from bios 
;from that address running our bootloader
;also to mention if we use 510 bytes
;our command wont output anything 
;but if we don't, it'll pad the rest with 0
;lets say we use only five bytes in the code
;then the extra 10 bytes will be filled 
;all the way through with zeros
;and this allows us to just go to next line with dw

