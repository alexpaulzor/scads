#define ENCODER_OPTIMIZE_INTERRUPTS
#include <Encoder.h>
#include "poolbot.h"

Encoder i_enc(PIN_INPUT_CLK, PIN_INPUT_DT);
long last_position = 0;
long input_delta = 0;
long edit_multiplier = 1;
t_edit_fn edit_show_fn = NULL;
t_edit_fn edit_save_fn = NULL;

long cur_time = 0;

t_port in_valve_port = UNKOWN;
t_port out_valve_port = UNKOWN;
int valve_current = CURRENT_ZERO;
bool flow_detected = false;
t_menu_item * cur_menu_item = &root_menu_item;
int selected_menu_idx = 0;
bool button_was_pressed = false;

t_schedule_item * next_schedule_item = NULL;



// https://wokwi.com/arduino/projects/301948378385744394
// https://lastminuteengineers.com/rotary-encoder-arduino-tutorial/
// https://www.pjrc.com/teensy/td_libs_Encoder.html


void configure_menu_item(
		t_menu_item* item, 
		String name, 
		t_menu_fn menu_fn, 
		t_menu_item** children) {
	item->name = name;
	Serial.println("Configuring " + item->name);
	item->menu_fn = menu_fn;
	int num_children = sizeof(children);
	if (num_children != 0) 
		num_children = num_children / sizeof(children[0]);
	for (int i = 0; i < MENU_MAX_CHILDREN; i++) {
		if (i < num_children) {
			item->children[i] = children[i];
			Serial.println("Adding child " + item->children[i]->name);
		}
		else
			item->children[i] = NULL;
	}
}

void setup_menus() {
	t_menu_item* set_time_menu_children[] = {
		&set_time_menu_item,
		&root_menu_item,
	};
	configure_menu_item(
		&set_time_menu_item, 
		"Set Time",
		&menu_set_time,
		set_time_menu_children);

	t_menu_item* root_menu_children[] = {
		&spa_menu_item,
		&pool_menu_item,
		&wfall_menu_item,
		&clean_menu_item,
		&stop_menu_item,
		&edit_schedule_menu_item,
		&set_time_menu_item,
	};
	configure_menu_item(
		&root_menu_item, 
		"Return",
		&menu_root,
		root_menu_children);
}

void populate_schedule() {
	// TODO: fill in default schedule
}

void menu_root() {
	if (next_schedule_item == NULL) {
		populate_schedule();
	}
}
void menu_spa() {
	
}
void menu_pool() {
	
}
void menu_wfall() {
	
}
void menu_clean() {
	
}
void menu_stop() {
	stop_cleaner();
	stop_pump();
}
void menu_edit_schedule() {
	
}

void show_time(long time) {
	int hr = time / 1000 / 60 / 60;
	int minutes = time / 1000 / 60 % 60;
	Serial.println(String(hr) + ":" + String(minutes));
}

void set_time(long time) {
	cur_time = time;
	// TODO: write to RTC
}

void menu_set_time() {
	cur_time = millis();
	input_delta = cur_time;
	edit_multiplier = 1000 * 60 * 15; // 15 minutes per click
	edit_show_fn = show_time;
	edit_save_fn = set_time;
	input_var = &cur_time;
}

bool is_flow_detected() {
	return digitalRead(PIN_FLOW_SWITCH) != HIGH;
}

void stop_pump() {
	digitalWrite(PIN_STOP_PUMP, HIGH);
}

void unstop_pump() {
	digitalWrite(PIN_STOP_PUMP, LOW);
}

bool stop_pump_wait_noflow(int timeout_ms=1000) {
	stop_pump();
	long start = millis();
	while (is_flow_detected() && start + timeout_ms < millis()) {
		delay(250);
	}
	return is_flow_detected();
}

bool valves_moving() {
	int current = analogRead(PIN_VALVE_CURRENT);
	//TODO: fuzz a tiny bit?
	//TODO: take more than one sample because it's 24v AC
	return current != CURRENT_ZERO;
}

void stop_valve(t_valve valve) {
	if (valve == IN) {
		digitalWrite(PIN_VALVE_IN_SPA, LOW);
		digitalWrite(PIN_VALVE_IN_POOL, LOW);
	} else {
		digitalWrite(PIN_VALVE_OUT_POOL, LOW);
		digitalWrite(PIN_VALVE_OUT_SPA, LOW);
	}
}

void stop_valve_wait_nocurrent() {
	// TODO: args
	// TODO: implment
}

void update_display() {
	/* Update the LCD with current information/menu */
	// TODO: define args
	// TODO: implement dashboard
	// TODO: implement menus
	// TODO: display valve current draw
}

