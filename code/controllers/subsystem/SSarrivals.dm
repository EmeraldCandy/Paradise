/// The time it takes before the shuttle departs after landing
#define TIME_BETWEEN_MOVES 1 MINUTES

/obj/docking_port/stationary/arrivals
		id = "arrivals shuttle"
		callTime = 20 SECONDS



/obj/docking_port/stationary/arrivals/register()
	if(!..())
		return FALSE
	SSarrivals.shuttle = src
	return TRUE

/obj/docking_port/stationary/arrivals/fire()



/obj/docking_port/stationary/arrivals/cyberiad
	name = "Cyberiad Arrivals Shuttle"
	dwidth = 6
	height = 8
	width = 18

SUBSYSTEM_DEF(arrivals)
	name = "Arrivals Shuttle"
	init_order = INIT_ORDER_SHUTTLE
	flags = SS_KEEP_TIMING
	runlevels = RUNLEVEL_SETUP | RUNLEVEL_GAME
	offline_implications = "Arrivals shuttle will no longer transmit. Setup alternative travel."
	cpu_display = SS_CPUDISPLAY_LOW

	/// holds the arrivals dock port
	var/obj/docking_port/stationary/arrivals/shuttle

	/// Holds the time until the next launch
	var/cooldown_time

/datum/controller/subsystem/arrivals/Initialize()
	. = ..()
	cooldown_time = world.time

/datum/controller/subsystem/arrivals/fire(resumed)
	. = ..()
	if(world.time > cooldown_time)
		cooldown_time = world.time + TIME_BETWEEN_MOVES
		shuttle.moveShuttle()
