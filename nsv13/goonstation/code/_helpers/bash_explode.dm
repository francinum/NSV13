// TODO: Variable processing.

#define NONE 0
#define APOS 1
#define QUOT 2

#define ESCAPE "\\"

/proc/bash_explode(var/str)
	var/fin = 0
	var/state = NONE
	var/pos = 1
	var/qpos = 1
	var/buf = ""
	while (!fin)
		switch(state)
			if (NONE)
				var/NA = findtext(str, "'", pos)
				var/NQ = findtext(str, "\"", pos)
				if (!NA && !NQ)
					buf += copytext(str, pos)
					fin = 1
				else if (NA && !NQ || (NA && NQ && NA < NQ))
					if (chs(str, NA - 1) == ESCAPE)
						buf += copytext(str, pos, NA - 1) + "'"
						pos = NA + 1
						continue
					else
						buf += copytext(str, pos, NA)
						pos = NA + 1
						state = APOS
				else if (NQ && !NA || (NA && NQ && NQ < NA))
					if (chs(str, NQ - 1) == ESCAPE)
						buf += copytext(str, pos, NQ - 1) + "\""
						pos = NQ + 1
						continue
					else
						buf += copytext(str, pos, NQ)
						pos = NQ + 1
						qpos = NQ + 1
						state = QUOT
				else if (NA == NQ)
					//??????
					return null

			if (APOS)
				var/NA = findtext(str, "'", pos)
				if (!NA)
					return null
				var/temp = copytext(str, pos, NA)
				buf += replacetext(temp, " ", "&nbsp;")
				pos = NA + 1
				state = NONE

			if (QUOT)
				var/NQ = findtext(str, "\"", pos)
				if (!NQ)
					return null
				if (copytext(str, NQ - 1, NQ) == ESCAPE)
					pos = NQ + 1
					continue
				var/temp = copytext(str, qpos, NQ)
				buf += replacetext(replacetext(temp, " ", "&nbsp;"), "\\\"", "\"")
				pos = NQ + 1
				state = NONE

	var/list/el = splittext(buf, " ")
	var/list/ret = list()
	for (var/s in el)
		ret += replacetext(s, "&nbsp;", " ")
	return ret

#undef ESCAPE
#undef QUOT
#undef APOS
#undef NONE