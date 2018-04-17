bits 16
org 0x7C00

cli
				
mov ah , 0x02
mov al ,8
mov dl , 0x80
mov ch , 0
mov dh , 0
mov cl , 2
mov bx, startingTheCode
int 0x13
jmp startingTheCode

times (510 - ($ - $$)) db 0
db 0x55, 0xAA

;----------------------------------------------------------------------------------------------;

startingTheCode:

cli
	xor eax,eax
	mov ds,ax
	mov es,ax
	mov edi, 0xB8000;
	mov esi, 0xB8000;
	xor ebx,ebx;
	xor ecx,ecx;
	xor edx, edx;
	xor esi,esi;
	mov sp , 0xffff

;----------------------------------------------------------------------------------------------;
        ;// getting our screen ready //
        pushad 
        mov eax,80                        ; colomns 
        mov ecx,25                        ; rows
        mul ecx                           ; total elements
        xor ecx,ecx                       ; counter
        mov esi,edi                       ; char byte
        inc esi                           ; color byte
        char_color:
        mov byte[edi+ecx*2],0             ; null value
        mov byte[esi+ecx*2],0x7           ;color black
        inc ecx
        inc edx
        cmp ecx,eax
        jl char_color
        popad 
;----------------------------------------------------------------------------------------------;

mov bx,ScanCodeTable1                    ; default table 


get_char:
in al,0x64      
and al,0x01
jz get_char
in al ,0x60                             ;char   

                     ;;;///comparisions///;;; 

;-------------------------------------------------------------------------------------------;                                       

caps_lock:
cmp al,0x3a
jne A_char
cmp byte[capslock_stat],1
jne L0
mov byte[capslock_stat],0
mov bx,ScanCodeTable1
L0:
mov byte[capslock_stat],1
mov bx,ScanCodeTable3

                                                         
                                                                                                                                                                           
A_char:
cmp al ,0x1e                            ;scan code for make of A char
jne v_char
cmp byte[ctrl_status],1
je select_all
jmp print_char


v_char:
cmp al ,0x2f                            ;scan code for make of V char
jne x_char
cmp byte[ctrl_status],1
je paste
jmp print_char

x_char:
cmp al,0x2d                             ;scan code for make of X char
jne c_char
cmp byte[ctrl_status],1
je cutt
jmp print_char

c_char:                                 ;scan code for make of C char
cmp al,0x2e
jne Lctrl
cmp byte[ctrl_status],1
jne print_char
call copy
jmp get_char


Lctrl:
cmp al,0x1d                             ;scan code for make of left ctrl
jne break_Lctrl
mov byte[ctrl_status],1
jmp get_char


break_Lctrl:
cmp al,0x9d                            ;scan code for break of left ctrl
jne enterr
mov byte[ctrl_status],0
jmp get_char


enterr:
cmp al, 0x1c                           ;scan code for make of enter 
je ent 


TAP:
cmp al ,0x0f                          ;scan code for make of a Tap
je tap


back_space:
cmp al ,0x0e                          ;scan code for make of backspace
je backspace



shifts:

Left_shift:
cmp al,0x2A                           ;scan code for make of left shift    
jne Right_shift

mov bx,ScanCodeTable2
mov byte[shift_status],1
jmp get_char



Right_shift:
cmp al, 0x36                          ;scan code for make of right shift
jne Leftshift_break
mov bx,ScanCodeTable2
mov byte[shift_status],1
jmp get_char


Leftshift_break:
cmp al,0xAA                           ;scan code for break of left shift
jne Rightshift_break
mov bx,ScanCodeTable1
mov byte[shift_status],0
jmp get_char



Rightshift_break:
cmp al,0xB6                          ;scan code for break of right shift
jne keys_with_queue
mov bx,ScanCodeTable1
mov byte[shift_status],0
jmp get_char


keys_with_queue:

cmp al,0xe0                         ; first byte in queue
jne print_char

get_second_byte:
in al,0x64      
and al,0x01
jz get_second_byte
in al ,0x60                           ; second  byte in queue


arrows_withLshift:
cmp al,0xaa                           ; second  byte in make of Lshift_arrow queue
je shaddow 

