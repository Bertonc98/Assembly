#La mappa dei nemici all'indirizzo 0x10008000
#Mappa posizionamento giocatore indirizzo 0x10040000 (heap)
#sparati dal giocatore 0x10000000
#256x256, 32x32
.data	
	name: .asciiz "Inserisci il tuo nome:"
	msg: .asciiz "Testa (0) o croce(1)?"
	t:   .asciiz "Hai scelto testa"
	c:   .asciiz "Hai scelto croce"
	W:   .asciiz "Vinto"
	P:   .asciiz "Perso"
	N:   .asciiz "E' uscito: "
	x:   .asciiz "Inserire la colonna"
	y:   .asciiz "Inserire la riga"
	sht: .asciiz "Inizio fase di sparo"
	p_w: .asciiz "Bravissimo "
	e_w: .asciiz "Vince il computer"
	ex:  .asciiz "Gioco sospeso"
	.align 2
	p_sht: .space 1
	.align 2
	e_sht: .space 1
	.align 2
	nome: .space 16
	.align 2
	enemy: .space 256
	player: .space 256
	
	
.text
.globl main
main:	
start:
	li $v0, 54		#chiedo il nome
	la $a0, name
	la $a1, nome
	li $a2, 10
	syscall	
	
	li $v0, 51		#chiedo testa o croce (0/1)
	la $a0, msg
	syscall
	
	add $t0, $a0, $zero	#salvo in t0 la scelta
	add $t1, $t0, $zero	#copio il valore per il controllo in t1
		
	beqz $t1, testa		#se è 0 lo faccio andare all'apposito controllo
	sub $t1, $t1, 1		#sottraggo se non è 0
	beqz $t1, croce		#se ora è 0 significa che prima era 1, e vado a croce
	j start			#se ancora non è 0 era sbagliato e richiedo
	
testa:
	li $v0, 55	#informo di cosa ha scelto
	la $a0, t
	li $a1, 1
	syscall
	j rand
croce:
	li $v0, 55	#informo di cosa ha scelto
	la $a0, c
	li $a1, 1
	syscall
	j rand

rand:
	li $v0, 42	#genero random (tra 0 e 1)
	la $a0, 0	#seed
	li $a1, 2	#top
	syscall
	
	move $t2, $a0	#salvo il numero generato in t2
	
	li $v0, 56	
	la $a0, N		#con il rispettivo messaggio
	add $a1, $t2, $zero	#dico che numero è uscito
	syscall
	
	beq $t2, $t0, win	#se uguali salto a win sennò a lose
	j lose
win:	
	li $v0, 55	#comunico la vittoria
	la $a0, W
	li $a1, 1
	syscall
	
	li $s3, 1	#salvo per il futuro se ha vinto 
	
	j posPlayer
lose:
	li $v0, 55	#comunico la sconfitta
	la $a0, P
	li $a1, 0
	syscall
	
	li $s3, 0	#salvo per il futuro se ha perso 
	
	j posPlayer
	
posPlayer:
	li $s2, 3
	li $t9, 0x00ff00
	
pos:		
	li $v0, 51	#richiedo la riga 
	la $a0, x
	syscall
	
	bgt $a0, 7, pos		#se fuori non colora
	
	add $t8, $a0, $zero	#salvo colonna
	mul $t8, $t8, 4		#moltiplico per il giusto indirizzo di colonna
	
	li $v0, 51	#richiedo la colonna 
	la $a0, y
	syscall
	
	bgt $a0, 7, pos		#se fuori non colora
	
	add $t7, $a0, $zero	#salvo riga
	
	mul $t7, $t7, 32	#moltiplico per il giusto indirizzo di riga
	
	li $s0, 0x10040000	#coloro la posizione
	add $s5,$s0, $zero	#copio l'indirizzo base
	add $s5, $s5, $t8	#aggiungo la colonna
	add $s5, $s5, $t7	#aggiungo la riga
	
	lw $t6, ($s5)		#copio il contenuto di quella posizione in memoria
	bnez $t6, pos		#se non è zero, significa che c'è già un colore, e ci ho già scritto
				#per questo faccio reinserire in un'altra posizione
	
	sw $t9, ($s5)		#coloro la cella di memoria se è una posizione consentita
	
	sub $s2,$s2, 1		#tolgo un piazzamento
	
	bgt $s2, $zero, pos	#se ho ancora le navi da piazzare rifaccio
	
	j posCmp	#posizionamento del computer

posCmp:
	
	li $s2, 3
	li $t9, 0x0000ff	#imposto un valore per le navi nemiche
		
	li $t0, 3		#numero di navi da posizionare
	
used:	
	la $s7, enemy		#indirizzo base, uso 0x10008000 per vedere dove posiziona ($gp)
cmp_colonna:
	li $v0, 42		#genero random nel campo
	la $a0, 0
	li $a1, 8
	syscall
	
	bgt $a0, 7, cmp_colonna #assicuro che sia nel campo

	move $t4, $a0		#salvo colonna
	mul $t4, $t4, 4		#calcolo la giusta colonna
