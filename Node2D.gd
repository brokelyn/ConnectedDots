extends Node2D

# connect dots by distance and dont apply forces

# dont apply forces for to small connection
 # dont apply negative forces -> limit to zero

var dots = []
var cons = []
var marked_dot = null

const SPACING = 100
const CONNECT_DISTANCE = 150
const ROW_DOTS = 24
const COL_DOTS = 10
const CONNECTION_FORCE = 3
const DAMPING = 0.03
const NUM_THREADS = 8
const MAX_SPEED = 100
const CONNECTION_TEAR = 10
const GRAVITY = Vector2(0, 0.3)

class Dot:
	var position = Vector2()
	var velocity = Vector2()
	var connections = []
	var marked = false
	
	var mutex = Mutex.new()
	
	func _init(pos: Vector2):
		self.position = pos
	
class Connection:
	var dot1
	var dot2
	var length
	var blinky = 0.4
	
	func _init(d1, d2, l):
		self.dot1 = d1
		self.dot2 = d2
		self.length = l
		
		d1.connections.append(self)
		d2.connections.append(self)
	
	func distance():
		return self.dot1.position.distance_to(self.dot2.position)
		
	func delete():
		var index_d1 = dot1.connections.find(self, 0)
		var index_d2 = dot2.connections.find(self, 0)
		
		dot1.conncetions.remove(index_d1)
		dot2.conncetions.remove(index_d2)

func connect_dots_distance():
	for i in len(dots):
		for j in len(dots):
			if dots[j] != dots[i]:
				var dot_distance = dots[j].position.distance_to(dots[i].position)
				if dot_distance <= CONNECT_DISTANCE:
					cons.append(Connection.new(dots[i], dots[j], dot_distance + rand_range(-10, 10)))
					
func connect_dots_rnd():
	for i in 6000:#rand_range(len(dots), len(dots) * 20):
		var random_dot1 = dots[rand_range(0, len(dots))]
		var random_dot2 = dots[rand_range(0, len(dots))]
		
		if random_dot1 != random_dot2:
			#var dot_distance = random_dot1.position.distance_to(random_dot2.position)
			cons.append(Connection.new(random_dot1, random_dot2, 100))
					
# Called when the node enters the scene tree for the first time.
func _ready():
	for i in range(0, ROW_DOTS, 1):
		for j in range (0, COL_DOTS, 1):
			var dot = Dot.new(Vector2((i * SPACING) + SPACING, (j * SPACING) + SPACING))
			if j == 0:
				dot.marked = true
			dots.append(dot)
			
	self.connect_dots_distance()
			
	set_process(true)
	

func process_dots(task_range):
	var start_index = task_range[0]
	var end_index = task_range[1]
	
	for index in range(start_index, end_index, 1):
		var con = cons[index]
		
		var distance = con.distance()
		
		if distance > con.length * CONNECTION_TEAR:
			con.delete()
			cons[cons.find(con, 0)] = null
			
			continue
		
		var stretch = con.length / distance
		var force = (stretch - 1) * -1
		
		var direction_to_d2 = con.dot2.position - con.dot1.position
		var direction_to_d1 = con.dot1.position - con.dot2.position
		
		var force_to_d2 = direction_to_d2.normalized() * CONNECTION_FORCE * force
		var force_to_d1 = direction_to_d1.normalized() * CONNECTION_FORCE * force
		
		con.dot1.mutex.lock()
		con.dot1.velocity = con.dot1.velocity + force_to_d2
		if con.dot1.velocity.length() > MAX_SPEED:
			con.dot1.velocity = con.dot1.velocity.normalized() * MAX_SPEED
		con.dot1.mutex.unlock()
		
		con.dot2.mutex.lock()
		con.dot2.velocity = con.dot2.velocity + force_to_d1
		if con.dot2.velocity.length() > MAX_SPEED:
			con.dot2.velocity = con.dot2.velocity.normalized() * MAX_SPEED
		con.dot2.mutex.unlock()


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta):
	
	var threads = []
	var task_split = int(len(cons) / NUM_THREADS)
	var current_proccessed = 0
	for i in NUM_THREADS:
		var task_range
		if i == NUM_THREADS - 1:
			task_range = [current_proccessed, len(cons)]
		else:
			task_range = [current_proccessed, current_proccessed + task_split]
		var thread = Thread.new()
		thread.start(self, "process_dots", task_range)
		threads.append(thread)
		current_proccessed += task_split
		
	for thread in threads:
		thread.wait_to_finish()
		
	var swap_cons = []
	for i in len(cons):
		if cons[i] != null:
			swap_cons.append(cons[i])
	cons = swap_cons

	for dot in dots:
		if dot.marked:
			dot.velocity = Vector2(0, 0)
		else:
			dot.position = dot.position + dot.velocity
			dot.velocity = (dot.velocity * (1 - DAMPING)) + GRAVITY
	
	update()
	
func select_dot(position):
	for dot in dots:
		if dot.position.distance_to(position) < 20:
			if marked_dot != null:
				marked_dot.marked = false
				marked_dot = null
			else:
				dot.marked = true
				marked_dot = dot
			break
			
func move_selected(position):
	if marked_dot != null:
		marked_dot.position = position


func _draw():
	for dot in dots:
		if dot.marked:
			draw_circle(dot.position, 5, Color(255, 255, 0))
		else:
			draw_circle(dot.position, 3, Color(255, 255, 255))
		
	for con in cons:
		var distance = con.distance()
		var relativ_length = (distance / con.length) - 1
		var color_short = max(0, min(1, relativ_length))
		var color_wide = max(0, min(1, relativ_length * -1))
		var color_green = max(0, 0.5 - color_short - color_wide)
		
		var color
		if distance > con.length * CONNECTION_TEAR - (0.25 * con.length):
			color = Color(con.blinky, 0, 0)
			con.blinky += 0.035
			if con.blinky >= 1:
				con.blinky = 0.4
		else:
			color = Color(color_short, color_green, color_wide)
			
		draw_line(con.dot1.position, con.dot2.position, color, 1, true)
		