arrows_withRshift:
cmp al ,0xb6                         ; second  byte in make of Rshift_arrow queue 
je shaddow


ordinary_arrows:  
up_arrow:
cmp al,0x48                         ;make code for  up arrow
jne Left_arrow

;perform up arrow 
cmp byte[isthereshaddowing?],0
je L1
call re_color                      ; remove shaddow first 
L1:
cmp edi,0xB80A0                    ; is edi in the first line? (0xb8000+160=0xb80a0) start of the second line
jl get_char                        ; if in first line / row , dont go up 
sub edi,160                        ; go up
L2:                                ; find the last char occurence in the new line to place the cursor at 
cmp byte[edi-2],0x0                ;is it a null value  ?
jne cursor                         ; no, place cursor 
sub edi,2                          ; go to the previous char and check
jmp L2
              






Left_arrow:
cmp al,0x4b                       ;make code for left arrow
jne down_arrow

cmp byte[isthereshaddowing?],0
je L3
call re_color                      ; remove shaddow first

;perform left arrow
L3:
cmp edi,0xB8000                   ;is edi first char in screen?
je get_char                       ; cant go left
sub edi,2
L4:                              ;find the last char in the new line to place the cursor at
cmp byte[edi],0x0 
jne cursor  
sub edi,2
jmp L4      






down_arrow:
cmp al,0x50                     ;make code for down arrow
jne right_arrow
cmp byte[isthereshaddowing?],0
je L5
call re_color
L5:
mov eax,0xb8fa0          ; last byte in screen [color of last char]
sub eax,160             ; line/row before the last
cmp edi,eax             ; is edi in the last line/row?
jg get_char             ; yes,dont go down
;perform down_arrow
add edi,160
L6:                     ;find the last char in the new line to place the cursor at
cmp byte[edi-2],0x0
jne cursor  
sub edi,2
jmp L6
          





right_arrow:
cmp al,0x4d                             ;make code for right arrow
jne  Rctrl
cmp byte[isthereshaddowing?],0
je L7
call re_color                           ; remove shaddow first
;perform right arrow
L7:
cmp edi,0xb8f9f                        ; is edi last char in screen?
je get_char                            ; yes, dont go right
add edi,2
L8:
cmp byte[edi-2],0x0                  ; if edi is at the last char pressed in the screen
jne cursor                           ; dont go right
sub edi,2                            ; if edi is at the last char pressed in the line
xor edx,edx
mov eax,edi
sub eax,0xB8000 ; to start counting from zero rathar than 0xB8000
mov ecx,160
div ecx ; eax / ecx
; modulus in edx
; edx now is the offset from the start of the line
; value should be added to edi to go to the next line : 160-edx
sub edx,160
neg edx
add edi,edx                       ;go to the start of the next line
cmp byte[edi],0x0
jne cursor
sub edi,edx
jmp cursor






Rctrl:
cmp al ,0x1d                  ;scan code for make of right ctrl
jne break_Rctrl
mov byte[ctrl_status],1
jmp get_char






break_Rctrl:
cmp al ,0x9d                    ;scan code for break of right ctrl
jne home 
mov byte[ctrl_status],0
jmp get_char






home:
cmp al,0x47                     ;scan code for make of home key
jne end 
cmp byte[isthereshaddowing?],0
je L9 
call re_color                 ;remove shaddow first 
L9: 
xor edx,edx
mov eax,edi
sub eax,0xB8000              ; to start counting from zero rathar than 0xB8000
mov ecx,160
div ecx                     ; eax / ecx
                            ; edx is offset from start of the line 
sub edi,edx                 ;go to the start of the line 
jmp cursor





end:
cmp al,0x4f                      ;scan code for make of end key
jne delete
cmp byte[isthereshaddowing?],0
je L10
call re_color
L10:
xor edx,edx
mov eax,edi
sub eax,0xB8000 ; to start counting from zero rathar than 0xB8000
; edi is not affected
mov ecx,160
div ecx ; eax / ecx
mov esi,edi
sub esi,edx                   ; start of line
sub edx,160
neg edx
add edi,edx                   ;start of next line
sub edi,2                     ; end of current line 
L11:
cmp byte[edi],0x0             ;is it null?
jne L12                       ;no,place cursor
sub edi,2
cmp edi,esi                   ; start of line?
jg L11                       
L12:
jmp cursor








