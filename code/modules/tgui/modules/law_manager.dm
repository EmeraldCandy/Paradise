/datum/ui_module/law_manager
	name = "Law manager"
	var/ion_law	= "IonLaw"
	var/zeroth_law = "ZerothLaw"
	var/inherent_law = "InherentLaw"
	var/supplied_law = "SuppliedLaw"
	var/supplied_law_position = MIN_SUPPLIED_LAW_NUMBER

	var/current_view = 0

	var/global/list/datum/ai_laws/admin_laws
	var/global/list/datum/ai_laws/player_laws
	var/mob/living/silicon/owner = null

/datum/ui_module/law_manager/New(mob/living/silicon/S)
	..()
	owner = S

	if(!admin_laws)
		admin_laws = new()
		player_laws = new()

		init_subtypes(/datum/ai_laws, admin_laws)
		admin_laws = dd_sortedObjectList(admin_laws)

		for(var/datum/ai_laws/laws in admin_laws)
			if(laws.selectable)
				player_laws += laws

/datum/ui_module/law_manager/ui_act(action, list/params, datum/tgui/ui)
	if(..())
		return

	if(ui.user != owner && !check_rights(R_ADMIN))
		message_admins("Warning: possible href exploit by [key_name_admin(ui.user)] - failed permissions check in law manager!")
		log_debug("Warning: possible href exploit by [key_name(ui.user)] - failed permissions check in law manager!")
		return

	. = TRUE

	switch(action)
		if("set_view")
			current_view = text2num(params["set_view"])

		if("law_channel")
			if(params["law_channel"] in owner.law_channels())
				owner.lawchannel = params["law_channel"]

		if("state_law")
			var/datum/ai_law/AL = locate(params["ref"]) in owner.laws.all_laws()
			if(AL)
				var/state_law = text2num(params["state_law"])
				owner.laws.set_state_law(AL, state_law)

		if("add_zeroth_law")
			if(zeroth_law && is_admin(ui.user) && !owner.laws.zeroth_law)
				owner.set_zeroth_law(zeroth_law)

		if("add_ion_law")
			if(ion_law && is_malf(ui.user))
				owner.add_ion_law(ion_law)

		if("add_inherent_law")
			if(inherent_law && is_malf(ui.user))
				owner.add_inherent_law(inherent_law)

		if("add_supplied_law")
			if(supplied_law && supplied_law_position >= 1 && MIN_SUPPLIED_LAW_NUMBER <= MAX_SUPPLIED_LAW_NUMBER && is_malf(ui.user))
				owner.add_supplied_law(supplied_law_position, supplied_law)

		if("change_zeroth_law")
			var/new_law = tgui_input_text(ui.user, "Enter new law Zero. Leaving the field blank will cancel the edit.", "Edit Law", zeroth_law)
			if(new_law && new_law != zeroth_law && (!..()))
				zeroth_law = new_law

		if("change_ion_law")
			var/new_law = tgui_input_text(ui.user, "Enter new ion law. Leaving the field blank will cancel the edit.", "Edit Law", ion_law)
			if(new_law && new_law != ion_law && (!..()))
				ion_law = new_law

		if("change_inherent_law")
			var/new_law = tgui_input_text(ui.user, "Enter new inherent law. Leaving the field blank will cancel the edit.", "Edit Law", inherent_law)
			if(new_law && new_law != inherent_law && (!..()))
				inherent_law = new_law

		if("change_supplied_law")
			var/new_law = tgui_input_text(ui.user, "Enter new supplied law. Leaving the field blank will cancel the edit.", "Edit Law", supplied_law)
			if(new_law && new_law != supplied_law && (!..()))
				supplied_law = new_law

		if("change_supplied_law_position")
			var/new_position = tgui_input_number(ui.user, "Enter new supplied law position between 1 and [MAX_SUPPLIED_LAW_NUMBER], inclusive. Inherent laws at the same index as a supplied law will not be stated.", "Law Position", supplied_law_position, MAX_SUPPLIED_LAW_NUMBER, 1)
			if(isnum(new_position) && (!..()))
				supplied_law_position = new_position

		if("edit_law")
			if(is_malf(ui.user))
				var/datum/ai_law/AL = locate(params["edit_law"]) in owner.laws.all_laws()
				// Dont allow non-admins to edit their own malf laws
				if(istype(AL, /datum/ai_law/zero) && (!check_rights(R_ADMIN)))
					to_chat(ui.user, "<span class='warning'>You can't edit that law.</span>")
					return
				if(AL)
					var/new_law = tgui_input_text(ui.user, "Enter new law. Leaving the field blank will cancel the edit.", "Edit Law", AL.law)
					if(new_law && new_law != AL.law && is_malf(ui.user) && (!..()))
						log_and_message_admins("has changed a law of [owner] from '[AL.law]' to '[new_law]'")
						AL.law = new_law

		if("delete_law")
			if(is_malf(ui.user))
				var/datum/ai_law/AL = locate(params["delete_law"]) in owner.laws.all_laws()
				// Dont allow non-admins to delete their own malf laws
				if(istype(AL, /datum/ai_law/zero) && (!check_rights(R_ADMIN)))
					to_chat(ui.user, "<span class='warning'>You can't delete that law.</span>")
					return
				if(AL && is_malf(ui.user))
					owner.delete_law(AL)

		if("state_laws")
			owner.statelaws(owner.laws)

		if("state_law_set")
			var/datum/ai_laws/ALs = locate(params["state_law_set"]) in (is_admin(ui.user) ? admin_laws : player_laws)
			if(ALs)
				owner.statelaws(ALs)

		if("transfer_laws")
			if(!is_malf(ui.user))
				return
			var/admin_overwrite = is_admin(ui.user)
			var/datum/ai_laws/ALs = locate(params["transfer_laws"]) in (admin_overwrite ? admin_laws : player_laws)
			if(!ALs)
				return
			if(admin_overwrite && alert("Do you want to overwrite [owner]'s zeroth law? If the chosen lawset has no zeroth law while [owner] has one, it will get removed!", "Load Lawset", "Yes", "No") != "Yes")
				admin_overwrite = FALSE
			log_and_message_admins("has transfered the [ALs.name] laws to [owner][admin_overwrite ? " and overwrote their zeroth law":""].")
			ALs.sync(owner, FALSE, admin_overwrite)
			current_view = 0

		if("notify_laws")
			to_chat(owner, "<span class='danger'>Law Notice</span>")
			owner.laws.show_laws(owner)
			if(is_ai(owner))
				var/mob/living/silicon/ai/AI = owner
				for(var/mob/living/silicon/robot/R in AI.connected_robots)
					to_chat(R, "<span class='danger'>Law Notice</span>")
					R.laws.show_laws(R)
			if(ui.user != owner)
				to_chat(ui.user, "<span class='notice'>Laws displayed.</span>")


