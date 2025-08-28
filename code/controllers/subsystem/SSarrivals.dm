/// The time it takes before the shuttle departs after landing
#define TIME_BETWEEN_MOVES 1 MINUTES

/obj/docking_port/stationary/arrivals
	id = "centcomm_dock"
	dwidth = 6
	height = 20
	width = 20

/obj/docking_port/mobile/arrivals

/obj/docking_port/mobile/arrivals/centcomm
	id = "arrivals_shuttle"

/obj/docking_port/stationary/arrivals/centcomm/register()
	if(!..())
		return FALSE
	///SSarrivals.centcomm_port = src
	return TRUE

/obj/docking_port/stationary/arrivals/station
	id = "arrivals_dock"

/obj/docking_port/stationary/arrivals/station/register()
	if(!..())
		return FALSE
	///SSarrivals.station_port = src
	return TRUE

/obj/docking_port/stationary/arrivals/station/cyberiad
	name = "Cyberiad Arrivals Shuttle"
	dwidth = 6
	height = 8
	width = 18

/obj/machinery/computer/shuttle/arrivals
	name = "arrivals shuttle computer"
	shuttleId = "arrivals_shuttle"
	possible_destinations = "centcomm_dock;arrivals_dock"

/*
SUBSYSTEM_DEF(arrivals)
	name = "Arrivals Shuttle"
	wait = 20 SECONDS
	init_order = INIT_ORDER_SHUTTLE
	flags = SS_KEEP_TIMING
	runlevels = RUNLEVEL_GAME
	offline_implications = "Arrivals shuttle will no longer transmit. Setup alternative travel."
	cpu_display = SS_CPUDISPLAY_LOW

	/// holds the arrivals dock port
	var/obj/docking_port/stationary/transit/station_port
	var/obj/docking_port/stationary/transit/centcomm_port

	/// Holds the time until the next launch
	var/cooldown_time

/datum/controller/subsystem/arrivals/Initialize()
	cooldown_time = world.time

/datum/controller/subsystem/arrivals/fire(resumed)
	if(world.time > cooldown_time)
		cooldown_time = world.time + TIME_BETWEEN_MOVES
		SSshuttle.moveShuttle()
*/
