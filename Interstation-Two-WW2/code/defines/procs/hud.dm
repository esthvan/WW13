/* Using the HUD procs is simple. Call these procs in the life.dm of the intended mob.
Use the regular_hud_updates() proc before process_faction_hud(mob) so
the HUD updates properly! */

//faction HUDs.

/mob/living/carbon/human/proc/most_important_faction_hud_constant()
	if (spy_faction)
		return SPY_FACTION
	if (officer_faction)
		return OFFICER_FACTION
	return BASE_FACTION

/mob/living/carbon/human/proc/base_faction_hud_constant()
	return BASE_FACTION

/mob/living/carbon/human/proc/squad_faction_hud_constant()
	return SQUAD_FACTION

/mob/living/carbon/human/proc/spy_faction_hud_constant()
	return SPY_FACTION

proc/process_faction_hud(var/mob/M, var/mob/Alt)

	if(!can_process_hud(M))
		return
	if (!ishuman(M))
		return

	var/mob/living/carbon/human/viewer = M
	if (!viewer.original_job)
		return

	#ifdef PROCESS_FACTION_HUD_DEBUG
	world << "[viewer] processing faction huds."
	#endif

	var/datum/arranged_hud_process/P = arrange_hud_process(M, Alt, faction_hud_users)
	for(var/mob/living/carbon/human/perp in P.Mob.in_view(P.Turf))

		if(P.Mob.see_invisible < perp.invisibility)
			continue
		if (!perp.original_job)
			continue

		var/shared_job_check = FALSE

		if (viewer == perp)
			shared_job_check = TRUE
		else if (viewer.original_job.base_type_flag() == perp.original_job.base_type_flag())
			shared_job_check = TRUE
		else if (viewer.original_job.base_type_flag() == ITALIAN)
			if (perp.original_job.base_type_flag() == GERMAN)
				shared_job_check = TRUE
		else if (perp.original_job.base_type_flag() == ITALIAN)
			if (viewer.original_job.base_type_flag() == GERMAN)
				shared_job_check = TRUE

		if (shared_job_check)
			if (sharesquads(viewer, perp)) // same squad or SL
				P.Client.images += perp.hud_list[perp.squad_faction_hud_constant()]
			else // unrelated
				P.Client.images += perp.hud_list[perp.most_important_faction_hud_constant()]
		else
			// one of us is a spy, allowing us to recognize true factions

			// condition 1: they're the spy
			// condition 2: we're the spy
			// condition 3: they're just an enemy

			if (perp.spy_faction == viewer.base_faction)
				P.Client.images += perp.hud_list[perp.spy_faction_hud_constant()]
			else if (viewer.spy_faction == perp.base_faction)
				P.Client.images += perp.hud_list[perp.base_faction_hud_constant()]
			else // we're just enemies. No hud for now
				P.Client.images += perp.hud_list[FACTION_TO_ENEMIES]

datum/arranged_hud_process
	var/client/Client
	var/mob/Mob
	var/turf/Turf

proc/arrange_hud_process(var/mob/M, var/mob/Alt, var/list/hud_list)
	hud_list |= M
	var/datum/arranged_hud_process/P = new
	P.Client = M.client
	P.Mob = Alt ? Alt : M
	P.Turf = get_turf(P.Mob)
	return P

proc/can_process_hud(var/mob/M)
	if(!M)
		return FALSE
	if(!M.client)
		return FALSE
	if(M.stat != CONSCIOUS)
		return FALSE
	return TRUE

//Deletes the current HUD images so they can be refreshed with new ones.
mob/proc/handle_hud_glasses() //Used in the life.dm of mobs that can use HUDs.
	if(client)
		for(var/image/hud in client.images)
			if(copytext(hud.icon_state,1,4) == "hud")
				client.images -= hud
//	med_hud_users -= src
//	sec_hud_users -= src

mob/proc/in_view(var/turf/T)
	return view(T)

/mob/observer/eye/in_view(var/turf/T)
	var/list/viewed = new
	for(var/mob/living/carbon/human/H in mob_list)
		if(get_dist(H, T) <= 7)
			viewed += H
	return viewed
