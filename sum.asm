global sum

; Funkcja wykonująca zadaną w zadaniu operację w miejscu.

; Dla prostoty rozważań, w komentarzach uznajemy układ tablicy
; x o kierunku indeksowania z prawej do lewej [n-1...0], żeby
; móc myśleć o problemie grubokońcówkowo. Wynik będzie mimo to
; cienkokońcówkowy.

; rdi - adres tablicy x
; rsi - n > 0
sum:
	; Znaczenie następujących rejestrów jest niezmienne
	; podczas trwania całego programu:
	; rdi - adres tablicy x[]
	; rsi - n > 0
	; r9 - last, największy indeks komórki, w której mamy
	; policzony dotychczasowy wynik
	; r10 - i, indeks aktualnie rozpatrywanej wartości w x
	; r11 - 64 powielone bity znaku aktualnego wyniku
	xor r9, r9
	xor r10, r10
	mov r11, [rdi]
	sar r11, 63
	
.for_condition:
	inc r10				; i = i + 1
	cmp r10, rsi
	je .return
.for:					; i < n
	; Wartości i, bitu znaku oraz last wyliczone.
	; Sczytaj x[i] do rejestru r8 i wyczyść pamięć.
	xor r8, r8
	xchg r8, [rdi + 8 * r10]
	; Oblicz shift na podstawie wzoru.
	; a) włóż i^2 + 64 do rax, wyzeruj rdx
	mov rax, r10		; i
	shl eax, 3			; i * 8 (musi się zmieścić w 32-bitach)
	mul rax				; i^2 * 64, zeruje rdx
	; b) podziel przez n, wynik w rax, rdx wolny
	div rsi				; / n
	; c) rozdziel na global[pos] i local[offset]
	; (pos: r8, offset: cl)
	mov cl, al			; shift % 64 (jeszcze nie, ale będzie
						; obcięty podczas shld)
	shr rax, 6			; shift / 64
	; Włóż offsetowaną wartość x[i] do rejestrów rdx:rax.
	; Wypełnij rdx bitem znaku x[i] ...
	xchg rax, r8
	cqo
	; ... i przesuń x[i] o offset z rax do rdx.
	; (rdx - high, rax - low)
	shld rdx, rax, cl
	shl rax, cl
	; 1) Jeśli pos >= last, wypełnij komórki od last + 1 do
	; pos + 1 aktualnym bitem znaku.
	jmp .first_while_condition
.first_while:
	inc r9
	mov [rdi + 8 * r9], r11
.first_while_condition:
	cmp r8, r9
	jnb .first_while	; while(pos >= last)

	; 2) Teraz last > pos; dodaj x[i]<<shift do wyniku.

	; Zaraz będziemy potrzebować rcx = 0.
	xor ecx, ecx
	; Dodaj low do x[pos].
	add [rdi + 8 * r8], rax
	; Dodaj high z carry do x[pos + 1].
	adc [rdi + 8 * r8 + 8], rdx
	
	; Zachodzi teraz pos + 2 >= last >= pos + 1,
	; wystarczy zatem dodać carry i bity znaku do x[pos + 2]
	; jeśli pos + 2 = last.

	; Zachowaj CF z poprzedniej operacji w rcx.
	adc cl, 0
	; Niech rdx wypełniony bitem znaku x[i].
	sar rdx, 63
	; Sprawdź czy pos + 2 = last.
	add r8, 2
	cmp r8, r9
	je .pos_2_inbound
	; Przywróć CF do poprzedniego stanu.
	add rcx, 0xffffffffffffffff
	jmp .end_pos_2_check
.pos_2_inbound:
	; Przywróć CF do poprzedniego stanu.
	add rcx, 0xffffffffffffffff
	; Dodaj carry i bity znaku x[i] do x[last].
	adc [rdi + 8 * r8], rdx
.end_pos_2_check:

	; Dodaj bity znaku wyniku i bity znaku x[i] + carry
	; i w zależności od sumy updatuj last oraz bit znaku wyniku.
	adc r11, rdx
	mov rdx, r11
	; Bit znaku na większość bitów sumy (ew. bez najmłodszego).
	sar r11, 1
	; Przesunięcie last jeśli najmłodszy bit inny niż reszta.
	cmp rdx, r11
	je .for_condition
	inc r9
	mov [rdi + 8 * r9], rdx

	; Koniec obrotu pętli.
	jmp .for_condition

.return:
	; Nie trzeba wypełniać pozostałych komórek bitem znaku,
	; bo last = n - 1.
	ret