delete:
cmp al,0x53                            ;scan code for make of delete key                    
jne get_char 
cmp byte[isthereshaddowing?],1
jne L13
call deleteShaddow                     ; delete shaddowed string 
jmp cursor
L13:
mov eax,edi
sub eax,0xb8f9f             ;is edi at last char position  in screen ?
cmp eax , 0                 ;yes, cant delete
je get_char
add edi,2 
pushad 
mov esi,edi
dec esi
dec esi
mov byte [esi] , 0x0;
popad
pushad
mov ecx,edi       ; next char pointer
L14:
mov al,[edi]      ;get the char in it 
mov esi,edi       ; calculate where we want to shift the char
dec esi
dec esi
mov [esi],al      ; put it 
cmp al,0
je out2
inc edi           ; now get the color and do the same 
add ecx,0x1       ; counter from current edi 
cmp ecx ,0xb8fa0   ;  end of the screen ?
jle L14

out2:
popad              
sub edi,2
jmp cursor	

;*************************************************************************************************************************

                         ;;;///operations and functions///;;;
                         
;**************************************************************************************************************************
                         
copy:
pushad 
mov esi ,0xb8000                          
xor ecx ,ecx
L15:
cmp byte[esi+1],0x16                   ; check for shaddowed char
jne L16
mov al,[esi]
mov byte[shaddowed_string+ecx*1],al    ;store that shaddowed charin memory
inc ecx
L16:
add esi,2
cmp esi, 0xb8fa0
jl L15
popad
ret

;***************************************************************************************************************

paste:
xor ecx,ecx
L17:                    ; make space for insertion of one char 
push ecx
mov esi,edi
mov cl,[esi]
L18:                    ; shift string on the right of edi to the right by 2 bytes (one char) 
mov dl,cl
add esi,2
mov cl,[esi]
mov [esi],dl
cmp cl,0                ; is it last char ?
je L19                  ; yes, all string is shifted 
jmp L18                 ; no , continue shifting 
L19:
pop ecx
mov al,[shaddowed_string+ecx*1]      ; get char from copied string in memroy one at a time  
cmp al,0                             ; end of copied string?
je endPaste                          ; yes, paste is done 
mov [edi],al                         ; insert the char at edi                     
inc edi                              
inc edi                              ; point to next char in screen
inc ecx                              ; next char in copied string
jmp L17

endPaste:
jmp cursor                            ; place cursor


;************************************************************************************************************

cutt:
call copy                            ; copy shaddowed string
call deleteShaddow                   ; delete that string
jmp get_char                         
                         
;****************************************************************************************************************                         
                         
select_all:
pushad
mov esi,0xb8000                       ; first char in screen
L20: 
cmp byte[esi],0x0                     ; is it null?
je L21                                ; yes,go to next char
mov byte[esi+1],0x16                  ; no , shaddow the char
mov byte[isthereshaddowing?],1        ; shaddowed occured
L21:
add esi,2
cmp esi ,0xb8fa0                      ; end of screen?
jl L20                                ;no ,  repeat 
popad                                 ;yes, done 
jmp get_char 

;*****************************************************************************************************************
ent:
cmp byte[isthereshaddowing?],1       ; is there shaddowing        
jne L22                              ;perform enter
call deleteShaddow                   ;delete shaddowed string first
L22:                                 ; perform enter
mov eax,edi
sub eax,0xb8000                      ; offset from start of screen
mov ecx,160
xor edx,edx
div ecx                              ;division result is the row/line index from(0 to 24)
cmp al,24                            ; is edi in the last line/row?
je get_char                          ;yes, there is no next line , dont perform enter
;no, perform enter
xor edx,edx
mov eax,edi
sub eax,0xB8000             ; to start counting from zero rathar than 0xB8000
                            ; edi is not affected