void print_display() {
	IF_SERIAL {
		true; 
	} else 
		return;

	if (input_var != NULL) {
		edit_show_fn(input_var);
		return;
	}

	int di = 0;
	if (selected_menu_idx > 3)
		di = 4;
	for (int i = 0; i < 4; i++) {
		t_menu_item* child = cur_menu_item->children[i + di];
		if (child == NULL)
			continue;
		if (selected_menu_idx == di + i)
			Serial.print(">");
		else
			Serial.print(" ");
		Serial.println(child->name);
	}
	String io;
	if (in_valve_port == SPA)
		io = "S->";
	else if (in_valve_port == POOL)
		io = "P->";
	else
		io = "?->";
	if (out_valve_port == SPA)
		io += "S";
	else if (out_valve_port == POOL)
		io += "P";
	else
		io += "?";
	Serial.println(io);

	// TODO: print RPM
	// TODO: print time remaining
}

bool set_valve(t_valve valve, t_port port) {
	// TODO: implement
	if (!stop_pump_wait_noflow()) {
		return false;
	}

	if (valve == IN) {
		if (port == SPA) {
			digitalWrite(PIN_VALVE_IN_POOL, LOW);
			digitalWrite(PIN_VALVE_IN_SPA, HIGH);
		} else {
			digitalWrite(PIN_VALVE_IN_SPA, LOW);
			digitalWrite(PIN_VALVE_IN_POOL, HIGH);
		}
	} else {
		if (port == SPA) {
			digitalWrite(PIN_VALVE_OUT_POOL, LOW);
			digitalWrite(PIN_VALVE_OUT_SPA, HIGH);
		} else {
			digitalWrite(PIN_VALVE_OUT_SPA, LOW);
			digitalWrite(PIN_VALVE_OUT_POOL, HIGH);
		}
	}
}

bool assert_valve_at_port(t_valve valve, t_port guess=POOL) {
	if (!stop_pump_wait_noflow())
		return false;
	// TODO: implement
	return true;
}

bool start_cleaner() {
	// TODO: check/assert requirements for cleaner
	/* 	* OUT=POOL (usually also IN=POOL)
		* Pump unstopped
		* Flow detected
	*/
	digitalWrite(PIN_CLEANER_PUMP, HIGH);
	return true;
}

void stop_cleaner() {
	digitalWrite(PIN_CLEANER_PUMP, LOW);
}

void handle_input(long delta_position) {
	long new_position = i_enc.read();
	long delta_position = new_position - last_position;
	if (delta_position != 0) {
		if (input_var != NULL)
			input_var += delta_position;
		else {
			selected_menu_idx += delta_position;
			if (selected_menu_idx < 0)
				selected_menu_idx = 0;
			while (
					cur_menu_item->children[selected_menu_idx] == NULL 
					&& selected_menu_idx > 0)
				selected_menu_idx--;
		}
		print_display();
	}
	last_position = new_position;

	bool button_pressed = (digitalRead(PIN_UI_SW) == HIGH);
	if (button_pressed && !button_was_pressed) {
		if (input_var != NULL) {
			// Finished updating var
			input_var = NULL;

		} else {
			t_menu_item* next_menu_item = cur_menu_item->children[selected_menu_idx];
			selected_menu_idx = 0;
			cur_menu_item = next_menu_item;
			next_menu_item->menu_fn();
		}
		print_display();
	}
	button_was_pressed = button_pressed;
}

void setup() {
	IF_SERIAL Serial.begin(115200);
	pinMode(PIN_FLOW_SWITCH, INPUT);
	pinMode(PIN_VALVE_CURRENT, INPUT);
	pinMode(PIN_UI_SW, INPUT);
	pinMode(PIN_STOP_PUMP, OUTPUT);
	pinMode(PIN_VALVE_IN_POOL, OUTPUT);
	pinMode(PIN_VALVE_IN_SPA, OUTPUT);
	pinMode(PIN_VALVE_OUT_POOL, OUTPUT);
	pinMode(PIN_VALVE_OUT_SPA, OUTPUT);
	pinMode(PIN_CLEANER_PUMP, OUTPUT);

	last_position = i_enc.read();

	// TODO: setup i2c

	setup_menus();

	stop_valve(IN);
	stop_valve(OUT);
	stop_cleaner();
	unstop_pump();

	// TODO: stop pumps
	// TODO: wiggle valves to determine state
	print_display();
}

void loop() {
	handle_input();

	// update_display();
}



/* General Algorithm:
 * Wait for timer (~3am)
 * Enqueue sequence:
	 * Stop pumps
	 * Set IN=POOL, OUT=POOL
	 * Poll valve current
	 * Unstop filter pump
	 * Wait for flow to resume
	 * Start booster pump
	 * Wait 4h
	 * Stop booster pump
	 * Wait 4h
	 * Stop pumps
	 * Set IN=POOL, OUT=SPA
	 * Unstop filter pump
*/