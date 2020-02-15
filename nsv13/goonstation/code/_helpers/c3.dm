#define CURRENT_SPACE_YEAR GLOB.year_integer+540

//File Permissions

#define COMP_ROWNER 1
#define COMP_WOWNER 2
#define COMP_DOWNER 4
#define COMP_RGROUP 8
#define COMP_WGROUP 16
#define COMP_DGROUP 32
#define COMP_ROTHER 64
#define COMP_WOTHER 128
#define COMP_DOTHER 256

#define COMP_HIDDEN 0
#define COMP_ALLACC 511

//Global Passcodes

GLOBAL_VAR_INIT(netpass_heads, gen_netpass())
GLOBAL_VAR_INIT(netpass_security, gen_netpass())
GLOBAL_VAR_INIT(netpass_medical, gen_netpass())

//Helper Procs

/proc/corruptText(var/t, var/p)
	if(!t)
		return ""
	var/tmp = ""
	for(var/i = 1, i <= length(t), i++)
		if(prob(p))
			tmp += pick("{", "|", "}", "~", "€", "ƒ", "†", "‡", "‰", "¡", "¢", "£", "¤", "¥", "¦", "§", "©", "«", "¬", "®", "°", "±", "²", "³", "¶", "¿", "ø", "ÿ", "þ")
		else
			tmp += copytext(t, i, i+1)
	return tmp

/proc/is_hex(hex)
	if (!( istext(hex) ))
		return FALSE
	var/hex_regex = regex(@"^[0-9a-f]+$", "i")
	return (findtext(hex, hex_regex) == 1)

/proc/random_hex(var/digits as num)
	var/list/hex_chars = list("0","1","2","3","4","5","6","7","8","9","A","B","C","D","E","F")
	if (!digits)
		digits = 6
	var/return_hex = ""
	for (var/i = 0, i < digits, i++)
		return_hex += pick(hex_chars)
	return return_hex

/proc/format_username(var/playerName)
	if (!playerName)
		return "Unknown"

	var/list/name_temp = splittext(playerName, " ")
	if (!name_temp.len)
		playerName = "Unknown"
	else if (name_temp.len == 1)
		playerName = name_temp[1]
	else //Ex: John Smith becomes JSmith
		playerName = copytext( ( copytext(name_temp[1],1, 2) + name_temp[name_temp.len] ), 1, 16)
	return lowertext(replacetext(playerName, "/", null))

//Jesus fuck what does this even do -FRANC
/proc/chs(var/str, var/i)
	return ascii2text(text2ascii(str,i))

/proc/gen_netpass() //-Francinum
	var/codes = strings(ION_FILE, "ionabstract")
	return "[rand(1111,9999)] [pick(codes)]-[rand(111,999)]"

//Bash Explode gets it's own file for being way too fucking long

/proc/format_net_id(var/refstring)
	if(!refstring)
		return
	. = copytext(refstring,4,(length(refstring)))
	. = add_zero(., 8)

/proc/generate_net_id(var/atom/the_atom)
	if(!the_atom) return
	var/tag_holder = the_atom.tag
	the_atom.tag = null //So we generate from internal ref id
	. = format_net_id("\ref[the_atom]")
	the_atom.tag = tag_holder