hl.config({
	dwindle = {
		preserve_split = true,
	},
	ecosystem = {
		no_update_news = true,
		no_donation_nag = true,
	},
	misc = {
		col = {
			splash = CACHYLGREEN,
		},
		middle_click_paste = false,
		enable_swallow = true,
		swallow_regex = "(kitty|ghostty|[Kk]onsole|Alacritty|gnome-terminal|xfce[0-9]?-terminal)",
		vrr = 3,
		focus_on_activate = true,
		allow_session_lock_restore = true,
	},
	render = {
		direct_scanout = 2,
	},
	xwayland = {
		force_zero_scaling = true,
	},
})