/datum/ui_module/law_manager/ui_state(mob/user)
	if(check_rights(R_ADMIN, FALSE))
		return GLOB.admin_state
	if(issilicon(user))
		return GLOB.conscious_state
	return GLOB.default_state

/datum/ui_module/law_manager/ui_interact(mob/user, datum/tgui/ui = null)
	ui = SStgui.try_update_ui(user, src, ui)
	if(!ui)
		ui = new(user, src, "LawManager", sanitize("[src] - [owner.name]"))
		ui.open()

/datum/ui_module/law_manager/ui_data(mob/user)
	var/list/data = list()
	owner.lawsync()

	data["ion_law_nr"] = ionnum()
	data["ion_law"] = ion_law
	data["zeroth_law"] = zeroth_law
	data["inherent_law"] = inherent_law
	data["supplied_law"] = supplied_law
	data["supplied_law_position"] = supplied_law_position

	package_laws(data, "zeroth_laws", list(owner.laws.zeroth_law))
	package_laws(data, "ion_laws", owner.laws.ion_laws)
	package_laws(data, "inherent_laws", owner.laws.inherent_laws)
	package_laws(data, "supplied_laws", owner.laws.supplied_laws)

	data["isAI"] = is_ai(owner)
	data["isMalf"] = is_malf(user)
	data["isSlaved"] = owner.is_slaved()
	data["isAdmin"] = is_admin(user)
	data["view"] = current_view

	var/list/channels = list()
	for(var/ch_name in owner.law_channels())
		channels[++channels.len] = list("channel" = ch_name)
	data["channel"] = owner.lawchannel
	data["channels"] = channels
	data["law_sets"] = package_multiple_laws(data["isAdmin"] ? admin_laws : player_laws)

	return data

/datum/ui_module/law_manager/proc/package_laws(list/data, field, list/datum/ai_law/laws)
	var/list/packaged_laws = list()
	for(var/datum/ai_law/AL in laws)
		packaged_laws[++packaged_laws.len] = list("law" = AL.law, "index" = AL.get_index(), "state" = owner.laws.get_state_law(AL), "ref" = "\ref[AL]")
	data[field] = packaged_laws
	data["has_[field]"] = length(packaged_laws)

/datum/ui_module/law_manager/proc/package_multiple_laws(list/datum/ai_laws/laws)
	var/list/law_sets = list()
	for(var/datum/ai_laws/ALs in laws)
		var/list/packaged_laws = list()
		package_laws(packaged_laws, "zeroth_laws", list(ALs.zeroth_law, ALs.zeroth_law_borg))
		package_laws(packaged_laws, "ion_laws", ALs.ion_laws)
		package_laws(packaged_laws, "inherent_laws", ALs.inherent_laws)
		package_laws(packaged_laws, "supplied_laws", ALs.supplied_laws)
		law_sets[++law_sets.len] = list("name" = ALs.name, "header" = ALs.law_header, "ref" = "\ref[ALs]","laws" = packaged_laws)

	return law_sets

/datum/ui_module/law_manager/proc/is_malf(mob/user)
	return (is_admin(user) && !owner.is_slaved()) || is_special_character(owner)

/mob/living/silicon/proc/is_slaved()
	return FALSE

/mob/living/silicon/robot/is_slaved()
	return lawupdate && connected_ai ? sanitize(connected_ai.name) : null

/datum/ui_module/law_manager/proc/sync_laws(mob/living/silicon/ai/AI)
	if(!AI)
		return
	for(var/mob/living/silicon/robot/R in AI.connected_robots)
		R.sync()
	log_and_message_admins("has syncronized [AI]'s laws with its borgs.")
