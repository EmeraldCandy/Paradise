/datum/ai_law
	var/law = ""
	var/index = 0

/datum/ai_law/New(law, index)
	src.law = law
	src.index = index

/datum/ai_law/proc/get_index()
	return index

/datum/ai_law/ion/get_index()
	return ionnum()

/datum/ai_law/zero/get_index()
	return 0

/datum/ai_laws
	var/name = "Unknown Laws"
	var/law_header = "Prime Directives"
	var/selectable = FALSE
	var/default = FALSE
	///Is this lawset used by the unique ai trait?
	var/unique_ai = FALSE
	var/datum/ai_law/zero/zeroth_law = null
	var/datum/ai_law/zero/zeroth_law_borg = null
	var/list/datum/ai_law/inherent_laws = list()
	var/list/datum/ai_law/supplied_laws = list()
	var/list/datum/ai_law/ion/ion_laws = list()
	var/list/datum/ai_law/sorted_laws = list()

	var/state_zeroth = 0
	var/list/state_ion = list()
	var/list/state_inherent = list()
	var/list/state_supplied = list()

/datum/ai_laws/New()
	..()
	sort_laws()

/* General ai_law functions */
/datum/ai_laws/proc/all_laws()
	sort_laws()
	return sorted_laws

/datum/ai_laws/proc/laws_to_state()
	sort_laws()
	var/list/statements = list()
	for(var/datum/ai_law/law in sorted_laws)
		if(get_state_law(law))
			statements += law

	return statements

/datum/ai_laws/proc/sort_laws()
	if(length(sorted_laws))
		return

	if(zeroth_law)
		sorted_laws += zeroth_law

	for(var/ion_law in ion_laws)
		sorted_laws += ion_law

	var/index = 1
	for(var/datum/ai_law/inherent_law in inherent_laws)
		inherent_law.index = index++
		if(length(supplied_laws) < inherent_law.index || !istype(supplied_laws[inherent_law.index], /datum/ai_law))
			sorted_laws += inherent_law

	for(var/datum/ai_law/AL in supplied_laws)
		if(istype(AL))
			sorted_laws += AL

/datum/ai_laws/proc/sync(mob/living/silicon/S, full_sync = TRUE, change_zeroth = TRUE)
	// Add directly to laws to avoid log-spam
	if(change_zeroth)
		S.sync_zeroth(zeroth_law, zeroth_law_borg)
		var/datum/atom_hud/data/human/medical/advanced/A = GLOB.huds[DATA_HUD_MALF_AI]
		A.add_hud_to(usr)

	if(full_sync || length(ion_laws))
		S.laws.clear_ion_laws()
	if(full_sync || length(inherent_laws))
		S.laws.clear_inherent_laws()
	if(full_sync || length(supplied_laws))
		S.laws.clear_supplied_laws()

	for(var/datum/ai_law/law in ion_laws)
		S.laws.add_ion_law(law.law)
	for(var/datum/ai_law/law in inherent_laws)
		S.laws.add_inherent_law(law.law)
	for(var/datum/ai_law/law in supplied_laws)
		if(law)
			S.laws.add_supplied_law(law.index, law.law)


/mob/living/silicon/proc/sync_zeroth(datum/ai_law/zeroth_law, datum/ai_law/zeroth_law_borg)
	if(!is_special_character(src) || !mind.is_original_mob(src))
		if(zeroth_law_borg)
			laws.set_zeroth_law(zeroth_law_borg.law)
			var/datum/atom_hud/data/human/medical/advanced/A = GLOB.huds[DATA_HUD_MALF_AI]
			A.add_hud_to(usr)
		else if(zeroth_law)
			laws.set_zeroth_law(zeroth_law.law)
		else
			laws.clear_zeroth_laws()

/mob/living/silicon/ai/sync_zeroth(datum/ai_law/zeroth_law, datum/ai_law/zeroth_law_borg)
	if(zeroth_law)
		laws.set_zeroth_law(zeroth_law.law, zeroth_law_borg ? zeroth_law_borg.law : null)

/****************
*	Add Laws	*
****************/
/datum/ai_laws/proc/set_zeroth_law(law, law_borg = null)
	if(!law)
		return

	zeroth_law = new(law)
	if(law_borg) //Making it possible for slaved borgs to see a different law 0 than their AI. --NEO
		zeroth_law_borg = new(law_borg)
	else
		zeroth_law_borg = null
	sorted_laws.Cut()

/datum/ai_laws/proc/add_ion_law(law)
	if(!law)
		return

	for(var/datum/ai_law/AL in ion_laws)
		if(AL.law == law)
			return

	var/new_law = new/datum/ai_law/ion(law)
	ion_laws += new_law
	if(length(state_ion) < length(ion_laws))
		state_ion += 1

	sorted_laws.Cut()

/datum/ai_laws/proc/add_inherent_law(law)
	if(!law)
		return

	for(var/datum/ai_law/AL in inherent_laws)
		if(AL.law == law)
			return

	var/new_law = new/datum/ai_law/inherent(law)
	inherent_laws += new_law
	if(length(state_inherent) < length(inherent_laws))
		state_inherent += 1

	sorted_laws.Cut()

