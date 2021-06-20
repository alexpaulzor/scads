#include <stdbool.h>

#ifndef POOLBOT_H
#define POOLBOT_H

#define IF_SERIAL if (true) // if (false)
// TODO: i2c library
// TODO: RTC library
// TODO: LCD library
// #include <Encoder.h>
// TODO: rotary encoder library

#define PIN_INPUT_CLK 2
#define PIN_INPUT_DT 3
#define PIN_UI_SW 4
#define PIN_CLEANER_PUMP 13

#define HEAT_POOL 6
#define HEAT_SPA 7
#define PIN_STOP_PUMP 8
#define PIN_VALVE_IN_POOL 9
#define PIN_VALVE_IN_SPA 10
#define PIN_VALVE_OUT_POOL 11
#define PIN_VALVE_OUT_SPA 12
#define PIN_FLOW_SWITCH A0
#define PIN_VALVE_CURRENT A1
#define PIN_PUMP_SPEED_STEP_1 A2
#define PIN_PUMP_SPEED_STEP_2 A3

#define CURRENT_MAX 1024
#define CURRENT_MIN 0
#define CURRENT_ZERO ((CURRENT_MAX+CURRENT_MIN)/2)

typedef enum {
	IN,
	OUT
} t_valve;

typedef enum {
	POOL,
	SPA,
	UNKOWN
} t_port;



#define MENU_MAX_CHILDREN 8
// #define MENU_NAME_MAX_LEN 20

//typedef 'return type' (*FuncPtr)('arguments')
typedef void (*t_menu_fn)(void);
typedef void (*t_edit_fn)(long);  

typedef void (*t_schedule_fn)(void); 

typedef struct t_schedule_item {
	long time;
	t_schedule_fn schedule_fn;
	struct t_schedule_item * next;
} t_schedule_item;

typedef struct t_menu_item {
	String name;
	struct t_menu_item * children[MENU_MAX_CHILDREN];
	t_menu_fn menu_fn;
} t_menu_item;


void menu_root();
void menu_spa();
void menu_pool();
void menu_wfall();
void menu_clean();
void menu_stop();
void menu_edit_schedule();
void menu_set_time();

t_menu_item root_menu_item;
t_menu_item spa_menu_item;
t_menu_item pool_menu_item;
t_menu_item wfall_menu_item;
t_menu_item clean_menu_item;
t_menu_item stop_menu_item;
t_menu_item edit_schedule_menu_item;
t_menu_item set_time_menu_item;

void configure_menu_item(
		t_menu_item* item, 
		String name, 
		t_menu_fn menu_fn, 
		int num_children, 
		t_menu_item** children);

void setup_menus();

/*
MENUS

Root:
  1 3 5 7 901 3 5 7 90
  --------------------
A|>Spa     |      i->o|  i=P|S, o=P|S
B| Pool    |  xxxx rpm|
C| WFall   | yy:zz rem|
D| Clean   |          |
  --------------------
A|>All Stop           |
B| Edit schedule      |
C| Set time           |
D|                    |

Spa:
  1 3 5 7 901 3 5 7 90
  --------------------
A|>Return   |     S->S|
B| Set Speed| xxxx rpm|
C| Set Time |yy:zz rem|
D|          |         |

Pool -> set_duration ->
  1 3 5 7 901 3 5 7 90
  --------------------
A| Spa     |      i->o|
B|>Return  |  xxxx rpm|
C| WFall   | yy:zz rem|
D| Clean   |          |

WFall -> set_duration ->
  1 3 5 7 901 3 5 7 90
  --------------------
A| Spa     |      i->o|
B| Pool    |  xxxx rpm|
C|>Return  | yy:zz rem|
D| Clean   |          |

Clean -> set_duration -> set_boost_duration (default=same) ->
  1 3 5 7 901 3 5 7 90
  --------------------
A| Spa     |      i->o|
B| Pool    |  xxxx rpm|
C| WFall   | yy:zz rem|
D|>Return  |          |

All Stop:
  1 3 5 7 901 3 5 7 90
  --------------------
A|>Return
B|
C|
D|

Edit schedule:
  1 3 5 7 901 3 5 7 90
  --------------------
A| Clean (hh:mm)
B| BotOff (hh:mm)
C| Stop (hh:mm)
D| Waterfall (hh:mm)

Set Time -> set_duration (default=now) -> Root


End * -> Root
Return -> Root
*/


# endif // POOLBOT_H

