%include "../include/io.mac"

;; defining constants, you can use these as immediate values in your code
LETTERS_COUNT EQU 26

section .data
    extern len_plain

section .bss
    plain_addres resd 1
    enc_addres resd 1
    notch_addres resd 1

section .text
    global rotate_x_positions
    global enigma

; void rotate_x_positions(int x, int rotor, char config[10][26], int forward);
rotate_x_positions:
    push ebp
    mov ebp, esp
    pusha

    mov eax, [ebp + 8]  ; x
    mov ebx, [ebp + 12] ; rotor
    mov ecx, [ebp + 16] ; config (address of first element in matrix)
    mov edx, [ebp + 20] ; forward

    mov esi, ecx

    ;; calculam indicele efectiv al primei linii
    shl ebx, 1 ; ebx = ebx * 2

    ;; calculam offset-ul in octeti fata de primul element al matricii
    imul ebx, LETTERS_COUNT

    ;; calculam addresa primului element din rotorul dorit din matrice
    lea edi, [esi + ebx]

    ;; setam x-ul in functie de directia de siftare
    cmp edx, 0
    je dont_negate
    neg eax
dont_negate:

    ;; aflam numarul de elemente care trebuie siftate
    mov ecx, LETTERS_COUNT
    add eax, ecx ; eax = eax + 26
    div cl
    ;; ecx = nr elemente care trebuie siftate si ies din bound-ul array-ului
    movzx ecx, ah
    mov ebx, ecx

    cmp ebx, 0
    jz no_shifting

    ;; punem pe stack elementele care trebuie siftate si depasesc limita array-ului
    xor eax, eax
push_to_stack:
    mov al, byte[edi + ecx + 25]
    push eax
    mov al, byte[edi + ecx - 1]
    push eax
    loop push_to_stack

    ;; siftam "la stanga" elementele care nu ar iesi din limita
    ;; liniei matricii in urma siftarii
    xor ecx, ecx
    mov esi, LETTERS_COUNT
shift_numbers_in_bound:
    ; ebx = indicele primului element siftat care ramane in limita array-ului
    mov al, byte[edi + ebx]
    mov byte[edi + ecx], al
    mov al, byte[edi + ebx + 26]
    mov byte[edi + ecx + 26], al
    inc ecx  ; ecx reprezinta indicele in linie la care s-a ajuns
    inc ebx
    cmp ebx, esi
    jl shift_numbers_in_bound

    ;; adaugam la finalul liniilor elemtele puse pe stack
add_rest:
    pop eax
    mov byte[edi + ecx], al
    pop eax
    mov byte[edi + ecx + 26], al
    inc ecx
    cmp ecx, esi
    jl add_rest

no_shifting:
    popa
    leave
    ret

; void enigma(char *plain, char key[3], char notches[3], char config[10][26], char *enc);
enigma:
    ;; DO NOT MODIFY
    push ebp
    mov ebp, esp
    pusha

    mov eax, [ebp + 8]  ; plain (address of first element in string)
    mov ebx, [ebp + 12] ; key
    mov ecx, [ebp + 16] ; notches
    mov edx, [ebp + 20] ; config (address of first element in matrix)
    mov edi, [ebp + 24] ; enc
    ;; DO NOT MODIFY
    ;; TODO: Implement enigma
    ;; FREESTYLE STARTS HERE

    mov dword[plain_addres], eax
    mov dword[notch_addres], ecx
    mov dword[enc_addres], edi

    xor ecx, ecx
loop_to_encode_next_letter:
    ;; pregatim criptarea
    push ecx
    mov ecx, [notch_addres]
    push edx
    push ecx
    push ebx
    call prepare_for_encryption
    add esp, 12
    pop ecx

    ;; determinam litera care trebuie criptata
    mov edi, [plain_addres]
    mov al, byte[edi + ecx]
    movzx eax, al

    ;; determinam pozitia literei care trebuie criptata
    sub eax, 'A'

    ;; folosim layerele de criptare in ordinea 4, 2, 1, 0, 3, 0, 1, 2, 4
    ;; eax va stoca rezultatul fiecarui layer de criptare (un indice)
    push 1
    push edx
    push 4
    push eax
    call encrypt_for_one_layer
    add esp, 16

    push 1
    push edx
    push 2
    push eax
    call encrypt_for_one_layer
    add esp, 16

    push 1
    push edx
    push 1
    push eax
    call encrypt_for_one_layer
    add esp, 16

    push 1
    push edx
    push 0
    push eax
    call encrypt_for_one_layer
    add esp, 16

    push 1
    push edx
    push 3
    push eax
    call encrypt_for_one_layer
    add esp, 16

    push 0
    push edx
    push 0
    push eax
    call encrypt_for_one_layer
    add esp, 16

    push 0
    push edx
    push 1
    push eax
    call encrypt_for_one_layer
    add esp, 16

    push 0
    push edx
    push 2
    push eax
    call encrypt_for_one_layer
    add esp, 16

    ;; trecem la final litera prin plugboard in linie dreapta, adica calculam
    ;; offset-ul efectiv al rezultatului
    ;; eax retine practic indicele literei (rezultat) aflata in ultima linie a matricii
    mov esi, LETTERS_COUNT
    imul esi, 9
    add esi, eax
    mov al, byte[edx + esi]
    movzx eax, al

    ;; copiam litera criptata in string-ul rezultat
    mov edi, [enc_addres]
    mov byte[edi + ecx], al

    ;; verificam daca am parcurs tot string-ul
    inc ecx
    mov edi, dword[len_plain]
    cmp ecx, edi
    jl loop_to_encode_next_letter

    ;; FREESTYLE ENDS HERE
    ;; DO NOT MODIFY
    popa
    leave
    ret
    ;; DO NOT MODIFY

    ;; functie auxiliara care prepara rotorii de encriptie in functie de cheie si notch
    ;; actualizeaza si matricea care contine permutarile rotorilor
