//Small modifications required move from C2 -> C3

//datum/signal PRIMARY DEFINITION code/game/communications.dm

// ------------
// DATUM/SIGNAL
// ------------
datum/signal
//	var/obj/source
	var/channels_passed = "" //Param-like list of frequencies this signal has been on, for transponders and stuff.

//	var/transmission_method = 0
	//0 = wire
	//1 = radio transmission

//	var/data = list()
	var/encryption
	//We can carry a computer file around, why not.
	var/datum/computer/file/data_file

datum/signal/proc/copy_from(datum/signal/model)
	source = model.source
	transmission_method = model.transmission_method
	data = model.data
	encryption = model.encryption

datum/signal/proc/wipe()
	source = null
	channels_passed = ""
	data = list()
	encryption = null
	if (data_file)
		data_file.dispose()
	data_file = null
	return

datum/signal/destroy()
	if(src.data_file)
		src.data_file.destroy()
/* //Pooling is performance-negative. -FRANC
	if (reusable_signals)
		reusable_signals -= null
*/
	..()


// debuggging
datum/signal/proc/show()
	to_chat(world, "signal from \ref[source][source] on [channels_passed]")
	for(var/key in data)
		to_chat(world, "[key]=[data[key]]")
	to_chat(world, "end of signal")

// ---------------------
// DATUM/COMPUTER/FILE
// ---------------------
// DATUM/COMPUTER/FOLDER
// ---------------------

/datum/computer
	var/name
	var/size = 4
	var/tmp/obj/item/disk/data/holder = null
	var/tmp/datum/computer/folder/holding_folder = null
	var/tmp/list/metadata = list()

	New()
		..()
		metadata = list("date" = world.realtime, "owner"=null,"group"=null, "permission"=COMP_ALLACC)

		return

	folder
		name = "Folder"
		size = 0
		var/gen = 0
		var/list/datum/computer/contents = list()
		var/tmp/list/linkers = list()
		/* commented by singh, new disposing() pattern should handle this. if i broke everything sorry IBM, SORRY
		disposing()
			for(var/datum/computer/F in src.contents)
				qdel(F)
			for(var/datum/computer/folder/link/L in src.linkers)
				L.contents = list()
			..()
		*/
		destroy()
			for (var/datum/computer/F in src.contents)
				F.dispose()

			for (var/datum/computer/folder/link/L in src.linkers)
				L.contents.len = 0

			..()

		proc
			add_file(datum/computer/R)
				if(!holder || holder.read_only || !R)
					return 0
				if(istype(R,/datum/computer/folder) && (src.gen>=10))
					return 0
				if((holder.file_used + R.size) <= holder.file_amount)
					src.contents.Add(R)
					R.holder = holder
					R.holding_folder = src
					if (src.gen)
						if (isnull(R.metadata["owner"]))
							R.metadata["owner"] = src.metadata["owner"]
						if (isnull(R.metadata["group"]))
							R.metadata["group"] = src.metadata["group"]
						if (isnull(R.metadata["permission"]) || R.metadata["permission"] == COMP_ALLACC)
							R.metadata["permission"] = src.metadata["permission"]
					src.holder.file_used -= src.size
					src.size += R.size
					src.holder.file_used += src.size
					if(istype(R,/datum/computer/folder))
						R:gen = (src.gen+1)
					return 1

				return 0

			remove_file(datum/computer/R)
				if(holder && !holder.read_only && R)
//					boutput(world, "Removing file [R]. File_used: [src.holder.file_used]")
					src.contents.Remove(R)
					src.holder.file_used -= src.size
					src.size -= R.size
					src.holder.file_used += src.size
					src.holder.file_used = max(src.holder.file_used, 0)
//					boutput(world, "Removed file [R]. File_used: [src.holder.file_used]")
					return 1
				return 0

			can_add_file(datum/computer/R)
				if(!holder || holder.read_only || !R)
					return 0
				if(istype(R,/datum/computer/folder) && (src.gen>=10))
					return 0
				return ((holder.file_used + R.size) <= holder.file_amount)

			copy_folder(var/depth = 0)
				if (depth >= 8)
					return null
				var/datum/computer/folder/F = new src.type()
				F.name = src.name
				F.holder = src.holder
				for (var/datum/computer/C in contents)
					if (istype(C, /datum/computer/file))
						F.add_file(C:copy_file())
					else if (istype(C, /datum/computer/folder))
						F.add_file(C:copy_folder(depth + 1))
				return F


	file
		name = "File"
		var/extension = "FILE" //Differentiate between types of files, why not

		asText()
			return corruptText(pick("Error: Unknown filetype for '[name]'", "Imagine four balls on the edge of a cliff.  Time works the same way.","Packet five loss packet six echo loss packet nine loss packet ten loss gain signal."),60)

		proc
			copy_file_to_folder(datum/computer/folder/newfolder, var/newname)
				if(!newfolder || (!istype(newfolder)) || (!newfolder.holder) || (newfolder.holder.read_only))
					return 0

				if((newfolder.holder.file_used + src.size) <= newfolder.holder.file_amount)
					var/datum/computer/file/newfile = src.copy_file()
					if(newname)
						newfile.name = newname

					if(!newfolder.add_file(newfile))
						qdel(newfile)

					return 1

				return 0

			copy_file() //Just make a replica of self
				var/datum/computer/file/copy = new src.type

				for(var/V in src.vars)
					if (issaved(src.vars[V]))// && V != "holder")
						copy.vars[V] = src.vars[V]

				if (!copy.metadata)
					copy.metadata = list()
				if (src.metadata)
					copy.metadata["owner"] = src.metadata["owner"]
					copy.metadata["permission"] = src.metadata["permission"]
					copy.metadata["group"] = src.metadata["group"]

				return copy

			writable()
				if(src.holder && src.holder.read_only)
					return 0

				return 1

	proc/asText() //Convert contents to text, if possible
		return null
