module main

import gg
import gx
import os
import time
import math
import rand
import neuroevolution

const (
	win_width    = 1340
	win_height   = 754
	timer_period = 40 * time.millisecond // Framerate defined as 1000ms / timer_period (defaulted 25 fps)
	font_small = gx.TextCfg {
		color: gx.white
		size: 20
	}
	font_large = gx.TextCfg {
		color: gx.black
		size: 40
	}
)

/* Ball instance */ 

struct Ball {
mut:
	x      		f64 = 40
	y      		f64 = 250
	width  		f64 = 30
	height 		f64 = 30
	center_x	f64
	center_y 	f64 
	radius 		f64 = 25  
	speed  		f64 = 0.06
	angle  		f64 = 59
}

fn (mut b Ball) update() {
	b.x += b.speed * math.cos(b.angle*math.pi/180)
	b.y += b.speed * math.sin(b.angle*math.pi/180)

	if b.x < 0 { 
	 	b.speed = -b.speed
		b.angle = -b.angle 
	}
	if b.x > 1340 { 
		b.speed = -b.speed 
		b.angle = -b.angle
	}
	if b.y < 0 {
		b.speed = -b.speed
		b.angle = 180-b.angle
	}
}

fn (b Ball) is_out() bool {
	return b.y + b.height > 754
}

/* Player instance */ 

struct Player {
mut:
	x        	f64 = 670
	y       	f64 = 600
	width    	f64 = 80
	height   	f64 = 28
	center_x	f64
	center_y 	f64 
	alive    	bool = true
	gravity 	f64 = -0.012
	friction 	f64 = -0.5
	speed   	f64
	thrust		f64
	ammo     	f64 = 3
}

fn (mut p Player) fire() {
	p.ammo--
}

fn (mut p Player) move(dir int) { 
	if dir == 0 {p.speed -= 0.6}
	if dir == 1 {p.speed += 0.6}
}

fn (mut p Player) release(dir int) { 
	if dir == 0 {p.speed = 0}
	if dir == 1 {p.speed = 0}
}

fn (mut p Player) is_collision(mut balls []Ball) bool {
	for mut ball in balls {
		ball.center_x = ball.x+ball.width/2
		ball.center_y = ball.y+ball.height/2
		p.center_x = p.x+p.width/2
		p.center_y = p.y+p.height/2
		mut dx := math.abs(ball.center_x-p.center_x)
		mut dy := math.abs(ball.center_y-p.center_y)
        mut d := math.sqrt((dx*dx) + (dy*dy))
	return (d <= ball.radius) || ((math.abs((p.x + p.width/2) - (ball.x + ball.width/2)) * 2 < (p.width + ball.width)) && (math.abs((p.y + p.height/2) - (ball.y + ball.height/2)) * 2 < (p.height + ball.height)))
 	}
	return false
}

fn (mut p Player) update() {

	p.x += p.speed
	// if p.speed > 7 { p.speed += p.friction }

	if p.x > 1340-p.width {
		p.x = 1340-p.width
		p.speed = 0
	}
	if p.x < 0 {
		p.x = 0
		p.speed = 0
	}

	if p.speed > 4 { p.speed = 4} 
	if p.speed < -4 { p.speed = -4} 

	if p.ammo <= 0 { 
		p.ammo = 0 
	}
}

/* Brick instance */ 

struct Brick {
mut: 
	x      		f64 = 40
	y      		f64 = 40
	width  		f64 = 80
	height 		f64 = 30
	center_x	f64
	center_y 	f64 
	color		gg.Image
	tag			int
}

fn (mut br Brick) is_bumping(mut balls []Ball) bool { 
	for mut ball in balls {
		ball.center_x = ball.x+ball.width/2
		ball.center_y = ball.y+ball.height/2
		br.center_x = br.x+br.width/2
		br.center_y = br.y+br.height/2
		mut dx := math.abs(ball.center_x-br.center_x)
		mut dy := math.abs(ball.center_y-br.center_y)
        mut d := math.sqrt((dx*dx) + (dy*dy))
	return (d <= ball.radius) || ((math.abs((br.x + br.width/2) - (ball.x + ball.width/2)) * 2 < (br.width + ball.width)) && (math.abs((br.y + br.height/2) - (ball.y + ball.height/2)) * 2 < (br.height + ball.height)))
 	}
	return false
}

/* Game basics */

struct App {
mut:
	gg               &gg.Context
	background       gg.Image
	player           gg.Image
	ball    	     gg.Image
	brick_red		 gg.Image
	brick_gold		 gg.Image
	brick_purple	 gg.Image
	players          []Player
	balls            []Ball
	bricks 			 []Brick
	row_count 		 int = 4
	col_count 		 int = 14
	score            int
	max_score        int
	width            f64 = win_width
	height           f64 = win_height
	nv               neuroevolution.Generations
	gen              []neuroevolution.Network
	alives           int
	generation       int
	background_x     f64
	background_y	 f64
}

fn (mut app App) start() {
	app.score = 0
	app.balls = []
	app.players = []
	app.bricks = []
	app.gen = app.nv.generate()
	for _ in 0 .. app.gen.len {
		app.players << Player{}
	}
	app.generation++
	app.alives = app.players.len
	app.balls << Ball{
			x: math.round(rand.f64() * (app.width)) 
	}
	for i in 0 .. app.row_count {
		for j in 0 .. app.col_count {
			app.bricks << Brick {
				x: (j * 90) + 50 
				y: (i * 40) + 50
				color: app.pick_color()
				tag: app.pick_tag()
			}
		}
	}
}

fn (app &App) is_it_end() bool {
	for i in 0 .. app.players.len {
		if app.players[i].alive {
			return false
		}
	}
	return true
}

