#!/bin/bash
# youtube-url.sh
# author : @adjinwa
# purpose : extract videos' links from a youtube list

# BEGIN

clear

declare -rx SCRIPT=${0##*/} 			# SCRIPT is the name of this script
declare -r WGET=`which wget`
declare -r CUT=`which cut`
declare -r AWK=`which awk`

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
	exit
fi
}

# Check if url is that of a youtube playlist 
function CheckYoutubePlaylistUrl {
string2test="playlists"		# Youtube's playlist url end with the string : "playlists"
stringinurl=`echo "$url" | $CUT -d / -f 6`
if [ "$string2test" != "$stringinurl" ]	# "playlist" is at the 6th position in the url
then
	echo "This is not the url of a playlist";
	exit
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
	* ) echo "An error occured!"; exit
esac

}

# TODO
# Check if url is that of a youtube channel
function CheckYoutubeChannelUrl {
sleep 2
}
# Check if playlist exits

# Extract urls in the youtube playlist and 
# Create a csv file and write into it the extracted urls 
function ExtractYoutubePlaylistLinks {
echo "Extracting links in $url ... "
# Check the number of links
numberoflinks=`$WGET -qO - $url | grep -o '<h3 .*href=\"\/playlist.*>' | sed -e 's/<a /\n<a /g' | sed -e 's/<a .*href=['"'"'"]/    /' -e 's/["'"'"'].*$//' -e '/^$/ d' | sed -e 's/<h3 .*class=$//g' | sed '/^\s*$/d' | wc -l`
if [ "$numberoflinks" -eq 0 ]
then
	echo "Sorry ! $numberoflinks links found.";
	exit
else
	echo "$numberoflinks links found !"
fi
}

function WriteLinksToFile {
username=`echo $url | $CUT -d / -f 5` 			# Etract the username. Will be part of the csv filename.
#`$WGET -qO - $url | grep -o '<h3 .*href=\"\/playlist.*>' | sed -e 's/<a /\n<a /g' | sed -e 's/<a .*href=['"'"'"]//' -e 's/["'"'"'].*$//' -e '/^$/ d' | sed -e 's/<h3 .*class=$//g' | sed '/^\s*$/d' | sed -e "s/^/https:\/\/www.youtube.com\/user\/$username/" >$username"_playlist.csv"`


# Write name of link
# Awk does the construction of csv file with "," as seperator
`$WGET -qO - $url | grep -o '<h3 .*href=\"\/playlist.*>' | sed -e 's/<a /\n<a /g' | sed -e 's/title=/\ntitle=/g' | sed -e 's/href=['"'"'"]/\n/g' | sed -e 's/title=['"'"'"]//g' | sed -e 's/^<a //g' | sed -e 's/^<h3 //g' | sed -e 's/^class.*$//g' | sed -e 's/".*$//g' | sed '/^\s*$/d' | sed -e '/^\/playlist/! s/.*/"&"/g' | sed -e 's/^\/playlist/https:\/\/www.youtube.com&/' | $AWK '!/playlist/{if (x)print x;x="";}{x=(!x)?$0:x","$0;}END{print x;}' >$username"_playlist.csv"`

# Insert header in csv file (Title, Link)
`sed -i.bak 1i"Title,Link" $username"_playlist.csv"`
}

CheckYoutubeUrl 
CheckYoutubePlaylistUrl
CheckYoutubeUrlConnection 
ExtractYoutubePlaylistLinks 
WriteLinksToFile 

exit
# END
