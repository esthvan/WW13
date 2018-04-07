// 2017-07-04: Fixed rifles spitting out all casings on ground when opening bolt after first shot -- Irra

/obj/item/weapon/gun/projectile/boltaction
	name = "bolt-action rifle"
	desc = "A bolt-action rifle of true ww2 (You shouldn't be seeing this)"
	icon_state = "mosin"
	item_state = "mosin" //placeholder
	w_class = 4
	force = 10
	throwforce = 20
	max_shells = 5
	slot_flags = SLOT_BACK
	caliber = "a792x54"
	recoil = 2 //extra kickback
	//fire_sound = 'sound/weapons/sniper.ogg'
	handle_casings = HOLD_CASINGS
	load_method = SINGLE_CASING | SPEEDLOADER
	ammo_type = /obj/item/ammo_casing/a762x54
	magazine_type = /obj/item/ammo_magazine/mosin
	load_shell_sound = 'sound/weapons/clip_reload.ogg'
	//+2 accuracy over the LWAP because only one shot
	accuracy = TRUE
	scoped_accuracy = 2
	gun_type = GUN_TYPE_RIFLE
	attachment_slots = ATTACH_IRONSIGHTS|ATTACH_SCOPE|ATTACH_BARREL
	accuracy_increase_mod = 2.00
	accuracy_decrease_mod = 6.00
	KD_chance = KD_CHANCE_HIGH
	stat = "rifle"
	move_delay = 2

	// 5x as accurate as MGs for now
	accuracy_list = list(

		// small body parts: head, hand, feet
		"small" = list(
			SHORT_RANGE_STILL = 90,
			SHORT_RANGE_MOVING = 45,

			MEDIUM_RANGE_STILL = 80,
			MEDIUM_RANGE_MOVING = 40,

			LONG_RANGE_STILL = 70,
			LONG_RANGE_MOVING = 35,

			VERY_LONG_RANGE_STILL = 60,
			VERY_LONG_RANGE_MOVING = 30),

		// medium body parts: limbs
		"medium" = list(
			SHORT_RANGE_STILL = 95,
			SHORT_RANGE_MOVING = 48,

			MEDIUM_RANGE_STILL = 85,
			MEDIUM_RANGE_MOVING = 43,

			LONG_RANGE_STILL = 75,
			LONG_RANGE_MOVING = 38,

			VERY_LONG_RANGE_STILL = 65,
			VERY_LONG_RANGE_MOVING = 33),

		// large body parts: chest, groin
		"large" = list(
			SHORT_RANGE_STILL = 100,
			SHORT_RANGE_MOVING = 50,

			MEDIUM_RANGE_STILL = 90,
			MEDIUM_RANGE_MOVING = 45,

			LONG_RANGE_STILL = 80,
			LONG_RANGE_MOVING = 40,

			VERY_LONG_RANGE_STILL = 70,
			VERY_LONG_RANGE_MOVING = 35),
	)

	var/bolt_open = FALSE
	var/check_bolt = FALSE //Keeps the bolt from being interfered with
	var/check_bolt_lock = FALSE //For locking the bolt. Didn't put this in with check_bolt to avoid issues
	var/bolt_safety = FALSE //If true, locks the bolt when gun is empty
	var/next_reload = -1
	var/jammed_until = -1
	var/jamcheck = 0
	var/last_fire = -1


/obj/item/weapon/gun/projectile/boltaction/attack_self(mob/user)
	if(!check_bolt)//Keeps people from spamming the bolt
		check_bolt++
		if(!do_after(user, 1, src, FALSE, TRUE,INCAPACITATION_DEFAULT, TRUE))//Delays the bolt
			check_bolt--
			return
	else return
	if(check_bolt_lock)
		user << "<span class='notice'>The bolt won't move, the gun is empty!</span>"
		check_bolt--
		return
	bolt_open = !bolt_open
	if(bolt_open)
		if(chambered)
			playsound(loc, 'sound/weapons/bolt_open.ogg', 50, TRUE)
			user << "<span class='notice'>You work the bolt open, ejecting [chambered]!</span>"
			chambered.loc = get_turf(src)
			loaded -= chambered
			chambered = null
			if(bolt_safety)
				if(!loaded.len)
					check_bolt_lock++
					user << "<span class='notice'>The bolt is locked!</span>"
		else
			playsound(loc, 'sound/weapons/bolt_open.ogg', 50, TRUE)
			user << "<span class='notice'>You work the bolt open.</span>"
	else
		playsound(loc, 'sound/weapons/bolt_close.ogg', 50, TRUE)
		user << "<span class='notice'>You work the bolt closed.</span>"
		bolt_open = FALSE
	add_fingerprint(user)
	update_icon()
	check_bolt--

/obj/item/weapon/gun/projectile/boltaction/special_check(mob/user)
	if(bolt_open)
		user << "<span class='warning'>You can't fire [src] while the bolt is open!</span>"
		return FALSE
	return ..()

/obj/item/weapon/gun/projectile/boltaction/load_ammo(var/obj/item/A, mob/user)
	if(!bolt_open)
		return
	if(check_bolt_lock)
		--check_bolt_lock // preincrement is superior
	..()