prepare_for_encryption:
    push ebp
    mov ebp, esp
    pusha

    mov esi, [ebp + 8] ; key
    mov edi, [ebp + 12] ; notches
    mov ebx, [ebp + 16] ; config


    ;; verificam daca ne aflam in cazul special de double stepping cand literele
    ;; din mijloc pentru cheie si notch sunt egale, dar restul literelor sunt diferite

    mov dh, byte[esi + 2] ; key[2]
    mov dl, byte[esi + 1] ; key[1]
    mov cl, byte[esi + 0] ; key[0]
    mov ah, byte[edi + 2] ; notch[1]
    mov al, byte[edi + 1] ; notch[2]
    mov ch, byte[edi + 0] ; key[0]

    cmp dl, al        ; verificam daca key[1] si notch[1] sunt egale
    jne simple_case
    cmp dh, ah        ; verificam daca key[2] si notch[2] nu sunt egale
    je simple_case
    cmp cl, ch        ; verificam daca key[2] si notch[2] nu sunt egale
    je simple_case

    ;; daca am ajuns aici inseamna ca ne aflam in cazul special de double_stepping

    ;; apelam functia de la primul subpunct pentru toate rotoarele
    push 0
    push ebx
    push 2
    push 1
    call rotate_x_positions
    add esp, 16

    push 0
    push ebx
    push 1
    push 1
    call rotate_x_positions
    add esp, 16

    push 0
    push ebx
    push 0
    push 1
    call rotate_x_positions
    add esp, 16

    ;; actualizam cheia (pentru toate elementele)
    mov ecx, 0
shift_one_element:
    push ecx
    push esi
    call update_key
    add esp, 8
    inc ecx
    cmp ecx, 3
    jl shift_one_element

    jmp changed_all_rotors

    ;; cazul clasic cand siftam rotoarele de la rotorul 3 catre primul in functie
    ;; de cate litere din notch si key sunt identice
simple_case:
    mov ecx, 3 ;rotorul care va fi siftat prima data in cazul simplu (cu indice 2)

change_rotors_simple_case:
    cmp ecx, 0
    jz changed_all_rotors
    dec ecx
    ;; apelam functia de la primul subpunct al taskului
    push 0
    push ebx
    push ecx
    push 1
    call rotate_x_positions
    add esp, 16

    ;; salvam valorile cheii inainte de rotire
    mov dh, byte[esi + ecx]

    ;; actualizam noua valoare a cheii
    push ecx
    push esi
    call update_key
    add esp, 8

    ;; verificam daca valoarea cheii era egala cu notch-ul inainte de rotire

    mov dl, byte[edi + ecx]
    cmp dh, dl
    je change_rotors_simple_case

changed_all_rotors:
    popa
    leave
    ret


    ;; functie auxiliara care codeaza o litera printr-un layer de encriptie
encrypt_for_one_layer:
    push ebp
    mov ebp, esp

    push ebx
    push ecx
    push edi
    push esi

    mov ebx, [ebp + 8] ; "indice de start" pentru litera de criptat
    mov ecx, [ebp + 12] ; indicele layer-ului de encriptie
    mov edi, [ebp + 16] ; pointer catre primul element din matrice
    mov esi, [ebp + 20] ; sens de criptare (0 egal de sus in jos, 1 egal de jos in sus)

    ;; calculam offset-ul primului element din layer-ul nostru (fata de adresa
    ;; primului element din matrice)
    imul ecx, LETTERS_COUNT
    shl ecx, 1
    cmp esi, 0
    jz no_extra_offset
    mov esi, LETTERS_COUNT
no_extra_offset:
    add ecx, esi
    push ecx

    ;; calculam offset-ul dintre litera ce trebuie criptata si adresa
    ;; primului element din matrice
    add ecx, ebx

    ;; aflam litera ce trebuie criptata
    mov bl, byte[edi + ecx]
    pop ecx

    cmp esi, 0
    jne element_is_above
    add ecx, LETTERS_COUNT
    jmp continue

element_is_above:
    sub ecx, LETTERS_COUNT

continue:
    xor esi, esi
    ;; cautam in matrice litera pe care vrem sa o criptam
search_letter_loop:
    mov al, byte[edi + ecx]
    inc ecx
    inc esi
    cmp al, bl
    jne search_letter_loop

    ;; ii aflam corespondentul
    dec esi
    mov eax, esi

end:
    pop esi
    pop edi
    pop ecx
    pop ebx
    leave
    ret


    ;; functie auxiliara care sifteaza o valoare a unei chei cu 1 la stanga
update_key:

    push ebp
    mov ebp, esp
    pusha

    mov esi, [ebp + 8]    ;; adresa primului element di cheie
    mov ecx, [ebp + 12]   ;; indicele elementului care se doreste a fi siftat

    ;; salvam valoarea elementului din cheie inainte de rotire
    mov dh, byte[esi + ecx]

    ;; actualizam noua valoare a cheii
    mov al, dh
    sub al, 'A'
    add al, LETTERS_COUNT
    inc al
    movzx ax, al
    mov dl, LETTERS_COUNT
    div dl
    mov dl, ah
    add dl, 'A' ; noul key
    mov byte[esi + ecx], dl

    popa
    leave
    ret