cmp_riga:
	li $v0, 42		#genero random
	la $a0, 0
	li $a1, 8
	syscall
	
	bgt $a0, 7, cmp_riga	#assicuro che sia nel campo
	
	move $t3, $a0		#salvo riga
	mul $t3, $t3, 32	#calcolo la giusta riga
	
	li $s0, 0x10008000	#coloro la posizione
	add $s7,$s0, $zero	#copio l'indirizzo base
	add $s7, $s7, $t3	#aggiungo all'indirizzo base la riga
	add $s7, $s7, $t4	#aggiungo all'indirizzo base la colonna

	lw $s4, ($s7)		#carico il contenuto dell'indirizzo calcolato
	
	bnez $s4, posCmp	#controllo se ci ha già scritto (in base al contenuto dell'indirizzo)
	
	sw $t9, ($s7)		#se non ancora utilizzato salvo la posizione

	sub $t0, $t0, 1		#tolgo una nave
	
	bgt $t0, $zero, used	#se non ho finito le navi richiedo
	
	li $t0, 3		#contatore per settare le navi da distruggere
	
	sw $t0, p_sht		#navi che il giocatore deve distruggere
	sw $t0, e_sht		#navi che il computer deve distruggere
	
	beqz $s3, computerGame	#se ha perso a testa o croce inizia il computer
	
	sub $s3,$s3,1 
	
	beqz $s3, playerGame	#se ha vinto a testa o croce inizia il giocatore
	

computerGame:
	#Il computer userà l'indirizzo di mappa del giocatore per verificare se effetticamente colpisce
	#e per verificare dove ha già sparato
	li $v0, 42		#genero random nel campo
	la $a0, 0
	li $a1, 8
	syscall
	
	move $t4, $a0		#salvo colonna
	
	li $v0, 42		#genero random
	la $a0, 0
	li $a1, 8
	syscall
	
	move $t3, $a0		#salvo riga
	
	mul $t4, $t4, 4		#calcolo la giusta colonna
	mul $t3, $t3, 32	#calcolo la giusta riga
	
	la $a0, 0x10040000
	add $a0, $a0, $t4	#posizione da visualizzare
	add $a0, $a0, $t3
	move $a1, $a0	
	
	jal controllopos
	
	beq $v0, 1, cmp_colpito
	
	j playerGame

cmp_colpito:
	lw $t6, e_sht
	sub $t6, $t6, 1
	beqz $t6, cmp_win
	sw $t6, e_sht
	j playerGame

cmp_win:
	li $v0, 55	
	la $a0, e_w
	syscall
	li $v0, 10
	syscall
	

playerGame:
	li $v0, 55	#comunico l'inizio del gioco
	la $a0, sht
	li $a1, 1
	syscall
p_game_pos:
	li $v0, 51	#richiedo la riga 
	la $a0, x
	syscall
	
	beq $a0, 8 end_exit
	
	bgt $a0, 7, p_game_pos		#se fuori non colora
	
	move $t8, $a0
	
	li $v0, 51	#richiedo la colonna 
	la $a0, y
	syscall
	
	bgt $a0, 7, p_game_pos		#se fuori non colora
	move $t9, $a0
	
	mul $t8, $t8, 4		#calcolo la giusta colonna
	mul $t9, $t9, 32	#calcolo la giusta riga
	
	la $a0, 0x10000000
	add $a0, $a0, $t8	#posizione da visualizzare
	add $a0, $a0, $t9
	
	la $a1, 0x10008000
	add $a1, $a1, $t8	#posizione sul campo nemico
	add $a1, $a1, $t9	
	
	jal controllopos
	
	move $a1, $v0		#salvo il valore dello sparo
	beq $a1, 1, p_colpito

p_void:
	j computerGame
p_colpito:
	lw $t0, p_sht
	sub $t0, $t0, 1	#se coloisce una nave decrementa
	sw $t0, p_sht
		
	beqz $t0, end_p
	syscall
	
	j computerGame
	
end_p:	
	
	li $v0, 59		
	la $a0, p_w
	la $a1, nome
	syscall
	li $v0, 10
	syscall
end_exit:	
	li $v0, 55	
	la $a0, ex	
	syscall
	
	li $v0, 10
	syscall

controllopos:
	#alloco nello stack lo spazio per salvare i registr1 $s1 e $s0
	subu $sp, $sp, 12
	sw $fp, 8($sp)
	sw $s1, 4($sp)
	sw $s0, 0($sp)
	addiu $fp, $sp, 8
	
	#una volta salvati e al sicuro posso esegurie le istruzioni
	#$a0 posizione sul campo visualizzato
	#$a1 posizione sul campo nemico
	
	lw $t0, ($a1)			#carico contenuto della cella $a1 in $t0
	li $t6, 0x0000ff
	beq $t0, $t6, colpito		#se il giocatore colpisce 
	lw $s5, ($a1)
	beq $t0, 0x00ff00, colpito	#se il computer colpisce
	beq $t0, 0xff0000, nullo	#se sparo dove ho già colpito non segno nulla
	lw $t0, ($a0)
	beqz $t0, vuoto	
	
	j usato
	
vuoto:	
	li $t1, 0xffffff
	sw $t1, ($a0)		#carico il colore del colpo
	li $v0, 0		#0=colpo a vuoto	
	j return
	
colpito:
	li $t2, 0xff0000
	sw $t2, ($a0)		#carico il colore del colpo
	li $v0, 1		#1=colpito
	j return
	
usato:
	li $t1, 0xffffff
	sw $t1, 0($a0)		#carico il colore del colpo
	li $v0, 2		#2=già sparato li
	j return
nullo:
	li $v0, 3		#2=già sparato li
	j return

return:
	
	lw $s0, 0($sp)
	lw $s1, 4($sp)
	lw $fp, 8($sp)
	addi $sp, $sp, 12
	
	jr $ra
