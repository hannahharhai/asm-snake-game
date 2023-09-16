# Hannah Harhai
# heh55

# Cardinal directions.
.eqv DIR_N 0
.eqv DIR_E 1
.eqv DIR_S 2
.eqv DIR_W 3

# Game grid dimensions.
.eqv GRID_CELL_SIZE 4 # pixels
.eqv GRID_WIDTH  16 # cells
.eqv GRID_HEIGHT 14 # cells
.eqv GRID_CELLS 224 #= GRID_WIDTH * GRID_HEIGHT

# How long the snake can possibly be.
.eqv SNAKE_MAX_LEN GRID_CELLS # segments

# How many frames (1/60th of a second) between snake movements.
.eqv SNAKE_MOVE_DELAY 12 # frames

# How many apples the snake needs to eat to win the game.
.eqv APPLES_NEEDED 20

# ------------------------------------------------------------------------------------------------
.data

# set to 1 when the player loses the game (running into the walls/other part of the snake).
lost_game: .word 0

# the direction the snake is facing (one of the DIR_ constants).
snake_dir: .word DIR_N

# how long the snake is (how many segments).
snake_len: .word 2

# parallel arrays of segment coordinates. index 0 is the head.
snake_x: .byte 0:SNAKE_MAX_LEN
snake_y: .byte 0:SNAKE_MAX_LEN

# used to keep track of time until the next time the snake can move.
snake_move_timer: .word 0

# 1 if the snake changed direction since the last time it moved.
snake_dir_changed: .word 0

# how many apples have been eaten.
apples_eaten: .word 0

# coordinates of the (one) apple in the world.
apple_x: .word 3
apple_y: .word 2

# A pair of arrays, indexed by direction, to turn a direction into x/y deltas.
# e.g. direction_delta_x[DIR_E] is 1, because moving east increments X by 1.
#                         N  E  S  W
direction_delta_x: .byte  0  1  0 -1
direction_delta_y: .byte -1  0  1  0

.text

# ------------------------------------------------------------------------------------------------

# these .includes are here to make these big arrays come *after* the interesting
# variables in memory. it makes things easier to debug.
.include "display_2211_0822.asm"
.include "textures.asm"

# ------------------------------------------------------------------------------------------------

.text
.globl main
main:
	jal setup_snake
	jal wait_for_game_start

	# main game loop
	_loop:
		jal check_input
		jal update_snake
		jal draw_all
		jal display_update_and_clear
		jal wait_for_next_frame
	jal check_game_over
	beq v0, 0, _loop

	# when the game is over, show a message
	jal show_game_over_message
syscall_exit

# ------------------------------------------------------------------------------------------------
# Misc game logic
# ------------------------------------------------------------------------------------------------

# ------------------------------------------------------------------------------------------------

# waits for the user to press a key to start the game (so the snake doesn't go barreling
# into the wall while the user ineffectually flails attempting to click the display (ask
# me how I know that that happens))
wait_for_game_start:
enter
	_loop:
		jal draw_all
		jal display_update_and_clear
		jal wait_for_next_frame
	jal input_get_keys_pressed
	beq v0, 0, _loop
leave

# ------------------------------------------------------------------------------------------------

# returns a boolean (1/0) of whether the game is over. 1 means it is.
check_game_over:
enter
	li v0, 0

	# if they've eaten enough apples, the game is over.
	lw t0, apples_eaten
	blt t0, APPLES_NEEDED, _endif
		li v0, 1
		j _return
	_endif:

	# if they lost the game, the game is over.
	lw t0, lost_game
	beq t0, 0, _return
		li v0, 1
_return:
leave

# ------------------------------------------------------------------------------------------------

show_game_over_message:
enter
	# first clear the display
	jal display_update_and_clear

	# then show different things depending on if they won or lost
	lw t0, lost_game
	bne t0, 0, _lost
		# they finished successfully!
		li   a0, 7
		li   a1, 25
		lstr a2, "yay! you"
		li   a3, COLOR_GREEN
		jal  display_draw_colored_text

		li   a0, 12
		li   a1, 31
		lstr a2, "did it!"
		li   a3, COLOR_GREEN
		jal  display_draw_colored_text
	j _endif
	_lost:
		# they... didn't...
		li   a0, 5
		li   a1, 30
		lstr a2, "oh no :("
		li   a3, COLOR_RED
		jal  display_draw_colored_text
	_endif:

	jal display_update_and_clear
leave

# ------------------------------------------------------------------------------------------------
# Snake
# ------------------------------------------------------------------------------------------------