/datum/ai_laws/proc/add_supplied_law(number, law)
	if(!law)
		return

	if(length(supplied_laws) >= number)
		var/datum/ai_law/existing_law = supplied_laws[number]
		if(existing_law && existing_law.law == law)
			return

	if(length(supplied_laws) >= number && supplied_laws[number])
		delete_law(supplied_laws[number])

	while(length(src.supplied_laws) < number)
		src.supplied_laws += ""
		if(length(state_supplied) < length(supplied_laws))
			state_supplied += 1

	var/new_law = new/datum/ai_law/supplied(law, number)
	supplied_laws[number] = new_law
	if(length(state_supplied) < length(supplied_laws))
		state_supplied += 1

	sorted_laws.Cut()

/****************
*	Remove Laws	*
*****************/
/datum/ai_laws/proc/delete_law(datum/ai_law/law)
	if(istype(law))
		law.delete_law(src)

/datum/ai_law/proc/delete_law(datum/ai_laws/laws)
	return

/datum/ai_law/zero/delete_law(datum/ai_laws/laws)
	laws.clear_zeroth_laws()

/datum/ai_law/ion/delete_law(datum/ai_laws/laws)
	laws.internal_delete_law(laws.ion_laws, laws.state_ion, src)

/datum/ai_law/inherent/delete_law(datum/ai_laws/laws)
	laws.internal_delete_law(laws.inherent_laws, laws.state_inherent, src)

/datum/ai_law/supplied/delete_law(datum/ai_laws/laws)
	var/index = laws.supplied_laws.Find(src)
	if(index)
		laws.supplied_laws[index] = ""
		laws.state_supplied[index] = 1

/datum/ai_laws/proc/internal_delete_law(list/datum/ai_law/laws, list/state, list/datum/ai_law/law)
	var/index = laws.Find(law)
	if(index)
		laws -= law
		for(index, index < length(state), index++)
			state[index] = state[index+1]
	sorted_laws.Cut()

/****************
*	Clear Laws	*
****************/
/datum/ai_laws/proc/clear_zeroth_laws()
	zeroth_law = null
	zeroth_law_borg = null

/datum/ai_laws/proc/clear_ion_laws()
	ion_laws.Cut()
	sorted_laws.Cut()

/datum/ai_laws/proc/clear_inherent_laws()
	inherent_laws.Cut()
	sorted_laws.Cut()

/datum/ai_laws/proc/clear_supplied_laws()
	supplied_laws.Cut()
	sorted_laws.Cut()

/datum/ai_laws/proc/show_laws(who)
	sort_laws()
	for(var/datum/ai_law/law in sorted_laws)
		if(law == zeroth_law_borg)
			continue
		if(law == zeroth_law)
			to_chat(who, "<span class='danger'>[law.get_index()]. [law.law]</span>")
		else
			to_chat(who, "[law.get_index()]. [law.law]")

/datum/ai_laws/proc/return_laws_text()
	. = list()
	sort_laws()
	for(var/datum/ai_law/law in sorted_laws)
		if(law == zeroth_law_borg)
			continue
		if(law == zeroth_law)
			. += "<span class='danger'>[law.get_index()]. [law.law]</span>"
		else
			. += "[law.get_index()]. [law.law]"


/********************
*	Stating Laws	*
********************/
/********
*	Get	*
********/
/datum/ai_laws/proc/get_state_law(datum/ai_law/law)
	return law.get_state_law(src)

/datum/ai_law/proc/get_state_law(datum/ai_laws/laws)
	return

/datum/ai_law/zero/get_state_law(datum/ai_laws/laws)
	if(src == laws.zeroth_law)
		return laws.state_zeroth

/datum/ai_law/ion/get_state_law(datum/ai_laws/laws)
	return laws.get_state_internal(laws.ion_laws, laws.state_ion, src)

/datum/ai_law/inherent/get_state_law(datum/ai_laws/laws)
	return laws.get_state_internal(laws.inherent_laws, laws.state_inherent, src)

/datum/ai_law/supplied/get_state_law(datum/ai_laws/laws)
	return laws.get_state_internal(laws.supplied_laws, laws.state_supplied, src)

/datum/ai_laws/proc/get_state_internal(list/datum/ai_law/laws, list/state, list/datum/ai_law/law)
	var/index = laws.Find(law)
	if(index)
		return state[index]
	return 0

/********
*	Set	*
********/
/datum/ai_laws/proc/set_state_law(datum/ai_law/law, state)
	law.set_state_law(src, state)

/datum/ai_law/proc/set_state_law(datum/ai_laws/laws, state)
	return

/datum/ai_law/zero/set_state_law(datum/ai_laws/laws, state)
	if(src == laws.zeroth_law)
		laws.state_zeroth = state

/datum/ai_law/ion/set_state_law(datum/ai_laws/laws, state)
	laws.set_state_law_internal(laws.ion_laws, laws.state_ion, src, state)

/datum/ai_law/inherent/set_state_law(datum/ai_laws/laws, state)
	laws.set_state_law_internal(laws.inherent_laws, laws.state_inherent, src, state)

/datum/ai_law/supplied/set_state_law(datum/ai_laws/laws, state)
	laws.set_state_law_internal(laws.supplied_laws, laws.state_supplied, src, state)

/datum/ai_laws/proc/set_state_law_internal(list/datum/ai_law/laws, list/state, list/datum/ai_law/law, do_state)
	var/index = laws.Find(law)
	if(index)
		state[index] = do_state
