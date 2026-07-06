return {
	{
		id = "dragon",
		displayName = "Dragon",
		icon = "DR",
		description = "Soar above the map with steady, controllable flight.",
		movement = {
			walkSpeed = 18,
			jumpPower = 60,
			flightSpeed = 52,
		},
		abilities = {
			flight = true,
		},
		appearance = {
			themeColor = Color3.fromRGB(203, 64, 47),
			bodyColors = {
				HeadColor = "Bright red",
				TorsoColor = "Crimson",
				LeftArmColor = "Bright red",
				RightArmColor = "Bright red",
				LeftLegColor = "Crimson",
				RightLegColor = "Crimson",
			},
			cosmetic = "Dragon",
		},
	},
	{
		id = "goblin",
		displayName = "Goblin",
		icon = "GB",
		description = "Quick on foot, sneaky, and built for fast ground play.",
		movement = {
			walkSpeed = 26,
			jumpPower = 54,
		},
		abilities = {
			flight = false,
		},
		appearance = {
			themeColor = Color3.fromRGB(88, 153, 73),
			bodyColors = {
				HeadColor = "Br. yellowish green",
				TorsoColor = "Earth green",
				LeftArmColor = "Br. yellowish green",
				RightArmColor = "Br. yellowish green",
				LeftLegColor = "Earth green",
				RightLegColor = "Earth green",
			},
			cosmetic = "Goblin",
		},
	},
}