mov ecx,160
div ecx ; eax / ecx
; modulus in edx
; edx is offset from start of line
; value should be added to edi to go to the next line : 160-edx
sub edx,160
neg edx
pushad 
mov ecx,0
mov esi,edi
mov eax,0xb8fa0
sub eax,edx
L23:                              ; store string from [edi] to [eax] (eax = 0xb8fa0-edx)
mov al,[esi]
mov byte[storage+ecx*1],al
inc ecx
add esi,2
cmp esi,eax                       ;end of stroing?
jle L23                           ; no , keep storing
                                  ; yes, store back with an offset edx from old position
mov esi,edi
add esi,edx
mov ecx,0
L24:
mov al,[storage+ecx*1]           ; first char
mov [esi],al                     ; store back 
inc ecx                          ; next stored char
add esi,2                        ; point to next position in screen
cmp esi, 0xb8fa0                 ; end of screen ?
jle L24                          ; no, keep storing back
; yes, delete chars from edi to end of line
mov eax,edi
add eax,edx                        
sub eax,2                       ; last char in the line
mov esi,edi

L25:
mov byte [esi] , 0x0         ; delete by placing a null 
add esi,2
cmp esi,eax
jle L25
popad
add edi,edx                  
jmp cursor                  ; place cursor at the start of next line


;**************************************************************************************************************
tap:
cmp byte[isthereshaddowing?],1
jne L26
call deleteShaddow                ;delete shaddowed string first
;perform a tap
L26:
pushad 
mov ecx,0
mov esi,edi
L27:
mov al,[esi]
mov byte[storage+ecx*1],al       ; store string on the right from edi to 0xbfa (0xb8fa0-6)
inc ecx
inc esi
cmp esi,0xb8f9a
jle L27
mov esi,edi
add esi,0x6
mov ecx,0
L28:
mov al,[storage+ecx*1]     ; store back
mov [esi],al
inc ecx
inc esi 
cmp esi, 0xb8fa0 
jle L28
popad
mov byte [edi] , 0x0          ; delete 3 chars by placing a null
add edi,2 
mov byte [edi] , 0x0
add edi,2
mov byte [edi] , 0x0
add edi,2
jmp cursor
;********************************************************************************************************************
backspace:        
cmp byte[isthereshaddowing?],1
jne L29
call deleteShaddow
jmp cursor

L29:
pushad 
mov eax,edi
sub eax,0xb8000
cmp eax , 0
je get_char
mov esi,edi
dec esi
dec esi
mov byte [esi] , 0x0 ; delete previous char

popad
back:
pushad
mov ecx,edi       ; next char pointer
L30:
mov al,[edi]      ;get the char in it 
mov esi,edi       ; calculate where we want to shift the char
dec esi
dec esi
mov [esi],al      ; put it 
cmp al,0
je out3
inc edi           ; now get the color and do the same 
add ecx,0x1       ; counter from current edi 
cmp ecx ,0xb8fa0   ;  end of the screen ?
jle L30
out3:
popad              

sub edi,2
cmp byte[edi-2],0x0  ; if there is a null keep deleting 
je back


jmp cursor	;place cursor
;**********************************************************************************************************************************
shaddow:

get_third_byte:            
in al,0x64      
and al,0x01
jz get_third_byte

in al ,0x60 
cmp al,0xe0                        ; third byte in scan code for make shift_arrow queue
jne get_char

get_fourth_byte:
in al,0x64      
and al,0x01
jz get_fourth_byte
in al ,0x60                      ; fourth byte in scan code for make shift_arrow scan code queue       


leftshaddowing: 
cmp al,0x4b                       ; shadowing with left arrow 
jne rightshaddowing 
mov eax,edi
sub eax,0xb8000                   
cmp eax,0                           ; is edi points to first char in screen ?
je get_char                         ; yes,dont perform shaddowing 
;no, perform shaddowing 
sub edi,2
pushad
mov esi,edi
cmp byte[esi],0                    ;is it null?
je L31                             ;yes, dont perform shaddowing
inc esi
cmp byte[esi],0x16                 ; is char already shaddowed?
jne L32                            ; no , shaddow it
mov byte[esi],0x07                 ;yes,unshaddow
cmp byte[esi-2],0x16
jne cursor
MOV BYTE[isthereshaddowing?],0       ; shaddow didnt  occur
jmp cursor
L32: 
mov byte[esi],0x16
L31:
popad
MOV BYTE[isthereshaddowing?],1          ; shaddowing occured
jmp cursor




 

