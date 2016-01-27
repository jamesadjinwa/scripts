#!/bin/bash
# youtube-url.sh
# author : @adjinwa
# purpose : extract videos' links from a youtube list

# BEGIN

clear

shopt -s -o nounset			# Unable the use of undefined variable

declare -rx SCRIPT=${0##*/} 			# SCRIPT is the name of this script
declare -r WGET="/usr/bin/wget"
declare -r CUT="/usr/bin/cut"
declare -r AWK="/usr/bin/awk"
declare -r MKDIR="/bin/mkdir"

# Sanity checks
if test -z "$BASH" ; then
	printf "$SCRIPT:$LINEO: please run this script with the BASH shell\n" >&2
	exit 192
fi
if test ! -x "$WGET" ; then
	printf "$SCRIPT:$LINEO: the command $WGET is not available - aborting\n" >&2
	exit 192
fi
if test ! -x "$CUT" ; then
	printf "$SCRIPT:$LINEO: the command $CUT is not available - aborting\n" >&2
	exit 192
fi
if test ! -x "$AWK" ; then
	printf "$SCRIPT:$LINEO: the command $AWK is not available - aborting\n" >&2
	exit 192
fi
if test ! -x "$MKDIR" ; then
	printf "$SCRIPT:$LINEO: the command $MKDIR is not available - aborting\n" >&2
	exit 192
fi

# Welcome message
echo "-----------------------------------------------------------------------------"
echo "-   This program will extract all the links from a Youtube list or channel  -"
echo "-   and write them in a CSV file                                            -"
echo "-----------------------------------------------------------------------------"
# Read the user's input
read -p "Enter the url of the youtube playlist or channel: " url

# Url validation
#regex=^((ht|f)tp(s?)\:\/\/|~/|/)?([\w]+:\w+@)?([a-zA-Z]{1}([\w\-]+\.)+([\w]{2,5}))(:[\d]{1,5})?((/?\w+/)+|/?)(\w+\.[\w]{3,4})?((\?\w+=\w+)?(&\w+=\w+)*)?
#if [[ $string =~ $regex ]]
#then
#	echo "Good! $url is a valid url."
#else
#       	echo "Sorry! $url is not a valid url.";
#       	exit	
#fi

# Check if its a youtube url
function CheckYoutubeUrl {
if [ `echo $url | grep ^https://www.youtube.com > /dev/null` -o `echo $url | grep ^http://www.youtube.com > /dev/null` ]
then
	echo "Good! This is a Youtube url"
elif [ `echo $url | grep ^www.youtube.com > /dev/null` ]
then
	echo "Good! This is a Youtube url";
	${$url/www/https://www}	

elif [ `echo $url | grep ^youtube.com > /dev/null` ]
then
	echo "Good! This is a Youtube url";
	${$url/youtube.com/https://www.youtube.com}	
else
	echo "Sorry! This is not a youtube url";
	exit 1
fi
}

# Check if url is that of a youtube playlist 
function CheckYoutubePlaylistUrl {
string2test="playlists"		# Youtube's playlist url end with the string : "playlists"
stringinurl=`echo "$url" | $CUT -d / -f 6`
if [ "$string2test" != "$stringinurl" ]	# "playlist" is at the 6th position in the url
then
	echo "This is not the url of a playlist";
	exit 1
else
	echo "Good! This is a playlist url"
fi
}

# Check if playlist exists
function CheckYoutubeUrlConnection {
echo "Connecting to $url ..."
$WGET -O - $url > /dev/null
case $? in
	0 ) echo "Got it !";;
	4 ) echo "Probably a network failure";; 
	* ) echo "An error occured!"; exit 2
esac

}

# TODO  Check if url is that of a youtube channel
# function CheckYoutubeChannelUrl {
# sleep 2
# }

# Check if playlist exits

# Extract urls in the youtube playlist and 
# Create a csv file and write into it the extracted urls 
function ExtractYoutubePlaylistLinks {
echo "Extracting links in $url ... "
# Check the number of links
numberoflinks=`$WGET -qO - $url \
	| grep -o '<h3 .*href=\"\/playlist.*>' \
	| sed -e 's/<a /\n<a /g' | sed -e 's/<a .*href=['"'"'"]/    /' -e 's/["'"'"'].*$//' -e '/^$/ d' \
	| sed -e 's/<h3 .*class=$//g' | sed '/^\s*$/d' \
	| wc -l`

if [ "$numberoflinks" -eq 0 ]
then
	echo "Sorry ! $numberoflinks links found.";
	exit 3
else
	echo "$numberoflinks links found !"
fi
}

function ExtractUsername {
username=`echo $url | $CUT -d / -f 5` 			# Etract the username. Will be part of the csv filename.
}

function WriteLinksToFile {

ExtractUsername
# Write name of link
# Awk does the construction of csv file with "," as seperator
`$WGET -qO - $url \
	| grep -o '<h3 .*href=\"\/playlist.*>' \
	| sed -e 's/<a /\n<a /g' -e 's/title=/\ntitle=/g' -e 's/href=['"'"'"]/\n/g' -e 's/title=['"'"'"]//g' \
	| sed -e 's/^<a //g' -e 's/^<h3 //g' -e 's/^class.*$//g' -e 's/".*$//g' | sed '/^\s*$/d' \
	| sed -e '/^\/playlist/! s/.*/"&"/g' -e 's/^\/playlist/https:\/\/www.youtube.com&/' \
	| $AWK '!/playlist/{if (x)print x;x="";}{x=(!x)?$0:x","$0;}END{print x;}' >$username"_playlists.csv"`

# Insert header in csv file (Title, Link)
# `sed -i.bak 1i"Title,Link" $username"_playlists.csv"`
}

function WriteVideoUrlToFile {
# TODO Read each link in the csv file and extract the urls of videos. Save the urls found in file.
# The file name is the title of the url
ExtractUsername
if [[ ! -d $username"_playlists" ]] ; then
	$MKDIR $username"_playlists"
fi
n=0
while read line; do
	n=$[$n +1]
	echo $line
	url=`echo $line | $CUT -d , -f 2`
	`$WGET -qO - $url \
		| grep 'data-title' \
		| sed 's/data-title/\ndata-title /g; s/<a /\n<a /g' \
		| grep -v '^<tr' \
		| sed 's/><td class=.*.*.*//g; s/class=.*//g; s/<a href=//g; s/data-title =//g' \
		| sed 's/ data-video-id=.*//g' \
		| sed 's/^"\/watch?v/"https:\/\/www.youtube.com\/watch?v/' \
		| $AWK '!/watch/{if (x)print x;x="";}{x=(!x)?$0:x","$0;}END{print x;}' \
		>$username"_playlists/playlist"$n".csv"`
done <$username"_playlists.csv"
}

# TODO Put all the files generated in a directory. The directory name is the Youtube username.


CheckYoutubeUrl 
CheckYoutubePlaylistUrl
CheckYoutubeUrlConnection 
ExtractYoutubePlaylistLinks 
WriteLinksToFile 
WriteVideoUrlToFile

exit 0
# END
