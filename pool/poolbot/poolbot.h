// TODO: RTC library
// TODO: LCD library

#define PIN_STOP_PUMP 8
#define PIN_VALVE_IN_POOL 9
#define PIN_VALVE_IN_SPA 10
#define PIN_VALVE_OUT_POOL 11
#define PIN_VALVE_OUT_SPA 12
#define PIN_FLOW_SWITCH A0
#define PIN_VALVE_CURRENT A1

typedef enum VALVE {
	IN,
	OUT
};

typedef enum PORT {
	POOL,
	SPA
}