/obj/item/weapon/gun/projectile/boltaction/unload_ammo(mob/user, var/allow_dump=1)
	if(!bolt_open)
		return
	..()

// rifles take 0.3 seconds to fire now, meaning they're weaker than SMGs at close range
/obj/item/weapon/gun/projectile/boltaction/special_check(var/mob/user)
	. = ..()
	if (!.)
		return .
	if (!do_after(user, 2, get_turf(user)))
		return FALSE
	return TRUE

/obj/item/weapon/gun/projectile/boltaction/handle_post_fire()
	..()

	if (last_fire != -1)
		if (world.time - last_fire <= 5)
			jamcheck += 4
		else if (world.time - last_fire <= 10)
			jamcheck += 3
		else if (world.time - last_fire <= 20)
			jamcheck += 2
		else if (world.time - last_fire <= 30)
			++jamcheck
		else if (world.time - last_fire <= 40)
			++jamcheck
		else if (world.time - last_fire <= 50)
			++jamcheck
		else
			jamcheck = 0
	else
		++jamcheck

	if (prob(jamcheck*2))
		jammed_until = max(world.time + (jamcheck * 5), 50)
		jamcheck = 0

	last_fire = world.time

/obj/item/weapon/gun/projectile/boltaction/mosin
	name = "Mosin-Nagant"
	desc = "Soviet bolt-action rifle chambered in 7.62x54mmR cartridges. It looks worn and has Katyusha on the butt."
	force = 12
	fire_sound = 'sound/weapons/mosin_shot.ogg'
	caliber = "a762x54"
	weight = 4.0
	effectiveness_mod = 0.97

//This should only be temporary until more attachment icons are made, then we switch to adding/removing icon masks
/obj/item/weapon/gun/projectile/boltaction/mosin/update_icon(var/add_scope = FALSE)
	if(add_scope)
		if(bolt_open)
			icon_state = "mosin_scope_open"
			item_state = "mosin_scope"
			return
		else
			icon_state = "mosin_scope"
			item_state = "mosin_scope"
			return
	if(bolt_open)
		if(!findtext(icon_state, "_open"))
			icon_state = addtext(icon_state, "_open") //open
	else if(icon_state == "mosin_scope_open") //closed
		icon_state = "mosin_scope"
	else if(icon_state == "mosin_scope")
		return
	else
		icon_state = "mosin"

/obj/item/weapon/gun/projectile/boltaction/kar98k
	name = "Kar-98K"
	desc = "German bolt-action rifle chambered in 7.92x57mm Mauser ammunition. It looks clean and well-fabricated."
	icon_state = "kar98k"
	item_state = "kar98k"
	caliber = "a792x57"
	fire_sound = 'sound/weapons/kar_shot.ogg'
	ammo_type = /obj/item/ammo_casing/a792x57
	magazine_type = /obj/item/ammo_magazine/kar98k
	bolt_safety = TRUE
	effectiveness_mod = 1.03

/obj/item/weapon/gun/projectile/boltaction/kar98k/New()
	..()
	weight = pick(3.7, 3.8, 3.9, 4.0, 4.1)

//This should only be temporary until more attachment icons are made, then we switch to adding/removing icon masks
/obj/item/weapon/gun/projectile/boltaction/kar98k/update_icon(var/add_scope = FALSE)
	if(add_scope)
		if(bolt_open)
			icon_state = "kar98k_scope_open"
			item_state = "kar98k_scope"
			return
		else
			icon_state = "kar98k_scope"
			item_state = "kar98k_scope"
			return
	if(bolt_open)
		if(!findtext(icon_state, "_open"))
			icon_state = addtext(icon_state, "_open") //open
	else if(icon_state == "kar98k_scope_open") //closed
		icon_state = "kar98k_scope"
	else if(icon_state == "kar98k_scope")
		return
	else
		icon_state = "kar98k"

/obj/item/weapon/gun/projectile/boltaction/carcano
	name = "Carcano M1891"
	desc = "Italian made bolt action rifle Carcano Modello 1891. It smells of tomato pasta and gunpowder."
	icon_state = "carcano"
	item_state = "carcano"
	caliber = "6.5x52mm"
	fire_sound = 'sound/weapons/kar_shot.ogg'
	ammo_type = /obj/item/ammo_casing/c65x52mm
	magazine_type = /obj/item/ammo_magazine/c65x52mm
	max_shells = 6
	bolt_safety = FALSE
	weight = 3.9

/obj/item/weapon/gun/projectile/boltaction/carcano/update_icon(var/add_scope = FALSE)
	if(add_scope)
		if(bolt_open)
			icon_state = "carcano_scope_open"
			item_state = "carcano"
			return
		else
			icon_state = "carcano_scope"
			item_state = "carcano"
			return
	if(bolt_open)
		if(!findtext(icon_state, "_open"))
			icon_state = addtext(icon_state, "_open") //open
	else if(icon_state == "carcano_scope_open") //closed
		icon_state = "carcano_scope"
	else if(icon_state == "carcano_scope")
		return
	else
		icon_state = "carcano"

