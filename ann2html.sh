#!/bin/sh

export LC_ALL=C
awk '
BEGIN {
	noteid = 1
	sid = 1
	ss[sid] = "<pre>"
}

{
	gsub(/\&/, "\\&amp;")
	gsub(/</, "\\&lt;")
	gsub(/>/, "\\&gt;")
}

!title && /^[^@]/ {
	title = $0
	gsub(/  +/, "  ", title)
	gsub(/Committee Draft --/, "", title)
}

/^@sect Contents/ {
	ss[sid] = ss[sid] "</pre>\n"
	seencontents = 1
	level = 0
}

seencontents && !seenfore && /^[^@]/ {
	id = $1
	if (id ~ /Annex/)
		id = $2
	sub(/\.$/, "", id)

	s = $0
	if (!sub(/ +\. .*/, "", s)) {
		getline
		sub(/^ */, " ")
		s = s $0
		sub(/ +\. .*/, "", s)
	}

	if (match(s, /&lt;[a-zA-Z0-9_]*\.h&gt;/)) {
		h = substr($0,RSTART,RLENGTH)
		if (!(h in header))
			header[h] = id
	}

	s = "<a href=\"#" id "\">" s "</a>\n"

	s = "<li>" s
	n = split(id, a, /\./)
	while (n > level) {
		s = "<ul>\n" s
		level++
	}
	while (n < level) {
		s = "</ul>\n" s
		level--
	}
	ss[sid] = ss[sid] s
	next
}

/^@sect Foreword/ {
	while (level--)
		ss[sid] = ss[sid] "</ul>\n"
	seenfore = 1
}

/^@sect Index/ {
	seenindex = 1
}

/^@title/ {
	if (!seencontents) {
		ss[sid] = ss[sid] "</pre>\n"
	}
	sid++
	getline
	ss[sid] = ss[sid] "<h1>" $0 "</h1>\n"
	if (!seencontents) {
		ss[sid] = ss[sid] "<pre>\n"
	}
	next
}

/^@sect 3\./ {
	markdef = 1
}

/^@sect/ {
	sid++
	slevel = split($2,a,/\./)+1
	if (slevel > 5)
		slevel = 5
	sect = $2
	getline
	# todo hX, back to top
	ss[sid] = sprintf("<h%s><a name=\"%s\" href=\"#%s\">%s</a></h%s>\n", slevel, sect, sect, $0, slevel)
	if ($0 == "Index")
		ss[sid] = ss[sid] "<pre>\n"
	next
}

/^@ul/ {
	ss[sid] = ss[sid] "<ul>\n"
	next
}
/^@end ul/ {
	ss[sid] = ss[sid] "</ul>\n"
	next
}
/^@ol/ {
	ss[sid] = ss[sid] "<ol>\n"
	next
}
/^@end ol/ {
	ss[sid] = ss[sid] "</ol>\n"
	next
}

/^@li/ {
	ss[sid] = ss[sid] "<li>"
	next
}

/^@pre/ {
	pre = "<pre>"
	next
}

/^@end pre/ {
	if (!pre)
		next
	pre = pre "\n</pre>\n"
	if (nn)
		note[nn] = note[nn] "\n" pre
	else
		ss[sid] = ss[sid] pre
	pre = ""
	next
}

/^@note/ {
	nn = $2+0
	note[nn] = ""
	next
}

/^@page/ {
	nn = 0
	p = $2
	getline
	ss[sid] = ss[sid] "<!--page " p " -->\n"
	next
}

/^@para/ {
	ss[sid] = ss[sid] "<p><!--para " $2 " -->\n"
	next
}

/^ ?(Syntax|Semantics|Description|Constraints|Synopsis|Returns|Recommended practice|Implementation limits|Environmental limits)$/ {
	ss[sid] = ss[sid] "<h6>" $0 "</h6>\n"
	next
}

!seenfore {
	ss[sid] = ss[sid] $0 "\n"
	next
}

{
	s = $0
	p = ""
	if (seenindex)
		r = " [A-Z1-9][0-9.]*"
	else
		r = "[ ([][A-Z1-9]\\.[0-9.]*[0-9]"
	# hack
	s = " " s
	while (match(s, r)) {
		p = p substr(s,1,RSTART)
		m = substr(s,RSTART+1,RLENGTH-1)
		if (m ~ /\.0$/ || m ~ /[4-9][0-9]/ || m ~ /[0-3][0-9][0-9]/ ||
		    substr(s,RSTART+RLENGTH,1) ~ /[a-zA-Z_\-]/)
			p = p m
		else
			p = p "<a href=\"#" m "\">" m "</a>"
		s = substr(s,RSTART+RLENGTH)
	}
	s = p s
	p = ""
	while (match(s, /[Aa]nnex [A-Z]/)) {
		p = p substr(s,1,RSTART-1)
		m = substr(s,RSTART,RLENGTH)
		p = p "<a href=\"#" substr(m,RLENGTH,1) "\">" m "</a>"
		s = substr(s,RSTART+RLENGTH)
	}
	s = p s
	p = ""
	while (match(s, /&lt;[a-zA-Z0-9_]*\.h&gt;/)) {
		p = p substr(s,1,RSTART-1)
		m = substr(s,RSTART,RLENGTH)
		if (m in header)
			p = p "<a href=\"#" header[m] "\">" m "</a>"
		else
			p = p m
		s = substr(s,RSTART+RLENGTH)
	}
	s = p s
	p = ""
	# TODO: false positives..
	while (match(s, /[a-z]opt[ )"]/))
		s = substr(s,1,RSTART) "<sub>opt</sub>" substr(s,RSTART+RLENGTH-1)
	if (match(s, /[a-z]opt$/))
		s = substr(s,1,RSTART) "<sub>opt</sub>"
	for (;;) {
		while (match(s, noteid-1 "\\)")) {
			p = p substr(s,1,RSTART-1)
			p = p "<sup><a href=\"#note" noteid-1 "\"><b>" noteid-1 ")</b></a></sup>"
			s = substr(s,RSTART+RLENGTH)
		}
		if (!match(s, noteid "\\)"))
			break
		if (noteid==1 && s !~ /\.1\)/)
			break
		p = p substr(s,1,RSTART-1)
		p = p "<sup><a href=\"#note" noteid "\"><b>" noteid ")</b></a></sup>"
		snote[sid] = snote[sid] " " noteid
		noteid++
		s = substr(s,RSTART+RLENGTH)
	}
	s = p s
	sub(/^ *Forward references/, "<p><b>&</b>", s)
	if (markdef) {
		s = "<b>" s "</b><br>"
		markdef = 0
	}
	if (pre)
		pre = pre "\n" s
	else if (nn)
		note[nn] = note[nn] s "\n"
	else
		ss[sid] = ss[sid] s "\n"
}

END {
	ss[sid] = ss[sid] "</pre>"

	print "<html><head><title>" title "</title></head><body>"

	for (i = 1; i <= sid; i++) {
		print ss[i]
		n = split(snote[i],a)
		if (n > 0) {
			s = "<h6>footnotes</h6>\n"
			for (j = 1; j <= n; j++) {
				s = s "<p><small><a name=\"note" a[j] "\" href=\"#note" a[j] "\">" a[j] ")</a>" note[a[j]+0] "</small>\n"
			}
			print s
		}
	}

	print "</body></html>"
}'
