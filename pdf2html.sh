#!/bin/sh

name=$(basename $1 |sed 's/.pdf$//')
[ $name.pdf = $1 ] || {
	echo 'usage: ./pdf2html.sh nxxxx.pdf' 1>&2
	exit 1
}

pdftotext -layout $name.pdf
mv $name.txt $name.txt.utf8
./translit.sh <$name.txt.utf8 >$name.txt
./tohtml.sh <$name.txt >$name.html
./tohtml.pre.sh <$name.txt >$name.pre.html
