#!/bin/sh

export LC_ALL=C
awk '
function initpage() {
	if (innote)
		endpre()

	indent = 10
	para = 0
	innote = 0
	ok = 0
	empty = ""
	page = ""
}

function endlist() {
	if (listindex) {
		listindent = 0
		listindex = 0
		print "@end ol"
	} else if (listlevel) {
		listlevel--
		print "@end ul"
	}
}

function donote(s) {
	if (match(s, /^[1-9][0-9]*\) +/)) {
		# todo..
		endpre()
		print "@note " substr(s, 1, RLENGTH-2)
		s = substr(s, RLENGTH+1)
		innote = 1
		noteindent = RLENGTH
	} else if (innote) {
		if (match(s, /^ +/) && RLENGTH >= noteindent)
			s = substr(s, noteindent+1)
		else
			innote = 0
	}
	return s
}

function doul(s) {
	if (!listlevel) {
		if (s ~ /^--/) {
			s = dopre(s)
			listlevel++
			print "@ul"
		} else
			return s
	}
	if (listlevel == 1) {
		if (s ~ /^   *o /) {
			listlevel++
			print "@ul"
		} else if (s ~ /^--/) {
			s = dopre(s)
			s = substr(s , 3)
			print "@li"
		} else if (match(s, /^ +/) && RLENGTH > 1) {
			sub(/^  /, "", s)
		} else if (s !~ /^$/) {
			endpre()
			endlist()
		}
	}
	if (listlevel == 2) {
		if (s ~ /^   *o /) {
			sub(/ *o /, "", s)
			s = dopre(s)
			print "@li"
		} else if (match(s, /^ +/) && RLENGTH > 5) {
			sub(/^ +/, "", s)
		} else if (s !~ /^$/) {
			sub(/^  /, "", s)
			endlist()
		}
	}
	return s
}

function dool(s) {
	if (listindex == 0) {
		if (s ~ /^   *1\. /)
			print "@ol"
		else
			return s
	}

	if (match(s, "^ +" (listindex+1) "\\. +")) {
		listindex++
		listindent = RLENGTH
		s = substr(s, RLENGTH)
		s = dopre(s)
		print "@li " listindex
	} else if (match(s, /^ +/) && RLENGTH >= listindent) {
		s = substr(s, listindent+1)
	} else if (s !~ /^$/) {
		endpre()
		endlist()
	}
	return s
}

function endpre() {
	if (inpre) {
		print "@end pre"
		inpre = 0
	}
}

function dopre(s) {
	if (seenindex != 1)
		return s
	if (!inpre) {
		if (s ~ /^    */) {
			print "@pre"
			inpre = 1
		} else
			return s
	}
	if (s !~ /^    */)
		endpre()
	return s
}

function dosect(s,   n,a) {
	if (seenindex > 1)
		return s
	if (s ~ /^Programming languages/) {
		print "@title " s
		return s
	}
	if (s !~ /^([1-9]\.|[A-Z]\.[1-9]| *Annex |Contents|Index|Foreword|Introduction| *Bibliography)/)
		return s
	if (s ~ /^[0-9.]+[^0-9. ]/)
		return s
	n = split(s, a)
	id = a[1]
	if (id ~ /Annex/)
		id = a[2]
	if (id ~ /^([A-Z]|[1-9]\.|[1-9A-Z]\.[0-9.]*[0-9]|Contents|Index|Foreword|Introduction|Bibliography)$/ &&
	    (n==1 || a[2] ~ /^[A-Z.v]/)) {
		sub(/^ +/,"",s)
		if (id ~ /\.$/)
			id = substr(id,1,length(id)-1)
		if (seenindex || id == "Contents") {
			endpre()
			endlist()
			print "@sect " id
		}
		if (id == "Index")
			seenindex++
	}
	return s
}

BEGIN {
	listlevel = 0
	listindex = 0
	listindent = 0
	noteindent = 0
	inpre = 0
	seenindex = 0
	pn = 1
	initpage()
}

/^\[page/ {
	if(!para && indent && ok)
		indent = -1

	if (!ok)
		indent = 0

	n = split(page, a, /\n/)
	print "@page " pn
	print "@indent " indent
	if (indent < 0)
		indent = 0
	for (i = 1; i < n; i++) {
		if (a[i] ~ /^@/) {
			if (a[i] ~ /^@para/) {
				endpre()
				endlist()
			}
			print a[i]
		} else {
			s = substr(a[i], indent+1)
			s = dosect(s)
			s = donote(s)
			if (!innote) {
				s = doul(s)
				s = dool(s)
			}
			s = dopre(s)
			print s
		}
	}

	pn++
	initpage()
	next
}

/^$/ {
	if (ok)
		empty = empty "\n"
	next
}

length(empty) > 0 {
	page = page empty
	empty = ""
}

{
	ok = 1
	if (match($0, /^[0-9]+ +/)) {
		para = 1
		i = RLENGTH
		match($0, /^[0-9]+/)
		page = page "@para " substr($0,1,RLENGTH) "\n"
	} else if (match($0, /^ +/)) {
		i = RLENGTH
	} else if ($0 !~ /^[0-9]*$/) {
		i = 0
	} else
		i = 10
	if (i < indent)
		indent = i
	page = page $0 "\n"
}'

