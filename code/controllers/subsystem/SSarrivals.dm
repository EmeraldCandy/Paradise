/// The time it takes before the shuttle departs after landing
#define TIME_BETWEEN_MOVES 1 MINUTES

/obj/docking_port/stationary/arrivals
	id = "Do not  use"
	dwidth = 6
	height = 20
	width = 20

/obj/docking_port/mobile/arrivals
	id = "arrivals_shuttle"
	dwidth = 6
	height = 20
	width = 20

/obj/docking_port/stationary/arrivals/centcomm
	id = "centcomm_dock"

/obj/docking_port/stationary/arrivals/station
	id = "arrivals_dock"

/obj/docking_port/stationary/arrivals/station/cyberiad
	name = "Cyberiad Arrivals Shuttle"

SUBSYSTEM_DEF(arrivals)
	name = "Arrivals Shuttle"
	wait = 20 SECONDS
	init_order = INIT_ORDER_SHUTTLE
	flags = SS_KEEP_TIMING
	runlevels = RUNLEVEL_GAME
	offline_implications = "Arrivals shuttle will no longer transmit. Setup alternative travel."
	cpu_display = SS_CPUDISPLAY_LOW

	/// holds the arrivals dock port
	var/obj/docking_port/current_dock
	var/shuttleId = "arrivals_shuttle"

	/// Holds the time until the next launch
	var/cooldown_time

/datum/controller/subsystem/arrivals/Initialize()
	cooldown_time = world.time

/datum/controller/subsystem/arrivals/fire(resumed)
	if(world.time > cooldown_time)
		cooldown_time = world.time + TIME_BETWEEN_MOVES
		current_dock = SSshuttle.getDock(shuttleId)
		if(current_dock.id == "arrivals_dock")
			SSshuttle.moveShuttle(shuttleId, "centcomm_dock", TRUE, usr)
		else
			SSshuttle.moveShuttle(shuttleId, "arrivals_dock", TRUE, usr)