# sets up the snake so the first two segments are in the middle of the screen.
setup_snake:
enter
	# snake head in the middle, tail below it
	li  t0, GRID_WIDTH
	div t0, t0, 2
	sb  t0, snake_x
	sb  t0, snake_x + 1

	li  t0, GRID_HEIGHT
	div t0, t0, 2
	sb  t0, snake_y
	add t0, t0, 1
	sb  t0, snake_y + 1
leave

# ------------------------------------------------------------------------------------------------

# checks for the arrow keys to change the snake's direction.
check_input:
enter
	lw t0, snake_dir_changed
	bne t0, 0, _break

	jal input_get_keys_held
	
	beq v0, KEY_U, _north
   	beq v0, KEY_D, _south
    	beq v0, KEY_R, _east
    	beq v0, KEY_L, _west
	j _break
    	
	_north:
		lw t0, snake_dir
    		beq t0, DIR_N, _break	
		beq t0, DIR_S, _break
    		
    		# t1 = DIR_N
    		li t1, DIR_N
 		# snake_dir = DIR_N
    		sw t1, snake_dir
   
    		# t2 =  1
    		li t2, 1
    		# snake_dir_changed = 1
    		sw t2, snake_dir_changed
    		
   		j _break
	
	_south:
    		lw t0, snake_dir
    		beq t0, DIR_N, _break	
		beq t0, DIR_S, _break
    		
    		# t1 = DIR_S
    		li t1, DIR_S
 		# snake_dir = DIR_S
    		sw t1, snake_dir
   
    		# t2 =  1
    		li t2, 1
    		# snake_dir_changed = 1
    		sw t2, snake_dir_changed
    		
    		j _break
    		
    	_east:
    		lw t0, snake_dir
    		beq t0, DIR_E, _break	
		beq t0, DIR_W, _break
    		
    		# t1 = DIR_E
    		li t1, DIR_E
 		# snake_dir = DIR_E
    		sw t1, snake_dir
   
    		# t2 =  1
    		li t2, 1
    		# snake_dir_changed = 1
    		sw t2, snake_dir_changed
    		
    		j _break
    		
    	_west:
    		lw t0, snake_dir
    		beq t0, DIR_E, _break	
		beq t0, DIR_W, _break
    		
    		# t1 = DIR_W
    		li t1, DIR_W
 		# snake_dir = DIR_W
    		sw t1, snake_dir
   
    		# t2 =  1
    		li t2, 1
    		# snake_dir_changed = 1
    		sw t2, snake_dir_changed
    	
    		j _break
    		
	_break:
leave

# ------------------------------------------------------------------------------------------------

# update the snake.
update_snake:
enter
	lw t0, snake_move_timer
	
	# if snake_move_timer != 0
	beq t0, 0, _else
		sub t0, t0, 1
		sw t0, snake_move_timer
		
		j _endif
			
	_else:
		# t1 = SNAKE_MOVE_DELAY
		li t1, SNAKE_MOVE_DELAY
		# snake_move_timer = SNAKE_MOVE_DELAY
		#move t0, t1
		sw t1, snake_move_timer
		
		# t2 = snake_dir_changed
		lw t2, snake_dir_changed
		# snake_dir_changed = 0
		move t2, zero
		sw t2, snake_dir_changed
		
		jal move_snake	
	_endif:
leave

# ------------------------------------------------------------------------------------------------

move_snake:
enter s0, s1
	
	jal compute_next_snake_pos
	
	move s0, v0
	move s1, v1
	
    	blt s0, 0, _game_over
   	bge s0, GRID_WIDTH, _game_over
    	blt s1, 0, _game_over
    	bge s1, GRID_HEIGHT, _game_over
    	
    	# if is_point_on_snake = 1
    	move a0, s0
    	move a1, s1
    	jal is_point_on_snake
    	beq v0, 1, _game_over
    	
    	lw t0, apple_x
	lw t1, apple_y
	bne s0, t0, _move_forward
	bne s1, t1, _move_forward
	
	j _eat_apple
    	
	_game_over:
		# lost_game = 1
    		lw t0, lost_game
    		li t0, 1
    		sw t0, lost_game
    		
   		j _break
	
	_move_forward:
    		jal shift_snake_segments
    		sb s0, snake_x
    		sb s1, snake_y
    		
    		j _break
    		
    	_eat_apple:
    		# apples_eaten++
    		lw t0, apples_eaten
    		add t0, t0, 1
    		sw t0, apples_eaten
    		
    		# snake_len++
    		lw t1, snake_len
    		add t1, t1, 1
    		sw t1, snake_len
    		
    		jal shift_snake_segments
    		sb s0, snake_x
    		sb s1, snake_y
    		
    		jal move_apple
    			
	_break:
	
leave s0, s1

# ------------------------------------------------------------------------------------------------

