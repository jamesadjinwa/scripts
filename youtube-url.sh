#!/bin/bash
# youtube-url.sh
# author : @adjinwa
# purpose : extract videos' links from a youtube list

# BEGIN

clear

declare -r WGET=`which wget`
declare -r CUT=`which cut`

# Welcome message
echo "-----------------------------------------------------------------------------"
echo "-   This program will extract all the links from a Youtube list or channel  -"
echo "-   and write them in a CSV file                                            -"
echo "-----------------------------------------------------------------------------"
# Read the user's input
read -p "Enter the url of the youtube playlist or channel: " url

# Url validation
regex='(https?|ftp|file)://[-A-Za-z0-9\+&@#/%?=~_|!:,.;]*[-A-Za-z0-9\+&@#/%=~_|]'
if 	[[ $string =~ $regex ]]
then
	echo "Good! $url is a valid url."
else
       	echo "Sorry! $url is not a valid url.";
       	exit	
fi

# Check if youtube url exists
echo $url | grep "www.youtube.com" > /dev/null
case $? in
	0 ) 
		echo "Good! This is a Youtube url.";;
	1 ) 
		echo "This not a youtube url" ;;
	* ) 
		echo "An error has occured"; exit
esac
# Check if link is youtube playlist 
string2test="playlists"		# Youtube's playlist url end with the string : "playlists"
stringinurl=`echo "$url" | $CUT -d / -f 6`
if [ "$string2test" != "$stringinurl" ]	# "playlist" is at the 6th position in the url
then
	echo "This is not the url of a playlist";
	exit
else
	echo "Good! This is a playlist url"
fi
# Check if playlist exists
echo "Connecting to $url ..."
$WGET -O - $url > /dev/null
case $? in
	0 ) echo "Got it !";;
	4 ) echo "Network failure";;
	* ) echo "An error occured!"; exit
esac


# Extract urls in the youtube playlist and 
# Create a csv file and write into it the extracted urls 
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
username=`echo $url | $CUT -d / -f 5` 			# Etract the username. Will be part of the csv filename.
`$WGET -qO - $url | grep -o '<h3 .*href=\"\/playlist.*>' | sed -e 's/<a /\n<a /g' | sed -e 's/<a .*href=['"'"'"]//' -e 's/["'"'"'].*$//' -e '/^$/ d' | sed -e 's/<h3 .*class=$//g' | sed '/^\s*$/d' >$username"_playlist.csv"`

exit
# END
