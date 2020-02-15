/obj/machinery/power/terminal/netlink
	use_datanet = 1

	receive_signal(datum/signal/signal)
		if(!signal)
			return

		//It can't pick up wireless transmissions
		if(signal.transmission_method != TRANSMISSION_WIRE)
			return

		if(src.master)
			src.master.receive_signal(signal)

		return


	proc
		post_signal(obj/source, datum/signal/signal)
			if(!src.powernet || !signal)
				return

			if(isnull(src.master) || source != src.master)
				return

			signal.transmission_method = TRANSMISSION_WIRE
			signal.channels_passed += "PN[src.netnum];"

			for(var/obj/machinery/power/device in src.powernet.data_nodes)
				if(device != src)
					device.receive_signal(signal, TRANSMISSION_WIRE)

			//qdel(signal)
			return

/obj/machinery/power/data_terminal //The data terminal is remarkably similar to a regular terminal
	name = "data terminal"
	icon_state = "dterm"
	desc = "An underfloor connection point for power line communication equipment."
	level = 1
	layer = FLOOR_EQUIP_LAYER1
	anchored = 1
	directwired = 0
	use_datanet = 1
	mats = 5
	var/obj/master = null //It can be any obj that can use receive_signal

	ex_act()
		if (master)
			return

		return ..()

/obj/machinery/power/data_terminal

	New()
		..()

		var/turf/T = get_turf(src.loc)

		if(level==1) hide(T.intact)

	Destroy()
		master = null
		..()

	receive_signal(datum/signal/signal)
		if(!signal)
			return

		//It can't pick up wireless transmissions
		if(signal.transmission_method != TRANSMISSION_WIRE)
			return

		if(src.master && is_valid_master(src.master))
			src.master.receive_signal(signal)

		return


	proc
		post_signal(obj/source, datum/signal/signal)
			if(!src.powernet || !signal)
				return

			if(source != src.master || !is_valid_master(src.master))
				return

			signal.transmission_method = TRANSMISSION_WIRE
			signal.channels_passed += "PN[src.netnum];"

			var/iterations = 0
			for(var/obj/machinery/power/device in src.powernet.data_nodes)
				if(device != src)
					device.receive_signal(signal, TRANSMISSION_WIRE)

				if (iterations/100 < 1)
					iterations = 0
					LAGCHECK(LAG_REALTIME)

				iterations++

			if (signal)
				if (!reusable_signals || reusable_signals.len > 10)
					signal.dispose()
				else
					signal.wipe()
					if (!(signal in reusable_signals))
						reusable_signals += signal
			return

		is_valid_master(obj/test_master)
			if(!test_master)
				//boutput(world, "no test master")
				return 0

			if(get_turf(test_master) != src.loc)
				//boutput(world, "[test_master] isn't on the same turf")
				return 0

			//boutput(world, "[test_master] is a valid master")
			return 1

	hide(var/i)
		invisibility = i ? 101 : 0
		alpha = invisibility ? 128 : 255