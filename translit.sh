#!/bin/sh

# assumes utf8 locale..
# remove nonascii from the output of pdftotext -layout standard.pdf

sed '
s/\f/(newpage)/g
# utf8 fixes
s/ﬁ/fi/g
s/ﬂ/fl/g
s/§/!S/g
s/©/(C)/g
s/—/--/g
s/−/-/g
s/∗/*/g
s/ˆ/^/g
s/〈/</g
s/〉/>/g
s/⎡/[^/g
s/⎤/^]/g
s/⎣/[_/g
s/⎦/_]/g
s/⎢/[ /g
s/⎥/ ]/g
s/⎧/{/g
s/⎨/{/g
s/⎩/{/g
s/±/(+-)/g
s/≤/<=/g
s/≥/>=/g
s/≠/!=/g
s/Σ/(Sum)/g
s/√/(sqrt)/g
s/π/pi/g
s/∞/(inf)/g
s/ƒ/fl./g
s/∫/(integral)/g
s/Γ/(Gamma)/g
s/×/x/g
s/•/o/g
s/⎯/-/g
s/↑/(uparrow)/g
s/↓/(downarrow)/g
s/↔/<->/g
s/→/->/g
s/‘/'\''/g
s/’/'\''/g
# pdftotext layout fixes
s/_ _/__/g
# floats are sometimes broken
s/\([0-9]\)\. \([0-9]\)/\1.\2/g
' | LC_ALL=C tr -c '\n-~' '?' | awk '
BEGIN {
	getline
	last=$0
	side=0
}
/^$/ {
	nl=nl "\n"
	next
}
/^\(newpage\)/ {
	n=split(last,a)
	if(side)
		p=a[1]
	else
		p=a[n]
	side=!side
	print "\n[page " p "]"
	getline
	getline
	last=$0
	next
}
{
	print last
	last=nl $0
	nl=""
}'