rightshaddowing:
cmp al,0x4d                        ; fourth byte for shadowing with right arrow scan code queue 
jne  downshaddowing
add edi,2
mov esi,edi
cmp byte[esi-2],0                   ;is it nul?
je L33                              ; yes,dont perform shaddowing
dec esi
cmp byte[esi],0x16                  ; is char already shaddowed?
jne L34                             ; no , shaddow it
mov byte[esi],0x07                   ; yes, unshaddow
cmp byte[esi+2],0x16
jne cursor
MOV BYTE[isthereshaddowing?],0
jmp cursor
L34:
mov byte[esi],0x16
MOV BYTE[isthereshaddowing?],1
L33:
jmp cursor






downshaddowing:
cmp al,0x50                           ; fourth byte for shadowing with down arrow queue
jne upshaddowing
pushad
mov eax,edi
sub eax,0xb8000
mov ecx,160
xor edx,edx
div ecx
cmp al,24
je get_char   

mov esi,edi
inc esi
mov ecx,0
L35:
;; ### check if it's null
cmp byte[esi-1],0
je L36 ; don't change it's color
cmp byte[esi],0x16
jne L37
mov byte[esi],0x07
jmp L36
L37:
mov byte[esi],0x16
L36:
add esi,2
inc ecx
cmp ecx,80
;jle L35
jl L35
popad 
add edi,160
cmp byte[esi],0x16
je L38
MOV BYTE[isthereshaddowing?],0
jmp cursor
L38:
MOV BYTE[isthereshaddowing?],1
jmp cursor


upshaddowing:
cmp al,0x48                                  ; fourth byte for shadowing with up arrow queue 
jne print_char                                                  
pushad
mov eax,edi
sub eax,0xb8000
mov ecx,160
xor edx,edx
div ecx
cmp al,0
je get_char
mov esi,edi
dec esi
mov ecx,0
L39:
;; ### check if it's null
cmp byte[esi-1],0
je L40 ; don't change it's color
cmp byte[esi],0x16
jne L41
mov byte[esi],0x07
jmp L40
L41:
mov byte[esi],0x16
L40:
sub esi,2
inc ecx
cmp ecx,80
jl L39
popad 
sub edi,160
cmp byte[edi-2],0x16
je L42
MOV BYTE[isthereshaddowing?],0
jmp cursor

L42:
MOV BYTE[isthereshaddowing?],1
jmp cursor



;*******************************************************************************************************************
deleteShaddow:
mov byte[isthereshaddowing?],0
cmp byte[edi-1],0x16
je delete2
delete1:
add edi,2 
pushad 
mov eax,edi
sub eax,0xb8000
cmp eax , 0
je get_char
mov esi,edi
dec esi
dec esi
mov byte [esi] , 0x0;

popad

pushad
mov ecx,edi       ; next char pointer
lq8:
mov al,[edi]      ;get the char in it 
mov esi,edi       ; calculate where we want to shift the char
dec esi
dec esi
mov [esi],al      ; put it 
cmp al,0
je out1
add edi,2          ; now get the color and do the same 
add ecx,0x1       ; counter from current edi 
cmp ecx ,0xb8fa0   ;  end of the screen ?
jle lq8

out1:
popad              

sub edi,2
cmp byte[edi+1],0x16
je delete1
ret
delete2:      ; by bkspace
pushad 
mov eax,edi
sub eax,0xb8000
cmp eax , 0
je get_char
mov esi,edi
dec esi
dec esi
mov byte [esi] , 0x0;

popad

pushad
mov ecx,edi       ; next char pointer
l8w:
mov al,[edi]      ;get the char in it 
mov esi,edi       ; calculate where we want to shift the char
dec esi
dec esi
mov [esi],al      ; put it 
cmp al,0
jne l8w
         ; now get the color and do the same 
;add ecx,0x1       ; counter from current edi 
;cmp ecx ,0xb8fa0   ;  end of the screen ?
;jle l8w
popad              

sub edi,2
cmp byte[edi-1],0x16
je delete2
ret

;*****************************************************************************************************************************

