.code16

.equ INITSEG,0x9000
.equ SYSSEG,0x1000
.equ SETUPSEG,0x9020

.global _start,begtext,begdata,begbss

.text
begtext:
.data
begdata:
.bss
beginbss

.text

ljmp $SETUPSET,$start

_start:
    mov %INITSEG,%ax
    mov %ax,%ds
    #mov %ax,%es
    #mov %ax,%ss
    
    ;AH = 03
    ;BH = video page

    ;on return:
    ;CH = cursor starting scan line (low order 5 bits)
    ;CL = cursor ending scan line (low order 5 bits)
    ;DH = row
    ;DL = column
    #get the location of cursor
    mov $0x03,%ah
    xor %bh,%bh
    int $0x10
    #save the location of cursor and it stand about two bytes
    mov %bx,%ds:0
    
    ;INT 15,88 - Extended Memory Size Determination
    ;AH = 88h
    ;
    ;on return:
    ;CF = 80h for PC, PCj
    ; = 86h for XT and Model 30
    ;= other machines, set for error, clear for success
    ;AX = number of contiguous 1k blocks of memory starting
    ;at address 1024k (100000h)
    #get the memory size and it stand about two bytes
    mov %0x88,%ah
    int $0x15
    mov %ax,%ds:2

    #

    
   







    #get the four sectors of  setup from disk
    ; INPUT:  DL=Drive
;         CH=Cylinder
;         DH=Head
;         CL=Sector
;         AX=SectorCount
;         ES:BX=Buffer
; OUTPUT: CF=0 AH       = 0
;              CH,DH,CL = CHS of following sector
;         CF=1 AH       = Error status
;              CH,DH,CL = CHS of problem sector
   