/*
	disposing()
		if (Debug2)
			logTheThing("debug", null, null, "<b>Computer Datum:</b> disposing() called on [src.type] \ref[src] [src.name]")
		// same as above, XOXOXO. -singh
		//if(holder && holding_folder)
		//	holding_folder.remove_file(src)
		..()
*/
	destroy()
		if (GLOB.Debug2)
			log_world("DEBUG:<b>Computer Datum:</b> dispose() called on [src.type] \ref[src] [src.name]")
		if (holding_folder)
			holding_folder.remove_file(src)
			src.holding_folder = null

		src.holder = null
		src.metadata = null
		..()

// --------------
// MISC DATAFILES
// --------------


/datum/computer/file/text
	name = "text"
	extension = "TXT"
	size = 2
	var/data = null

	asText()
		return "[data]|n"

/datum/computer/file/record
	name = "record"
	extension = "REC"
	size = 2

	var/list/fields = list()

	Destroy()
		fields = null
		..()

	asText()
		for (var/x in fields)
			. += "[x]"
			if (isnull(fields[x]))
				. += "|n"
			else
				. += "=[fields[x]]|n"

/datum/computer/file/signal
	name = "signal"
	extension = "SIG"
	size = 2

	var/list/data = list()
	var/encryption
	var/datum/computer/file/data_file = null

	destroy()
		data = null
		encryption = null
		if (data_file)
			data_file.dispose()
			data_file = null

		..()

	asText()
		for (var/x in data)
			. += "\[[x]]"
			if (isnull(data[x]))
				. += " = NULL|n"
			else
				. += " = [data[x]]|n"

/datum/computer/file/archive
	name = "archive"
	extension = "FAR"
	size = 8

	var/uncompressed_size = 0 //Size of files stored within.
	var/list/contained_files = list() //Generally assumed that all contained files will be expendable copies
	var/max_contained_size = 48

	proc/add_file(datum/computer/R)
		if(!R || (R.size + uncompressed_size) > max_contained_size)
			return 0

		if(istype(R, /datum/computer/file/archive))
			return 0

		contained_files += R
		uncompressed_size += R.size
		return 1

	copy_file() //Just make a replica of self
		var/datum/computer/file/archive/copy = new src.type

		for(var/V in src.vars)
			if (issaved(src.vars[V]) && V != "contained_files")
				copy.vars[V] = src.vars[V]

		if (!copy.contained_files)
			copy.contained_files = list()

		for(var/datum/computer/F in src.contained_files)
			if (istype(F, /datum/computer/file))
				copy.contained_files += F:copy_file()
			else if (istype(F, /datum/computer/folder))
				var/datum/computer/folder/fcopy = F:copy_folder()
				if (fcopy)
					copy.contained_files += fcopy

		return copy

	disposing()
		if (src.contained_files)
			for (var/datum/computer/C in src.contained_files)
				C.dispose()

			src.contained_files.len = 0
			src.contained_files = null
		..()

/datum/computer/folder/link
	name = "symlink"
	gen = 10
	var/datum/computer/folder/target = null

	New(var/datum/computer/folder/newtarget)
		..()
		if (gen != 10) gen = 10
		if(istype(newtarget))
			if (istype(newtarget, /datum/computer/folder/link))
				newtarget = newtarget:target
				if (!newtarget)
					return
			//qdel(src.metadata)
			src.contents = newtarget.contents
			//src.metadata = newtarget.metadata
			newtarget.linkers += src
			src.target = newtarget
		return

	/* same as above, XOXOXO. -singh
	disposing()
		src.contents = null
		if (src.target)
			src.target.linkers -= src
			src.target = null
		..()
	*/

	disposing()
		src.contents = null
		if (src.target)
			src.target.linkers -= src
			src.target = null
		..()

	add_file(datum/computer/R, misc)
		if (!target || target.holder != src.holder)
			return 0

		return target.add_file(R, misc)

	can_add_file(datum/computer/R, misc)
		if (!target || target.holder != src.holder)
			return 0

		return target.can_add_file(R, misc)

	remove_file(datum/computer/R, misc)
		if(!target || target.holder != src.holder)
			return 0

		return target.remove_file(R, misc)

	copy_folder(var/depth = 0)
		if(!target || target.holder != src.holder)
			return 0

		return target.copy_folder(depth)

/datum/computer/file/image
	extension = "IMG"
	size = 8
	var/image/ourImage = null
	var/icon/ourIcon = null
	var/asciiVersion = null
	var/img_name = null
	var/img_desc = null

	asText()
		if (asciiVersion)
			return asciiVersion

		if (!(ourImage && ourImage.icon) && !ourIcon)
			return ""

		asciiVersion = ""
		var/icon/sourceIcon = ourIcon ? ourIcon : icon(ourImage.icon)
		for (var/py = 32, py > 0, py--)
			for (var/px = 1, px <= 32, px++)
				. = sourceIcon.GetPixel(px, py)
				if (.)
					. = hex2num(copytext(.,2))
					switch (.)
						if (0 to 5592405)
							asciiVersion += "."

						if (5592406 to 11184810)
							asciiVersion += "+"

						if (11184811 to INFINITY)
							asciiVersion += "@"
				else
					asciiVersion += "."

			asciiVersion += "|n"

		return asciiVersion

// ----------------------
// DATACORE MODIFICATIONS
// ----------------------
/datum/data
	var/size = 1.0

/datum/data/record
	size = 5.0

// -------------
// DATA TERMINAL
// -------------
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
				qdel(signal)
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