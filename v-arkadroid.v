module main

import gg
import gx
import os
import time
import math
import rand
// import sokol.sapp
import neuroevolution

const (
	win_width    = 1340
	win_height   = 754
	timer_period = 24
	font_cfg = gx.TextCfg{
		color: gx.white
		size: 20
	}
)

struct Ball {
mut:
	x      		f64 = 40
	y      		f64 = 40
	width  		f64 = 30
	height 		f64 = 30
	center_x	f64
	center_y 	f64 
	radius 		f64 = 25  
	speed  		f64 = 0.4
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
	velocity 	f64 
	thrust		f64
	ammo     	f64 = 5
}

fn (mut p Player) fire() {
	p.ammo--
}

fn (mut p Player) move(dir int) {
	if dir == 0 {p.speed-= 10}
	if dir == 1 {p.speed+= 10}
}

// fn (mut p Player) release(dir int) {
// 	if dir == 0 {p.speed =-0.3}
// 	if dir == 1 {p.speed =0.3}
// }

fn (mut p Player) is_collision(balls []Ball) bool {
  
	for mut ball in balls {
		ball.center_x = ball.x+ball.width/2
		ball.center_y = ball.y+ball.height/2
		p.center_x = p.x+p.width/2
		p.center_y = p.y+p.height/2
		mut dx := math.abs(ball.center_x-p.center_x)
		mut dy := math.abs(ball.center_y-p.center_y)
        mut d := math.sqrt((dx*dx) + (dy*dy))
	return (d <= ball.radius+20) || ((math.abs((p.x + p.width/2) - (ball.x + ball.width/2)) * 2 < (p.width + ball.width)) && (math.abs((p.y + p.height/2) - (ball.y + ball.height/2)) * 2 < (p.height + ball.height)))
 	}
	return false
}


fn (mut p Player) update() {

	// p.velocity = p.speed
	p.x += p.speed

	// if p.speed > 7 { p.speed += p.friction }

	if p.x > 1340-p.width {
		p.x = 1340-p.width
		p.speed = 0
		// p.velocity = 0
	}
	if p.x < 0 {
		p.x = 0
		p.speed = 0
		// p.velocity = 0
	}

	if p.speed > 10 { p.speed = 10} 
	if p.speed < -10 { p.speed = -10} 

	if p.ammo <= 0 { 
		p.ammo = 0 
	}
}

struct App {
mut:
	gg               &gg.Context
	background       gg.Image
	player           gg.Image
	ball    	     gg.Image
	balls            []Ball
	players          []Player
	score            int
	max_score        int
	width            f64 = win_width
	height           f64 = win_height
	spawn_interval   f64 = 90
	interval         f64
	nv               neuroevolution.Generations
	gen              []neuroevolution.Network
	alives           int
	generation       int
	background_speed f64
	background_x     f64
	background_y	 f64
}

fn (mut app App) start() {
	app.interval = 0
	app.score = 0
	app.balls = []
	app.players = []
	app.gen = app.nv.generate()
	for _ in 0 .. app.gen.len {
		app.players << Player{}
	}
	app.generation++
	app.alives = app.players.len

	app.balls << Ball{
			x: math.round(rand.f64() * (app.width)) 
			// y: 80
			// width: 40
			// height: 40
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

fn (mut app App) update() {
	
	for j, mut player in app.players {
		for mut ball in app.balls {
			
			if player.is_collision(app.balls) {
				ball.speed = -ball.speed //+player.speed/10
				ball.angle = 180-ball.angle-player.speed	
			}

			if player.alive {
				inputs := [
					player.x / app.width,
					ball.x / app.width
					// ball.y / app.height
				]
				res := app.gen[j].compute(inputs)
				if res[0] > 0.5 {
					player.move(1)
				} else {
					player.move(0)
				}
				player.update()
				ball.update()
				if ball.is_out() {
					player.alive = false
					app.alives--
					app.nv.network_score(app.gen[j], app.score)
					if app.is_it_end() {
						app.start()
					}
				}
			}
		}
	}
	
	app.interval++
	if app.interval == app.spawn_interval {
		app.interval = 0
	}
	app.score++
	app.max_score = if app.score > app.max_score { app.score } else { app.max_score }
}

// fn (mut app App) on_key_down(key sapp.KeyCode) {
// 	for mut player in app.players {
// 		match key {
// 			.a, .left {player.move(0)}
// 			.s, .right {player.move(1)}
// 			// .space {player.fire()}
// 			else {}
// 		}
// 	}
// }

// fn (mut app App) on_key_up(key sapp.KeyCode) {
// 	for mut player in app.players {
// 		match key {
// 			.a, .left {player.release(0)}
// 			.s, .right {player.release(1)}
// 			// .space {player.fire()}
// 			else {}
// 		}
// 	}
// }

// fn on_event(e &sapp.Event, mut app App) {
// 	match e.typ {
// 		.key_down {
// 			app.on_key_down(e.key_code)
// 		}
// 		// .key_up {
// 		// 	app.on_key_up(e.key_code)
// 		// }
// 		else {}
// 	}
// }

fn main() {
	mut app := &App{
		gg: 0
	}
	app.gg = gg.new_context(
		bg_color: gx.white
		width: win_width
		height: win_height
		use_ortho: true // This is needed for 2D drawing
		create_window: true
		window_title: 'arkadroid-v'
		frame_fn: frame
		// event_fn: on_event
		user_data: app
		init_fn: init_images
		font_path: os.resource_abs_path('../assets/fonts/RobotoMono-Regular.ttf')
	)
	app.nv = neuroevolution.Generations{
		population: 50
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
		time.sleep_ms(timer_period)
	}
}

fn init_images(mut app App) {
	app.background = app.gg.create_image(os.resource_abs_path('./images/background.png'))
	app.player = app.gg.create_image(os.resource_abs_path('./images/paddle.png'))
	app.ball = app.gg.create_image(os.resource_abs_path('./images/ball.png'))
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

		app.gg.draw_text(10, 25, 'Score: $app.score', font_cfg)
		app.gg.draw_text(10, 50, 'Max Score: $app.max_score', font_cfg)
		app.gg.draw_text(10, 75, 'Generation: $app.generation', font_cfg)
		app.gg.draw_text(10, 100, 'Population: $app.nv.population', font_cfg)
		// for mut ball in app.balls {
		// mut bp1 := ball.x+ball.width
		// mut bp2 := ball.y+ball.height
		// app.gg.draw_text(10, 125, 'Ball: $ball.x, $ball.y, $bp1, $bp2, $ball.angle', font_cfg)	
		// }
		// for mut player in app.players {
		// mut pp1 := player.x+player.width
		// mut pp2 := player.y+player.height
		// app.gg.draw_text(10, 150, 'Player: $player.x, $player.y, $pp1, $pp2', font_cfg)	
		// }
		/* Quick note on raster reference */
        // app.gg.draw_text(10, 150, 'Image: $app.ball.data', font_cfg)
}

fn (app &App) draw() {
	app.display()
}