shift_snake_segments:
enter

	lw t0, snake_len
	# i = snake_len-1
	sub t0, t0, 1
	
	_loop:
		# t2 = i - 1
		sub t2, t0, 1
		
		# t3 = snake_x[i-1]
		lb t3, snake_x(t2)
		# snake_x[i] = snake_x[i-1]
		sb t3, snake_x(t0)
	
		# t3 = snake_y[i-1]
		lb t3, snake_y(t2)
		# snake_y[i] = snake_y[i-1]
		sb t3, snake_y(t0)

    		sub t0, t0, 1
    		bge t0, 1, _loop
leave

# ------------------------------------------------------------------------------------------------

move_apple:
enter s0, s1
	_loop:
		# random X coordinate
    		li a0, 0
    		li a1, GRID_WIDTH
    		li v0, 42
    		syscall
    		move s0, v0
    		 		 		
    		# random Y coordinate
    		li a0, 0
    		li a1, GRID_HEIGHT
    		li v0, 42
    		syscall
    		move s1, v0
    		
    		move a0, s0
    		move a1, s1
    		
    		jal is_point_on_snake
    	   		
		beq v0, 1, _loop
		
	sb s0, apple_x
	sb s1, apple_y
	
leave s0, s1

# ------------------------------------------------------------------------------------------------

compute_next_snake_pos:
enter
	# t9 = direction
	lw t9, snake_dir

	# v0 = direction_delta_x[snake_dir]
	lb v0, snake_x
	lb t0, direction_delta_x(t9)
	add v0, v0, t0

	# v1 = direction_delta_y[snake_dir]
	lb v1, snake_y
	lb t0, direction_delta_y(t9)
	add v1, v1, t0
leave

# ------------------------------------------------------------------------------------------------

# takes a coordinate (x, y) in a0, a1.
# returns a boolean (1/0) saying whether that coordinate is part of the snake or not.
is_point_on_snake:
enter
	# for i = 0 to snake_len
	li t9, 0
	_loop:
		lb t0, snake_x(t9)
		bne t0, a0, _differ
		lb t0, snake_y(t9)
		bne t0, a1, _differ

			li v0, 1
			j _return

		_differ:
	add t9, t9, 1
	lw  t0, snake_len
	blt t9, t0, _loop

	li v0, 0

_return:
leave

# ------------------------------------------------------------------------------------------------
# Drawing functions
# ------------------------------------------------------------------------------------------------

draw_all:
enter
	# if we haven't lost...
	lw t0, lost_game
	bne t0, 0, _return

		# draw everything.
		jal draw_snake
		jal draw_apple
		jal draw_hud
_return:
leave

# ------------------------------------------------------------------------------------------------

draw_snake:
enter s0
		# s0 = 0
		li s0, 0
	_loop:
		
		# t0 = snake_x[s0]
		lb t0, snake_x(s0)
		
		mul a0, t0, GRID_CELL_SIZE
		
		# t1 = snake_y[s0]
		lb t1, snake_y(s0)
		
		mul a1, t1, GRID_CELL_SIZE	
		
		# if s0 == 0
		bne s0, 0, _else
		
			# t4 = snake_dir
			lw t4, snake_dir
			# t4 = snake_dir * 4
			mul t4, t4, 4
			# a2 = tex_snake_head[snake_dir * 4]
			lw a2, tex_snake_head(t4)
			
			j _endif
			
		_else:
			la a2, tex_snake_segment
		_endif:
		
		jal display_blit_5x5_trans
		
		lw t3, snake_len
		add s0, s0, 1
		blt s0, t3, _loop
leave s0

# ------------------------------------------------------------------------------------------------

draw_apple:
enter
	# t0 = apple_x
	lw t0, apple_x
	# a0 = apple_x * GRID_CELL_SIZE
	mul a0, t0, GRID_CELL_SIZE
	
	# t1 = apple_y
	lw t1, apple_y
	# a1 = apple_y * GRID_CELL_SIZE
	mul a1, t1, GRID_CELL_SIZE
	
	la a2, tex_apple
	
	jal display_blit_5x5_trans
leave

# ------------------------------------------------------------------------------------------------

draw_hud:
enter
	# draw a horizontal line above the HUD showing the lower boundary of the playfield
	li  a0, 0
	li  a1, GRID_HEIGHT
	mul a1, a1, GRID_CELL_SIZE
	li  a2, DISPLAY_W
	li  a3, COLOR_WHITE
	jal display_draw_hline

	# draw apples collected out of remaining
	li a0, 1
	li a1, 58
	lw a2, apples_eaten
	jal display_draw_int

	li a0, 13
	li a1, 58
	li a2, '/'
	jal display_draw_char

	li a0, 19
	li a2, 58
	li a2, APPLES_NEEDED
	jal display_draw_int
leave
