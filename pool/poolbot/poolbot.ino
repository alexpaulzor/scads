#include "poolbot.h"

void setup() {
	pinMode(PIN_FLOW_SWITCH, INPUT);
	pinMode(PIN_VALVE_CURRENT, INPUT);
	pinMode(PIN_STOP_PUMP, OUTPUT);
	pinMode(PIN_VALVE_IN_POOL, OUTPUT);
	pinMode(PIN_VALVE_IN_SPA, OUTPUT);
	pinMode(PIN_VALVE_OUT_POOL, OUTPUT);
	pinMode(PIN_VALVE_OUT_SPA, OUTPUT);

	// TODO: stop pumps
	// TODO: wiggle valves to determine state
}

void loop() {
	// TODO


	// Poll for input

}

/* Algorithm:
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