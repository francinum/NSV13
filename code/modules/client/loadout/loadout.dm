GLOBAL_LIST_EMPTY(loadout_categories)
GLOBAL_LIST_EMPTY(gear_datums)

/datum/loadout_category
	var/category = ""
	var/list/gear = list()

/datum/loadout_category/New(cat)
	category = cat
	..()

/proc/populate_gear_list()
	//create a list of gear datums to sort
	for(var/geartype in subtypesof(/datum/gear))
		var/datum/gear/G = geartype

		var/use_name = initial(G.display_name)
		var/use_category = initial(G.sort_category)

		if(G == initial(G.subtype_path))
			continue

		if(!use_name)
			WARNING("Loadout - Missing display name: [G]")
			continue
		if(!initial(G.cost) && initial(G.unlocktype) == GEAR_METACOIN)
			WARNING("Loadout - Metacoin item, Missing cost: [G]")
			continue
		if(!initial(G.ckey) && initial(G.unlocktype) == GEAR_DONATOR)
			WARNING("Loadout - Donator Item, No assigned control key: [G]")
		if(!initial(G.path) && use_category != "OOC") //OOC category does not contain actual items
			WARNING("Loadout - Missing path definition: [G]")
			continue

		if(!GLOB.loadout_categories[use_category])
			GLOB.loadout_categories[use_category] = new /datum/loadout_category(use_category)
		var/datum/loadout_category/LC = GLOB.loadout_categories[use_category]
		GLOB.gear_datums[use_name] = new geartype
		LC.gear[use_name] = GLOB.gear_datums[use_name]

	GLOB.loadout_categories = sortAssoc(GLOB.loadout_categories)
	for(var/loadout_category in GLOB.loadout_categories)
		var/datum/loadout_category/LC = GLOB.loadout_categories[loadout_category]
		LC.gear = sortAssoc(LC.gear)
	return 1

/datum/gear
	var/display_name               //Name/index. Must be unique.
	var/description                //Description of this gear. If left blank will default to the description of the pathed item.
	var/unlocktype                 //How is this item unlocked, May also cause the item to be hidden.
	var/path                       //Path to item.
	var/cost = INFINITY            //Number of metacoins (If GEAR_METACOIN)
	var/ckey                       //Control Key of the donator the item is assigned to. (GEAR_DONATOR)
	var/slot                       //Slot to equip to.
	var/list/allowed_roles         //Roles that can spawn with this item.
	var/list/species_blacklist     //Stop certain species from receiving this gear
	var/list/species_whitelist     //Only allow certain species to receive this gear
	var/sort_category = "General"
	var/subtype_path = /datum/gear //for skipping organizational subtypes (optional)

/datum/gear/New()
	..()
	if(!description)
		var/obj/O = path
		description = initial(O.desc)

/datum/gear/proc/purchase(client/C) //Called when the gear is first purchased
	return

/datum/gear_data
	var/path
	var/location

/datum/gear_data/New(npath, nlocation)
	path = npath
	location = nlocation

/datum/gear/proc/spawn_item(location, metadata)
	var/datum/gear_data/gd = new(path, location)
	var/item = new gd.path(gd.location)
	return item
