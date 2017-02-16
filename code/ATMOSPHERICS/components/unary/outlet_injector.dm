/obj/machinery/atmospherics/unary/outlet_injector
	icon = 'icons/obj/atmospherics/outlet_injector.dmi'
	icon_state = "off"
	use_power = 1

	name = "Air Injector"
	desc = "Has a valve and pump attached to it."

	var/on = 0
	var/injecting = 0

	var/volume_rate = 50


	var/id = null


	level = 1

/obj/machinery/atmospherics/unary/outlet_injector/update_icon()
	if(node)
		if(on && !(stat & NOPOWER))
			icon_state = "[level == 1 && istype(loc, /turf/simulated) ? "h" : "" ]on"
		else
			icon_state = "[level == 1 && istype(loc, /turf/simulated) ? "h" : "" ]off"
	else
		icon_state = "exposed"
		on = 0

	return

/obj/machinery/atmospherics/unary/outlet_injector/power_change()
	var/old_stat = stat
	..()
	if(old_stat != stat)
		update_icon()


/obj/machinery/atmospherics/unary/outlet_injector/process()
	..()
	injecting = 0

	if(!on || stat & NOPOWER)
		return 0

	if(air_contents.temperature > 0)
		var/transfer_moles = (air_contents.return_pressure())*volume_rate/(air_contents.temperature * R_IDEAL_GAS_EQUATION)

		var/datum/gas_mixture/removed = air_contents.remove(transfer_moles)

		loc.assume_air(removed)

		if(network)
			network.update = 1

	return 1

/obj/machinery/atmospherics/unary/outlet_injector/proc/inject()
	if(on || injecting)
		return 0

	injecting = 1

	if(air_contents.temperature > 0)
		var/transfer_moles = (air_contents.return_pressure())*volume_rate/(air_contents.temperature * R_IDEAL_GAS_EQUATION)

		var/datum/gas_mixture/removed = air_contents.remove(transfer_moles)

		loc.assume_air(removed)

		if(network)
			network.update = 1

	flick("inject", src)

/obj/machinery/atmospherics/unary/outlet_injector/set_frequency(new_frequency)
	radio_controller.remove_object(src, frequency)
	frequency = new_frequency
	if(frequency)
		radio_connection = radio_controller.add_object(src, frequency)

/obj/machinery/atmospherics/unary/outlet_injector/proc/broadcast_status()
	if(!radio_connection)
		return 0

	var/datum/signal/signal = new
	signal.transmission_method = 1 //radio signal
	signal.source = src

	signal.data = list(
		"tag" = id,
		"device" = "AO",
		"power" = on,
		"volume_rate" = volume_rate,
		//"timestamp" = world.time,
		"sigtype" = "status"
	 )

	radio_connection.post_signal(src, signal)

	return 1

/obj/machinery/atmospherics/unary/outlet_injector/initialize()
	..()

	set_frequency(frequency)

/obj/machinery/atmospherics/unary/outlet_injector/Destroy()
	if(frequency)
		set_frequency(null)
	return ..()

/obj/machinery/atmospherics/unary/outlet_injector/receive_signal(datum/signal/signal)
	if(!signal.data["tag"] || (signal.data["tag"] != id) || (signal.data["sigtype"]!="command"))
		return 0

	if("power" in signal.data)
		on = text2num(signal.data["power"])

	if("power_toggle" in signal.data)
		on = !on

	if("inject" in signal.data)
		spawn inject()
		return

	if("set_volume_rate" in signal.data)
		var/number = text2num(signal.data["set_volume_rate"])
		volume_rate = between(0, number, air_contents.volume)

	if("status" in signal.data)
		spawn(2)
			broadcast_status()
		return //do not update_icon

		//log_admin("DEBUG \[[world.timeofday]\]: outlet_injector/receive_signal: unknown command \"[signal.data["command"]]\"\n[signal.debug_print()]")
		//return
	spawn(2)
		broadcast_status()
	update_icon()

/obj/machinery/atmospherics/unary/outlet_injector/hide(i) //to make the little pipe section invisible, the icon changes.
	if(node)
		if(on)
			icon_state = "[i == 1 && istype(loc, /turf/simulated) ? "h" : "" ]on"
		else
			icon_state = "[i == 1 && istype(loc, /turf/simulated) ? "h" : "" ]off"
	else
		icon_state = "[i == 1 && istype(loc, /turf/simulated) ? "h" : "" ]exposed"
		on = 0
	return