/* Exercise - To do */

// fn (app &App) is_it_win() bool {
	
// }

/* Helpers */

fn (app &App) pick_color() gg.Image {
  	if math.round(rand.f64()*2) == 0 {
	return app.brick_purple
	} else if math.round(rand.f64()*2) == 1 {
	return app.brick_red
	}
    return app.brick_gold
}

fn (app &App) pick_tag() int {
  	if math.round(rand.f64()*2) == 0 {
	return 0
	} else if math.round(rand.f64()*2) == 1 {
	return 1
	}
    return 2
}

fn (mut app App) update() {
	
	for j, mut player in app.players {
		for k, mut brick in app.bricks {
			for mut ball in app.balls {

				if brick.is_bumping(mut app.balls) {
					ball.speed = -ball.speed
					// Poor side collision
					if (brick.x > ball.x && brick.y < ball.y) || (brick.x + brick.width > ball.x && brick.y + brick.height < ball.y) {
					} else {
					ball.angle = 180-ball.angle
					}
					if brick.tag == 0 {
						app.score += 100
					} else if brick.tag == 1 {
						app.score += 200
					} else if brick.tag == 2 {
						app.score += 300
						// Hint: roll an extra k isolated fire bonus here + render fx
					}
					app.bricks.delete(k)
				}
				
				if player.is_collision(mut app.balls) {
					ball.speed = -ball.speed
					// Poor side collision
					if (player.x > ball.x && player.y < ball.y) || (player.x + player.width > ball.x && player.y + player.height < ball.y) {
					} else {
					ball.angle = 180-ball.angle-(player.speed*2)	
					}
				}

				if player.alive {
					/* evoNN I/O */

					inputs := [
						player.x / app.width,
						ball.x / app.width
					]
					res := app.gen[j].compute(inputs)
					if res[0] > 0.5 {
						player.move(1)
					} else {
						player.move(0)
					}
					if ball.is_out() {
						player.alive = false
						app.alives--
						app.nv.network_score(app.gen[j], app.score)
						if app.is_it_end() { app.start() }
					}
				}
			ball.update()
			}
		}
	player.update()
	}
	app.score++
	app.max_score = if app.score > app.max_score { app.score } else { app.max_score }
}

/* Human Controls */

fn (mut app App) on_key_down(key gg.KeyCode) {
	for mut player in app.players {
		match key {
			.a, .left {player.move(0)}
			.s, .right {player.move(1)}
			// .space {player.fire()}
			else {}
		}
	}
}

fn (mut app App) on_key_up(key gg.KeyCode) {
	for mut player in app.players {
		match key {
			.a, .left {player.release(0)}
			.s, .right {player.release(1)}
			// .space {player.fire()}
			else {}
		}
	}
}

fn on_event(e &gg.Event, mut app App) {
	match e.typ {
		.key_down {
			app.on_key_down(e.key_code)
		}
		.key_up {
			app.on_key_up(e.key_code)
		}
		else {}
	}
}

/* Module main and render*/
[console]
fn main() {
	println(os.resource_abs_path)
	mut app := &App{
		gg: 0
	}
	app.gg = gg.new_context(
		bg_color: gx.white
		width: win_width
		height: win_height
		use_ortho: true
		create_window: true
		window_title: 'v-arkadroid'
		frame_fn: frame
		event_fn: on_event
		user_data: app
		init_fn: init_images
		font_path: os.resource_abs_path('./fonts/RobotoMono-Regular.ttf')
	)
	app.nv = neuroevolution.Generations{
		population: 20
		network: [2, 3, 1]
		training: true
	}
	app.start()
	go app.run()
	app.gg.run()
}

fn (mut app App) run() {
	for {
		app.update()
		time.sleep(timer_period)
	}
}

fn init_images(mut app App) {
	app.background = app.gg.create_image(os.resource_abs_path('./images/background.png'))
	app.player = app.gg.create_image(os.resource_abs_path('./images/paddle.png'))
	app.ball = app.gg.create_image(os.resource_abs_path('./images/ball.png'))
	app.brick_red = app.gg.create_image(os.resource_abs_path('./images/brick_red.png'))
	app.brick_gold = app.gg.create_image(os.resource_abs_path('./images/brick_gold.png'))
	app.brick_purple = app.gg.create_image(os.resource_abs_path('./images/brick_purple.png'))
}

fn frame(app &App) {
	app.gg.begin()
	app.draw()
	app.gg.end()
}

fn (app &App) display() {
		app.gg.draw_image(f32(app.background_x), f32(app.background_y), app.background.width, app.background.height,
			app.background)
	
		for ball in app.balls {
			app.gg.draw_image(f32(ball.x), f32(ball.y),
				f32(ball.width), f32(ball.height), app.ball)
		}
		for player in app.players {
			if player.alive {
			app.gg.draw_image(f32(player.x), f32(player.y), f32(player.width), f32(player.height),
				app.player)
			}
		}
			
		for brick in app.bricks {	
			app.gg.draw_image(f32(brick.x), f32(brick.y),
				f32(brick.width), f32(brick.height), brick.color)
		}

		app.gg.draw_text(10, 25, 'Score: $app.score', font_small)
		app.gg.draw_text(10, 50, 'Max Score: $app.max_score', font_small)
		app.gg.draw_text(10, 75, 'Population: $app.nv.population', font_small)
		app.gg.draw_text(10, 100, 'Generation: $app.generation', font_small)
        // app.gg.draw_text(10, 150, 'Image: $app.ball.data', font_small) // Ball collision debug
}

fn (app &App) draw() {
	app.display()
}