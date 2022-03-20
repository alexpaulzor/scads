#include <Wire.h>
// #include <LiquidCrystal_I2C.h>
#include "LCD03.h"
#define ENCODER_OPTIMIZE_INTERRUPTS
#include <Encoder.h>
#include "poolbot.h"

LCD03 lcd(0x27);

Encoder i_enc(PIN_INPUT_CLK, PIN_INPUT_DT);
long last_position = 0;
long adjustment_value = 0;
long edit_multiplier = 1;
t_edit_fn edit_show_fn = NULL;
t_edit_fn edit_save_fn = NULL;

long cur_time = 0;
long cur_speed = 0;
long override_until = 0;

t_port in_valve_port = UNKOWN;
t_port out_valve_port = UNKOWN;
int valve_current = CURRENT_ZERO;
bool flow_detected = false;
t_menu_item * cur_menu_item = &root_menu_item;
int selected_menu_idx = 0;
bool button_was_pressed = false;


// t_schedule_item * next_schedule_item = NULL;



// https://wokwi.com/arduino/projects/301948378385744394
// https://lastminuteengineers.com/rotary-encoder-arduino-tutorial/
// https://www.pjrc.com/teensy/td_libs_Encoder.html


void configure_menu_item(
		t_menu_item* item, 
		t_menu_item** children,
		int num_children) {
	Serial.println("Configuring " + item->name + 
		" (" + String(num_children) + " children)");
	item->num_children = num_children;
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
	t_menu_item* no_children[] = {};
	
	configure_menu_item(
		&set_time_menu_item, 
		no_children,
		0);
	configure_menu_item(
		&set_speed_menu_item,
		no_children,
		0);
	configure_menu_item(
		&set_duration_menu_item,
		no_children,
		0);
	configure_menu_item(
		&spa_menu_item, 
		no_children,
		0);
	configure_menu_item(
		&pool_menu_item, 
		no_children,
		0);
	configure_menu_item(
		&wfall_menu_item, 
		no_children,
		0);
	configure_menu_item(
		&clean_menu_item, 
		no_children,
		0);
	configure_menu_item(
		&stop_menu_item, 
		no_children,
		0);

	t_menu_item* root_menu_children[] = {
		&set_speed_menu_item,
		&set_duration_menu_item,
		&spa_menu_item,
		&pool_menu_item,
		&wfall_menu_item,
		&clean_menu_item,
		&stop_menu_item,
		// &edit_schedule_menu_item,
		&set_time_menu_item,
	};
	configure_menu_item(
		&root_menu_item, 
		root_menu_children,
		8);
}

void menu_root() {
	// TODO: fill in default schedule
}

void show_duration(long time) {
	int minutes = time / 1000 / 60;
	Serial.println(String(minutes) + " minutes");
}

void set_duration(long duration) {
	override_until = millis() + adjustment_value;
}

void menu_set_duration() {
	adjustment_value = override_until - millis();
	if (adjustment_value <= 0)
		adjustment_value = 3 * 60 * 60 * 1000; // 3h default
	edit_multiplier = 1000 * 60 * 15; // 15 minutes per click
	edit_show_fn = show_duration;
	edit_save_fn = set_duration;
}

void show_speed(long speed) {
	Serial.println(String(speed) + " rpm");
}

void set_speed(long speed) {
	// TODO: set speed
	cur_speed = speed;
}

void menu_set_speed() {
	adjustment_value = cur_speed;
	edit_multiplier = 100;
	edit_show_fn = show_speed;
	edit_save_fn = set_speed;
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
// void menu_edit_schedule() {
	
// }

void show_time(long time) {
	int hr = time / 1000 / 60 / 60;
	int minutes = time / 1000 / 60 % 60;
	char buffer[21];
	sprintf(buffer, "%02d:%02d");
	Serial.println(buffer);
}

void set_time(long time) {
	cur_time = time;
	// TODO: write to RTC
}

void menu_set_time() {
	// TODO: interface with rtc
	cur_time = millis();
	adjustment_value = cur_time;
	edit_multiplier = 1000 * 60 * 15; // 15 minutes per click
	edit_show_fn = show_time;
	edit_save_fn = set_time;
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

	if (edit_show_fn != NULL) {
		Serial.println("Adjusting value: " + String(adjustment_value));
		edit_show_fn(adjustment_value);
		return;
	}
	Serial.println("In menu " + cur_menu_item->name + 
		"; idx = " + String(selected_menu_idx));
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

	// Serial.println(
	// 	"Position: " + String(i_enc.read()) + 
	// 	"; Button: " + String(button_was_pressed));
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

void handle_input() {
	bool refresh = false;
	long new_position = i_enc.read();
	long delta_position = (new_position - last_position) / 3;
	if (delta_position != 0) {
		if (edit_show_fn != NULL)
			adjustment_value += abs(delta_position) / delta_position * edit_multiplier;
		else {
			selected_menu_idx -= abs(delta_position) / delta_position;
			selected_menu_idx = constrain(selected_menu_idx, 0, cur_menu_item->num_children - 1);
		}
		// print_display();
		refresh = true;
	}
	last_position = new_position;

	bool button_pressed = (digitalRead(PIN_UI_SW) == LOW);
	if (button_pressed && !button_was_pressed) {
		Serial.println("Detected button press");
		if (edit_save_fn != NULL) {
			Serial.println("Saving adjustment");
			edit_save_fn(adjustment_value);
			edit_show_fn = NULL;
			edit_save_fn = NULL;
		} else {
			t_menu_item* next_menu_item = cur_menu_item->children[selected_menu_idx];
			// selected_menu_idx = 0;
			Serial.println("Selecting menu item " + next_menu_item->name);
			next_menu_item->menu_fn();
			if (next_menu_item->num_children > 0) {
				cur_menu_item = next_menu_item;
				selected_menu_idx = constrain(selected_menu_idx, 0, cur_menu_item->num_children - 1);
				Serial.println("Entering menu item " + cur_menu_item->name);
			}
		}
	// 	// print_display();
		refresh = true;
	} else if (button_pressed != button_was_pressed) {
		Serial.println("Detected button release");
		refresh = true;
	}
	button_was_pressed = button_pressed;
	if (refresh)
		print_display();
}

void setup() {
	lcd.begin(20, 4);
	lcd.backlight();
	lcd.print("Hello, world!");
	// IF_SERIAL Serial.begin(9600);
	// Serial.println("setup begin");
	pinMode(PIN_FLOW_SWITCH, INPUT);
	pinMode(PIN_VALVE_CURRENT, INPUT);
	pinMode(PIN_UI_SW, INPUT_PULLUP);
	pinMode(PIN_STOP_PUMP, OUTPUT);
	pinMode(PIN_VALVE_IN_POOL, OUTPUT);
	pinMode(PIN_VALVE_IN_SPA, OUTPUT);
	pinMode(PIN_VALVE_OUT_POOL, OUTPUT);
	pinMode(PIN_VALVE_OUT_SPA, OUTPUT);
	pinMode(PIN_CLEANER_PUMP, OUTPUT);

	

	
	// lcd.display();

	// last_position = i_enc.read();

	// setup_menus();

	stop_valve(IN);
	stop_valve(OUT);
	stop_cleaner();
	unstop_pump();

	// TODO: stop pumps
	// TODO: wiggle valves to determine state
	// print_display();
	// Serial.println("setup complete");
}

void loop() {
	// lcd.print("Hello, world!");
	// delay(1000);
	// Serial.println("loop begin");
	// handle_input();

	// update_display();
	// lcd.print("Hello, world!");
	// lcd.display();
	// delay(100);
	// Serial.println("loop complete");
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