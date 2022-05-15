local Translations = {
    error = {
        canceled = 'Canceled',
        bled_out = 'You have bled out...',
        impossible = 'Action Impossible...',
        no_player = 'No Player Nearby',
        no_firstaid = 'You need a First Aid Kit',
        no_bandage = 'You need a Bandage',
        beds_taken = 'Beds are occupied...',
        possessions_taken = 'All your possessions have been taken...',
        not_enough_money = 'You don\'t have enough money on you...',
        cant_help = 'You can\'t help this person...',
        not_ems = 'You are not EMS or not signed in',
        not_online = 'Player Not Online'
    },
    success = {
        revived = 'You revived a person',
        healthy_player = 'Player is Healthy',
        helped_player = 'You helped the person',
        wounds_healed = 'Your wounds have been healed!',
        being_helped = 'You are being helped...'
    },
    info = {
        civ_died = 'Civilian Died',
        civ_down = 'Civilian Down',
        civ_call = 'Civilian Call',
        self_death = 'Themselves or an NPC',
        wep_unknown = 'Unknown',
        respawn_txt = 'RESPAWN IN: ~r~%{deathtime}~s~ SECONDS',
        respawn_revive = 'HOLD [~r~E~s~] FOR %{holdtime} SECONDS TO RESPAWN FOR $~r~%{cost}~s~',
        bleed_out = 'YOU WILL BLEED OUT IN: ~r~%{time}~s~ SECONDS',
        bleed_out_help = 'YOU WILL BLEED OUT IN: ~r~%{time}~s~ SECONDS, YOU CAN BE HELPED',
        request_help = 'PRESS [~r~G~s~] TO REQUEST HELP',
        help_requested = 'EMS PERSONNEL HAVE BEEN NOTIFIED',
        amb_plate = 'AMBU', -- Should only be 4 characters long due to the last 4 being a random 4 digits
        heli_plate = 'LIFE',  -- Should only be 4 characters long due to the last 4 being a random 4 digits
        status = 'Status Check',
        is_staus = 'Is %{status}',
        healthy = 'You are completely healthy again!',
        safe = 'Hospital Safe',
        pb_hospital = 'Pillbox Hospital',
        mz_hospital = 'Mount Zonah Hospital',
        pain_message = 'Your %{limb} feels %{severity}',
        many_places = 'You have pain in many places...',
        bleed_alert = 'You are %{bleedstate}',
        ems_alert = 'EMS Alert - %{text}',
        mr = 'Mr.',
        mrs = 'Mrs.',
        dr_needed = 'A doctor is needed at Pillbox Hospital',
        ems_report = 'EMS Report',
        message_sent = 'Message to be sent',
        check_health = 'Check a Players Health',
        heal_player = 'Heal a Player',
        revive_player = 'Revive a Player',
        revive_player_a = 'Revive A Player or Yourself (Admin Only)',
        player_id = 'Player ID (may be empty)',
        pain_level = 'Set Yours or A Players Pain Level (Admin Only)',
        kill = 'Kill A Player or Yourself (Admin Only)',
        heal_player_a = 'Heal A Player or Yourself (Admin Only)',
    },
    mail = {
        sender = 'Pillbox Hospital',
        subject = 'Hospital Costs',
        message = 'Dear %{gender} %{lastname}, <br /><br />Hereby you received an email with the costs of the last hospital visit.<br />The final costs have become: <strong>$%{costs}</strong><br /><br />We wish you a quick recovery!'
    },
    states = {
        irritated = 'irritated',
        quite_painful = 'quite painful',
        painful = 'painful',
        really_painful = 'really painful',
        little_bleed = 'bleeding a little bit...',
        bleed = 'bleeding...',
        lot_bleed = 'bleeding a lot...',
        big_bleed = 'bleeding very much...',
    },
    menu = {
        amb_vehicles = 'Ambulance Vehicles',
        status = 'Heath Status',
        close = '⬅ Close Menu',
    },
    text = {
        pstash_button = '[E] - Personal stash',
        pstash = 'Personal stash',
        onduty_button = '[E] - Go On Duty',
        offduty_button = '[E] - Go Off Duty',
        duty = 'On/Off Duty',
        armory_button = '[E] - Armory',
        armory = 'Armory',
        veh_button = '[E] - Grab / Store Vehicle',
        heli_button = '[E] - Grab / Store Helicopter',
        elevator_roof = '[E] - Take the elevator to the roof',
        elevator_main = '[E] - Take the elevator down',
        bed_out = '[E] - To get out of bed..',
        call_doc = '[E] - Call doctor',
        call = 'Call',
        check_in = '[E] Check in',
        check = 'Check In',
        lie_bed = '[E] - To lie in bed'
    },
    body = {
        head = 'Head',
        neck = 'Neck',
        spine = 'Spine',
        upper_body = 'Upper Body',
        lower_body = 'Lower Body',
        left_arm = 'Left Arm',
        left_hand = 'Left Hand',
        left_fingers = 'Left Fingers',
        left_leg = 'Left Leg',
        left_foot = 'Left Foot',
        right_arm = 'Right Arm',
        right_hand = 'Right Hand',
        right_fingers = 'Right Fingers',
        right_leg = 'Right Leg',
        right_foot = 'Right Foot',
    },
    progress = {
        ifaks = 'Taking ifaks...',
        bandage = 'Using Bandage...',
        painkillers = 'Taking Painkillers...',
        revive = 'Reviving Person...',
        healing = 'Healing Wounds...',
        checking_in = 'Checking in...',
    },
    logs = {
        death_log_title = "%{playername} (%{playerid}) is dead",
        death_log_message = "%{killername} has killed %{playername} with a **%{weaponlabel}** (%{weaponname})",
    }
}

Lang = Locale:new({
    phrases = Translations,
    warnOnMissing = true
})