re_color:                       ; remove shaddow
pushad 
mov edi ,0xb8000                 ; first char in screen
mov eax,80
mov ecx,25
mul ecx                          ; to go over all screen
xor ecx,ecx
inc edi                         ;color byte
L43:
mov byte[edi+ecx*2],0x7         ; turn black
inc ecx                         ; next char color 
cmp ecx,eax                      ; last color byte?
jl L43                           ; no,keep colooring
        
popad                           ; yes, done
mov byte[isthereshaddowing?],0  ; screeen unshaddowed
ret

;*********************************************************************************************************************;

print_char:           ; default operation 
cmp al,0x80           ; is scan code sent is make of a char?
ja get_char           ; no, go wait for make
cmp byte[isthereshaddowing?],1          ; is there shaddowed string?
jne L44                                 ;no,insert the char    
call deleteShaddow                       ;yes,delete the shaddowed string first then insert
L44:
xlat                                     
cmp edi,0xb8f9f                        ; after last char in screen?
jg get_char                            ; cant insert
mov esi,edi                           ; no , perform printing
mov cl,[esi]
L45:
mov dl,cl
add esi,2
mov cl,[esi]
mov [esi],dl
cmp cl,0
je L46
jmp L45
L46:
mov [edi],al
inc edi
inc edi


cursor:
pushad
mov eax,edi
     sub eax,0xb8000
    
     mov ecx,160
     xor edx,edx
     div ecx
     ; row in al , col in dl * 2
     mov ah,2
     mov bh,0
     mov dh,al;row
     ; col in dl
     shr dl,1; div 2 
     int 0x10; interrupt of cursor position 
     ;cmp byte[shiftget_char],0
     popad
    
jmp get_char 

;/////////////////////////////////////////////////////////////////////////////////////////////////////////;









;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

ScanCodeTable1: db "//1234567890-=//qwertyuiop[]//asdfghjkl;//'/zxcvbnm,.//// /"
ScanCodeTable2: db '//!@#$%^&*()_+//QWERTYUIOP{}//ASDFGHJKL://"/ZXCVBNM<>?/// /'
ScanCodeTable3: db "//1234567890-=//QWERTYUIOP[]//ASDFGHJKL;//'/ZXCVBNM,.//// /"
shift_status: db 0
shaddowed_string: times(2001) db 0
isthereshaddowing?: db 0
ctrl_status: db 0
storage:  times(2000)db 0
capslock_stat: db 0
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

times (0x400000 - 512) db 0

db 	0x63, 0x6F, 0x6E, 0x65, 0x63, 0x74, 0x69, 0x78, 0x00, 0x00, 0x00, 0x02
db	0x00, 0x01, 0x00, 0x00, 0xFF, 0xFF, 0xFF, 0xFF, 0xFF, 0xFF, 0xFF, 0xFF
db	0x20, 0x72, 0x5D, 0x33, 0x76, 0x62, 0x6F, 0x78, 0x00, 0x05, 0x00, 0x00
db	0x57, 0x69, 0x32, 0x6B, 0x00, 0x00, 0x00, 0x00, 0x00, 0x40, 0x00, 0x00
db	0x00, 0x00, 0x00, 0x00, 0x00, 0x40, 0x00, 0x00, 0x00, 0x78, 0x04, 0x11
db	0x00, 0x00, 0x00, 0x02, 0xFF, 0xFF, 0xE6, 0xB9, 0x49, 0x44, 0x4E, 0x1C
db	0x50, 0xC9, 0xBD, 0x45, 0x83, 0xC5, 0xCE, 0xC1, 0xB7, 0x2A, 0xE0, 0xF2
db	0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00
db	0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00
db	0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00
db	0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00
db	0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00
db	0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00
db	0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00
db	0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00
db	0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00
db	0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00
db	0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00
db	0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00
db	0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00
db	0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00
db	0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00
db	0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00
db	0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00
db	0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00
db	0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00
db	0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00
db	0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00
db	0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00
db	0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00
db	0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00
db	0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00
db	0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00
db	0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00
db	0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00
db	0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00
db	0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00
db	0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00
db	0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00
db	0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00
db	0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00
db	0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00
db	0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00