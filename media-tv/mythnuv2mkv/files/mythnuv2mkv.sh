#!/bin/bash
# @(#)$Header: /home/mythtv/mythtvrep/scripts/mythnuv2mkv.sh,v 1.26 2008/07/18 12:50:11 mythtv Exp $
# Auric 2007/07/10 http://web.aanet.com.au/auric/
##########################################################################################################
#
# Convert MythRecording & MythVideo nuv or mpg files to mkv mp4 or avi.
#
######### Vars you need to set for your environment ######################################################
# Default aspect for Myth Recording mpg files. It will try to work it out but if it can't will use this.
DEFAULTMPEG2ASPECT="NA" # 4:3 or 16:9
##########################################################################################################
USAGE='mythnuv2mkv.sh [--contype=avi|mkv|mp4] [--quality=low|med|high] [--pass=one|two] [--jobid=%JOBID%] [--maxrunhours=int] [--findtitle=string] [--copydir=directory] "--chanid=chanid --starttime=starttime" | file ...
Must have either --chanid=chanid and --starttime=starttime or a plain filename. These can be mixed. e.g. -
mythnuv2mkv.sh --chanid=1232 --starttime=20071231235900 video1 video2 --chanid=1235 --starttime=20071231205900
--contype=avi|mkv|mp4 (default name of script. e.g. mythnuv2mkv.sh will default to mkv. mythnuv2avi.sh will default to avi)
	(Note Videos staying in MythRecord will always default to avi)
	avi - Video mpeg4 Audio mp3
	mkv - Video h.264 Audio aac (--contype=mkv,ogg will use ogg Vorbis Audio)
	mp4 - Video h.264 Audio aac
--quality=low|med|high (default med)
--pass=one|two (default two)
	--quality --pass and --contype can be passed as any argument and will only take effect on files after them.
	e.g. mythnuv2mkv.sh videofile1 --chanid=2033 --starttime=20070704135700 --pass=one video3 --quality=low video4
	videofile1 and chanid=2033/starttime=20070704135700 will be two pass med quality (defaults)
	video3, one pass med quality
	video4, one pass low quality
--maxrunhours=int (default process all files)
	Stop processing files after int hours. (Will complete the current file it is processing.)
--findtitle="string"
	Prints tile, chanid, starttime of programs matching string.
--copydir=directory
	mkv/mp4/avi file will be created in directory. Source nuv will be retained. i.e you are copying the source rather than replacing it.
	If the source was a CHANID/STARTIME it will be renamed to TITLE:S##E##:SUBTITLE. S##E## is the Season and Episode number. All punctuation characters are removed.
	If directory is under MythVideoDir, imdb will be searched, a MythVideo db entry created and a coverfile file created if one was not available at imdb.
--jobid=%JOBID%
        Add this when run as a User Job. Enables update status in the System Status Job Queue screen and the Job Queue Comments field in MythWeb. Also enables stop/pause/resume of job.

Logs to /var/tmp/mythnuv2mkvPID.log and to database if "log MythTV events to database" is enabled in mythtv.
Cutlists are always honored.
Sending the mythnuv2mkv.sh process a USR1 signal will cause it to stop after completing the current file.
e.g. kill -s USR1 PID
If run as a Myth Job, you can find the PID in the System Status Job Queue or Log Entries screens as [PID]

Typical usage.

Myth User Job
PATH/mythnuv2mkv.sh --jobid=%JOBID% --copydir /mythvideodirectory --chanid=%CHANID% --starttime=%STARTTIME%
This will convert nuv to mkv and copy it to /mythvideodirectory.
This is what I do. Record things in Myth Recording and anything I want to keep, use this to convert to mkv and store in Myth Video.
NOTE. System Status Job Queue screen and the Job Queue Comments field in MythWeb always report job Completed Successfully even if it actually failed.

Myth Video
Record program
mythrename.pl --link --format %T-%S --underscores --verbose (mythrename.pl is in the mythtv contrib directory
cp from your mythstore/show_names/PROGRAM to your MythVideo directory
use video manager to add imdb details 
nuv files work fine in MythVideo, but if you need to convert them to mkv/mp4/avi, or need to reduce their size
run mythnuv2mkv.sh MythVideo_file.nuv

Myth Recording
Record program
run mythnuv2mkv.sh --findtitle="title name"
get chanid and starttime
run mythnuv2mkv.sh --chanid=chanid --starttime=starttime
NOTE You cannot edit a avi/mp4/mkv file in Myth Recording. So do all your editing in the nuv file before you convert to avi.
NOTE You cannot play a mkv/mp4 file in Myth Recording.
I would in general recommend leaving everything in Myth Recording as nuv.

Version: $Revision: 1.26 $ $Date: 2008/07/18 12:50:11 $
'
REQUIREDAPPS='
Required Applications
For all contypes
mythtranscode.
perl
mplayer http://www.mplayerhq.hu/design7/news.html
mencoder http://www.mplayerhq.hu/design7/news.html
wget http://www.gnu.org/software/wget/
ImageMagick http://www.imagemagick.org/script/index.php
For avi
mp3lame http://www.mp3dev.org
For mkv and mp4 contypes
x264 http://www.videolan.org/developers/x264.html
faac http://sourceforge.net/projects/faac/
faad2 http://sourceforge.net/projects/faac/
For mkv contype
mkvtoolnix http://www.bunkus.org/videotools/mkvtoolnix/
For mkv,ogg contype
vorbis-tools http://www.vorbis.com/
For mp4 contype
MP4Box http://gpac.sourceforge.net/index.php
'
HELP=${USAGE}${REQUIREDAPPS}

##### Mapping #############################################################################################
# Maps tvguide categories to mythvideo ones. This will need to be managed individually.
# Either use the defaults below or create a mythnuv2mkv-category-mappings file in the same
# directory as this and enter data same format as below.
readonly CMAPFILE="$(dirname ${0})/mythnuv2mkv-category-mappings"
if [ -f "$CMAPFILE" ]
then 
	. "$CMAPFILE"
else
	# NOTE: Remove any spaces from XMLTV category. e.g. "Mystery and Suspense" is MysteryandSuspense
	# XMLTV Category		 ; Myth videocategory
	readonly Animated=1		 ; mythcat[1]="Animation"
	readonly Biography=2		 ; mythcat[2]="Documentary"
	readonly Historical=3		 ; mythcat[3]="Documentary"
	readonly CrimeDrama=4		 ; mythcat[4]="CrimeDrama"
	readonly MysteryandSuspense=5	 ; mythcat[5]="Mystery"
	readonly Technology=6		 ; mythcat[6]="Documentary"
	readonly ScienceFiction=7	 ; mythcat[7]="Sci-Fi"
	readonly Science_Fiction=8	 ; mythcat[8]="Sci-Fi"
	readonly art=9			 ; mythcat[9]="Musical"
	readonly History=10		 ; mythcat[10]="Documentary"
	readonly SciFi=11		 ; mythcat[11]="Sci-Fi"
	readonly ScienceNature=12	 ; mythcat[12]="Science"
fi

###########################################################################################################
PATH=~mythtv/bin:${HOME}/bin:$PATH:/usr/local/bin
AVIREQPROGS="mencoder mythtranscode mplayer perl wget convert"
AVIREQLIBS="libmp3lame.so"
MP4REQPROGS="mencoder mythtranscode mplayer perl wget convert faac MP4Box"
MP4REQLIBS="libx264.so libfaac.so"
MKVREQPROGS="mencoder mythtranscode mplayer perl wget convert faac oggenc mkvmerge"
MKVREQLIBS="libx264.so libfaac.so"

## CQ ## Quote from mencoder documentation
#The CQ depends on the bitrate, the video codec efficiency and the movie resolution. In order to raise the CQ, typically you would
#downscale the movie given that the bitrate is computed in function of the target size and the length of the movie, which are constant.
#With MPEG-4 ASP codecs such as Xvid and libavcodec, a CQ below 0.18 usually results in a pretty blocky picture, because there are
#not enough bits to code the information of each macroblock. (MPEG4, like many other codecs, groups pixels by blocks of several pixels
#to compress the image; if there are not enough bits, the edges of those blocks are visible.) It is therefore wise to take a CQ ranging
# from 0.20 to 0.22 for a 1 CD rip, and 0.26-0.28 for 2 CDs rip with standard encoding options. More advanced encoding options such as
#those listed here for libavcodec and Xvid should make it possible to get the same quality with CQ ranging from 0.18 to 0.20 for a 1 CD
#rip, and 0.24 to 0.26 for a 2 CD rip. With MPEG-4 AVC codecs such as x264, you can use a CQ ranging from 0.14 to 0.16 with standard
#encoding options, and should be able to go as low as 0.10 to 0.12 with x264's advanced encoding settings.
########################
# These map to --quality=low|med|high option.
#### AVI mpeg4/mp3 ####
readonly HIGH_MPEG4_CQ=0.22
readonly MED_MPEG4_CQ=0.21
readonly LOW_MPEG4_CQ=0.20
readonly HIGH_MPEG4_OPTS="vcodec=mpeg4:mbd=2:trell:v4mv:last_pred=2:dia=-1:vmax_b_frames=2:vb_strategy=1:cmp=3:subcmp=3:precmp=0:vqcomp=0.6"
readonly MED_MPEG4_OPTS="vcodec=mpeg4:mbd=2:trell:v4mv"
readonly LOW_MPEG4_OPTS="vcodec=mpeg4:mbd=2"
readonly HIGH_MP3_ABITRATE=256
readonly MED_MP3_ABITRATE=192
readonly LOW_MP3_ABITRATE=128
#### MP4/MKV h.263/aac,ogg ####
readonly HIGH_X264_CQ=0.15
readonly MED_X264_CQ=0.14
readonly LOW_X264_CQ=0.13
readonly HIGH_X264_OPTS="subq=6:partitions=all:8x8dct:me=umh:frameref=5:bframes=3:b_pyramid:weight_b:threads=auto"
readonly MED_X264_OPTS="subq=5:8x8dct:frameref=2:bframes=3:b_pyramid:weight_b:threads=auto"
readonly LOW_X264_OPTS="subq=4:bframes=2:b_pyramid:weight_b:threads=auto"
# Limit bframes for compability to quicktime
#readonly HIGH_X264_OPTS="subq=6:frameref=5:bframes=2:threads=auto"
#readonly MED_X264_OPTS="subq=5:frameref=2:bframes=2:threads=auto"
#readonly LOW_X264_OPTS="subq=4:bframes=2:threads=auto"
# AAC
#readonly HIGH_AAC_ABITRATE=158
#readonly MED_AAC_ABITRATE=129
#readonly LOW_AAC_ABITRATE=103
readonly HIGH_AAC_AQUAL=110
readonly MED_AAC_AQUAL=100
readonly LOW_AAC_AQUAL=90
# OGG
readonly HIGH_OGG_AQUAL=6
readonly MED_OGG_AQUAL=5
readonly LOW_OGG_AQUAL=4
# Defaults
MPEG4_OPTS=$MED_MPEG4_OPTS
MPEG4_CQ=$MED_MPEG4_CQ
MP3_ABITRATE=$MED_MP3_ABITRATE
#AAC_ABITRATE=$MED_AAC_ABITRATE
AAC_AQUAL=$MED_AAC_AQUAL
OGG_AQUAL=$MED_OGG_AQUAL
X264_OPTS=$MED_X264_OPTS
X264_CQ=$MED_X264_CQ
PASS="two"
CONTYPE="mkv" ; MKVAUD="aac"
if echo "$(basename $0)" | grep -i 'mkv' >/dev/null 2>&1
then
	CONTYPE="mkv"
elif echo "$(basename $0)" | grep -i 'mkv.*ogg' >/dev/null 2>&1
then
	CONTYPE="mkv"
	MKVAUD="ogg"
elif echo "$(basename $0)" | grep -i 'mp4' >/dev/null 2>&1
then
	CONTYPE="mp4"
elif echo "$(basename $0)" | grep -i 'avi' >/dev/null 2>&1
then
	CONTYPE="avi"
fi
###########################################################
readonly CROP=8
readonly HIGH_SCALE43=528:400	# 1.32
readonly MED_SCALE43=512:384	# 1.333
readonly LOW_SCALE43=448:336	# 1.333
readonly HIGH_SCALE169=656:368	# 1.783
readonly MED_SCALE169=624:352	# 1.773
readonly LOW_SCALE169=592:336	# 1.762
# Default
SCALE43=$MED_SCALE43
SCALE169=$MED_SCALE169
###########################################################
# ON or OFF
# debug mode
DEBUG="OFF"
DEBUGSQL="OFF"
# Print INFO messages
INFO="ON"
# Save(via a rename) or delete nuv file
SAVENUV="OFF"

[ "$DEBUGSQL" = "ON" ] && DEBUG="ON"

##### Functions ###########################################
scriptlog() {
local LEVEL="$1"
shift
local PRIORITY
local HIGHLIGHTON
local HIGHLIGHTOFF
	if [ "$LEVEL" = "BREAK" ]
	then
		echo "--------------------------------------------------------------------------------" | tee -a $LOGFILE
		return 0
	elif [ "$LEVEL" = "ERROR" ]
	then
		PRIORITY=4
		HIGHLIGHTON="${REDFG}"
		HIGHLIGHTOFF="${COLOURORIG}"
		# Global
		FINALEXIT=1
	elif [ "$LEVEL" = "SUCCESS" ]
	then
		PRIORITY=5
		HIGHLIGHTON="${GREENFG}"
		HIGHLIGHTOFF="${COLOURORIG}"
	elif [ "$LEVEL" = "START" -o "$LEVEL" = "STOP" ]
	then
		PRIORITY=5
		HIGHLIGHTON="${BOLDON}"
		HIGHLIGHTOFF="${ALLOFF}"
	elif [ "$LEVEL" = "DEBUG" ]
	then
		[ "$DEBUG" = "ON" ] || return
		PRIORITY=7
		HIGHLIGHTON=""
		HIGHLIGHTOFF=""
	else
		[ "$INFO" = "ON" ] || return
		LEVEL="INFO"
		PRIORITY=6
		HIGHLIGHTON=""
		HIGHLIGHTOFF=""
	fi
	echo "${HIGHLIGHTON}$(date +%d/%m,%H:%M) [${$}] $LEVEL $*${HIGHLIGHTOFF}" | tee -a $LOGFILE

	[ "$DBLOGGING" -eq 1 ] && insertmythlogentry "$PRIORITY" "$LEVEL" "${$}" "$*"
}

chkreqs() {
local REQPROGS="$1"
local REQLIBS="$2"
local TMP
local MENCODER
	for TMP in $REQPROGS
	do
		if ! which "$TMP" >/dev/null 2>&1
		then
			scriptlog ERROR "Can't find program $TMP."
			scriptlog ERROR "$REQUIREDAPPS"
			return 1
		fi
	done
	MENCODER=$(which mencoder)
	for TMP in $REQLIBS
	do
		if ! ldd $MENCODER | grep -i  "${TMP}.*=>.*${TMP}" >/dev/null 2>&1
		then
			scriptlog ERROR "mencoder may not support $TMP."
			scriptlog ERROR "$REQUIREDAPPS"
			return 1
		fi
	done
	return 0
}

calcbitrate() {
local ASPECT=$1
local SCALE=$2
local CQ=$3
local W
local H
local BITRATE
	W=$(echo $SCALE | cut -d ':' -f1)
	H=$(echo $SCALE | cut -d ':' -f2)
	BITRATE=$(echo "((($H^2 * $ASPECT * 25 * $CQ) / 16 ) * 16) / 1000" | bc)
	echo $BITRATE
}

getsetting() {
local VALUE="$1"
local HOST=$(hostname)
local DATA
	DATA=$(mysql --batch --skip-column-names --user=${DBUserName} --password=${DBPassword} -h ${DBHostName} ${DBName} <<-EOF
	select data from settings where value = "$VALUE" and hostname like "${HOST}%";
	EOF)
	if [ -z "$DATA" ]
	then
		DATA=$(mysql --batch --skip-column-names --user=${DBUserName} --password=${DBPassword} -h ${DBHostName} ${DBName} <<-EOF
		select data from settings where value = "$VALUE" and hostname is NULL;
	EOF)
	fi
	echo "$DATA"
}

hascutlist() {
local CHANID="$1"
local STARTTIME="$2"
	[ -n "$CHANID" ] || return 1
	local DATA=$(mysql --batch --skip-column-name --user=${DBUserName} --password=${DBPassword} -h ${DBHostName} ${DBName} <<-EOF
	select cutlist from recorded where chanid = $CHANID and starttime = "$STARTTIME";
	EOF)
	[ "$DATA" -eq 1 ] && return 0 || return 1
}

getrecordfile() {
local CHANID="$1"
local STARTTIME="$2"
	[ -n "$CHANID" ] || return 1
	mysql --batch --skip-column-names --user=${DBUserName} --password=${DBPassword} -h ${DBHostName} ${DBName} <<-EOF
	select basename from recorded where chanid = $CHANID and starttime = "$STARTTIME";
	EOF
}

gettitle() {
local CHANID="$1"
local STARTTIME="$2"
	[ -n "$CHANID" ] || return 1
	mysql --batch --skip-column-names --user=${DBUserName} --password=${DBPassword} -h ${DBHostName} ${DBName} <<-EOF
	select title, subtitle from recorded where chanid = $CHANID and starttime = "$STARTTIME";
	EOF
}

findchanidstarttime() {
local SEARCHTITLE="$1"
	mysql --user=${DBUserName} --password=${DBPassword} -h ${DBHostName} ${DBName} <<-EOF
	select title, subtitle, chanid, date_format(starttime, '%Y%m%d%H%i%s') from recorded where title like "%${SEARCHTITLE}%";
	EOF
}

updatemetadata() {
local MYTHCOMP="$1"
local OLD="$2"
local NEW="$3"
local CHANID_CFOLD="$4"
local STARTTIME_CFNEW="$5"
local NFSIZE
local NEW
	if [ "$MYTHCOMP" = "REC" ]
	then
		NFSIZE=$(stat -c %s "$NEW")
		NEW=$(basename "$NEW")
		mysql --user=${DBUserName} --password=${DBPassword} -h ${DBHostName} ${DBName} <<-EOF
		update recorded set
		basename = "$NEW",
		filesize = $NFSIZE,
		bookmark = 0,
		editing = 0,
		cutlist = 0,
		commflagged = 0
		where chanid = $CHANID_CFOLD and starttime = "$STARTTIME_CFNEW";
		delete from recordedmarkup where chanid = $CHANID_CFOLD and starttime = "$STARTTIME_CFNEW";
		delete from recordedseek where chanid = $CHANID_CFOLD and starttime = "$STARTTIME_CFNEW";
	EOF
	elif [ "$MYTHCOMP" = "VIDEO" ]
	then
		mysql --user=${DBUserName} --password=${DBPassword} -h ${DBHostName} ${DBName} <<-EOF
		update videometadata set filename = "$NEW" where filename = "$OLD";
		update videometadata set coverfile = "$STARTTIME_CFNEW" where coverfile = "$CHANID_CFOLD";
		delete from filemarkup where filename = "$OLD";
	EOF
	fi
}

createvideocover() {
local FILENAME="$1"
local ASPECT="$2"
local THDIR="${FIFODIR}/THDIR"
local THUMB_NAME=$(basename "$FILENAME" | sed -e 's/\.[am][vkp][iv4]$/\.png/')
local THUMB_PATH="${CFDIR}/${THUMB_NAME}"
local CURWD
local TH
	{
	CURWD=$(pwd)
	mkdir $THDIR && cd $THDIR || return 1
	nice -19 mplayer -really-quiet -nojoystick -nolirc -nomouseinput -ss 00:02:00 -aspect $ASPECT -ao null -frames 50 -vo png:z=5 "$FILENAME"
	TH=$(ls -1rt | tail -1)
	if [ $ASPECT = "16:9" ]
	then
		convert "$TH" -resize 720x404! THWS.png
	else
		cp "$TH" THWS.png
	fi
	mv THWS.png "$THUMB_PATH"
	cd $CURWD
	rm -rf $THDIR
	} >/dev/null 2>&1
	echo "$THUMB_PATH"
}

lookupinetref() {
local VIDNAME="$1"
local CHANID="$2"
local STARTTIME="$3"
local IMDBCMD
local IMDBRES
local IMDBSTR=""
local INETREF=00000000
local SERIES
local EPISODE
local YEAR
local TMP
	{
        IMDBCMD=$(getsetting MovieListCommandLine)
	# This is dependent on imdb.pl and will not work with any MovieListCommandLine due to use of s=ep option.
	set - $IMDBCMD
	IMDBCMD="$1 $2"
        IMDBRES=$($IMDBCMD "$VIDNAME")
        if [ -n "$IMDBRES" -a $(echo "$IMDBRES" | wc -l) -eq 1 ]
        then
		IMDBSTR="$IMDBRES"
	elif [ -n "$CHANID" ]
	then
		YEAR=$(getyear $CHANID $STARTTIME)
		if [ "$YEAR" -gt 1800 ]
		then
			for C in 0 1 -1
			do
				TMP=$(echo "$IMDBRES" | grep $(( $YEAR + $C )))
				[ -n "$TMP" -a $(echo "$TMP" | wc -l) -eq 1 ] && IMDBSTR="$TMP" && break
			done
		fi
        fi
	if [ -n "$IMDBSTR" ]
	then
                INETREF=$(echo "$IMDBSTR" | awk -F'[^0-9]' '{print $1}')
                echo $INETREF | grep '^[0-9][0-9][0-9][0-9][0-9][0-9][0-9]*$' >/dev/null 2>&1 || INETREF=00000000
	fi
        if [ "$INETREF" -eq 00000000 ]
        then
		# Try looking for episode
                OLDIFS="$IFS"; IFS=":"; set - $VIDNAME; IFS="$OLDIFS"
		SERIES="$1" ; EPISODE="$2"
		if [ -n "$SERIES" -a -n "$EPISODE" ]
		then
			# option s=ep is for episode lookup
			IMDBSTR=$($IMDBCMD s=ep "$EPISODE")
			if which agrep >/dev/null 2>&1
			then
				IMDBSTR=$(echo "$IMDBSTR" | agrep -i -s -2 "$SERIES" | sort -n | head -1 | cut -d':' -f2-)
			else
				IMDBSTR=$(echo "$IMDBSTR" | grep -i "$SERIES")
			fi
			if [ $(echo "$IMDBSTR" | wc -l) -eq 1 ]
			then
				INETREF=$(echo "$IMDBSTR" | awk -F'[^0-9]' '{print $1}')
				echo $INETREF | grep '^[0-9][0-9][0-9][0-9][0-9][0-9][0-9]*$' >/dev/null 2>&1 || INETREF=00000000
			fi
		fi
        fi
	} >/dev/null 2>&1
        echo $INETREF
}

hasvideometadata() {
local FILENAME="$1"
local DATA
	DATA=$(mysql --batch --skip-column-names --user=${DBUserName} --password=${DBPassword} -h ${DBHostName} ${DBName} <<-EOF
	select intid from videometadata where filename = "$FILENAME";
	EOF)
	echo $DATA | grep '^[0-9][0-9][0-9]*$' >/dev/null 2>&1 && return 0 || return 1
}

createvideometadata() {
local FILENAME="$1"
local ASPECT="$2"
local CHANID="$3"
local STARTTIME="$4"
local SEARCHTITLE=$(basename $FILENAME | sed -e 's/\.[am][vkp][iv4]$//' -e 's/:S[0-9][0-9]E[0-9][0-9]:/:/' -e 's/_/ /g')
local TITLE=$(basename $FILENAME | sed -e 's/\.[am][vkp][iv4]$//' -e 's/_/ /g')
local DIRECTOR="Unknown"
#local PLOT="None"
local PLOT="$(getplot $CHANID $STARTTIME)"
local MOVIERATING="NR"
local INETREF=00000000
#local YEAR=1895
local YEAR="$(getyear $CHANID $STARTTIME)"
local USERRATING=0
local RUNTIME=0
local COVERFILE="No Cover"
local GENRES=""
local COUNTRIES=""
local CATEGORY=""
local TI
local ST
local SEARCHSTR
local IMDBCMD
local IMDBSTR
local GTYPE
local TH
local SE
local S
local E
local WHERE
local INSERT
local TMP
local IDS
local INTID
local COUNT
	# Title name generation is a mess. Should do something better
	if hasvideometadata $FILENAME
	then
		scriptlog INFO "$FILENAME already has a videometdata entry"
		return 0
	else
		# Since I strip special characters in FILENAME, use chanid/starttime if I have it.
		if [ -n "$CHANID" ]
		then
			TI=$(mysql --batch --skip-column-names --user=${DBUserName} --password=${DBPassword} -h ${DBHostName} ${DBName} <<-EOF
			select title from recorded where chanid = $CHANID and starttime = "$STARTTIME";
			EOF)
			ST=$(mysql --batch --skip-column-names --user=${DBUserName} --password=${DBPassword} -h ${DBHostName} ${DBName} <<-EOF
			select subtitle from recorded where chanid = $CHANID and starttime = "$STARTTIME";
			EOF)
			SE=$(getseriesepisode "$CHANID" "$STARTTIME")
			if [ -n "$TI" -a -n "$SE" -a -n "$ST" ]
			then
				TITLE="\\\"${TI}\\\" ${SE} ${ST}"
				TI=$(echo $TI | tr ':' ' ')
				ST=$(echo $ST | tr ':' ' ')
				SEARCHTITLE="${TI}:${ST}"
			elif [ -n "$TI" -a -n "$ST" ]
			then
				TITLE="\\\"${TI}\\\" ${ST}"
				TI=$(echo $TI | tr ':' ' ')
				ST=$(echo $ST | tr ':' ' ')
				SEARCHTITLE="${TI}:${ST}"
			elif [ -n "$TI" ]
			then
				TITLE="${TI}"
				TI=$(echo $TI | tr ':' ' ')
				SEARCHTITLE="${TI}"
			fi
		fi
		scriptlog DEBUG "Looking up $SEARCHTITLE"
		INETREF=$(lookupinetref "$SEARCHTITLE" "$CHANID" "$STARTTIME")
		if [ $INETREF -gt 0 ]
		then
			IMDBCMD=$(getsetting MovieDataCommandLine)
			IMDBSTR=$($IMDBCMD $INETREF | sed -e 's/"/\\"/g')
			TMP=$(echo "$IMDBSTR" | grep '^Title' | cut -d':' -f2- | sed -e 's/^ *//')
			if [ -n "$TMP" ]
			then
				# If no SE try imdb page
				[ -n "$SE" ] || SE=$(getseriesepisode "$CHANID" "$STARTTIME" "$INETREF")
				# Try and put series and episode number back in. Based on imdb placing quotes around series name. A bit dodgy
				if [ -n "$SE" ]
				then
					TMP=$(echo "$TMP" | awk -v s=${SE} '{
					r=match($0,/"(.*)" (.*)/,m)
					if(r>0) { print("\\\""m[1]"\\\" "s" "m[2]) }
					else { print($0) }
					}' | sed -e 's/\\\\"/\\"/g')
				fi
				TITLE="$TMP"
			fi
			TMP=$(echo "$IMDBSTR" | grep '^Year' | cut -d':' -f2- | sed -e 's/^ *//')
			[ -n "$TMP" ] && YEAR="$TMP"
			TMP=$(echo "$IMDBSTR" | grep '^Director' | cut -d':' -f2- | sed -e 's/^ *//')
			[ -n "$TMP" ] && DIRECTOR="$TMP"
			TMP=$(echo "$IMDBSTR" | grep '^Plot' | cut -d':' -f2- | sed -e 's/^ *//')
			[ -n "$TMP" ] && PLOT="$TMP"
			TMP=$(echo "$IMDBSTR" | grep '^UserRating' | grep -v '[<>\"]' | cut -d':' -f2- | sed -e 's/^ *//')
			[ -n "$TMP" ] && USERRATING="$TMP"
			TMP=$(echo "$IMDBSTR" | grep '^MovieRating' | cut -d':' -f2- | sed -e 's/^ *//')
			[ -n "$TMP" ] && MOVIERATING="$TMP"
			TMP=$(echo "$IMDBSTR" | grep '^Runtime' | cut -d':' -f2- | sed -e 's/^ *//')
			[ -n "$TMP" ] && RUNTIME="$TMP"
			IMDBCMD=$(getsetting MoviePosterCommandLine)
			IMDBCOVER=$($IMDBCMD $INETREF)
			if [ -n "$IMDBCOVER" ]
			then
				GTYPE=$(echo $IMDBCOVER | sed -e 's/.*\(\....\)/\1/')
				wget -o /dev/null -O ${CFDIR}/${INETREF}${GTYPE} $IMDBCOVER 
				[ -f ${CFDIR}/${INETREF}${GTYPE} ] && COVERFILE="${CFDIR}/${INETREF}${GTYPE}"
			fi
			TMP=$(echo "$IMDBSTR" | grep '^Genres' | cut -d':' -f2- | sed -e 's/^ *//')
			[ -n "$TMP" ] && GENRES="$TMP"
			TMP=$(echo "$IMDBSTR" | grep '^Countries' | cut -d':' -f2- | sed -e 's/^ *//')
			[ -n "$TMP" ] && COUNTRIES="$TMP"
		fi
		if ! [ -f "$COVERFILE" ]
		then
			scriptlog INFO "Creating cover file."
			TH=$(createvideocover $FILENAME $ASPECT)
			[ -f ${TH} ] && COVERFILE="${TH}"
		fi
		scriptlog INFO "Creating videometadata entry. Inetref:$INETREF. Title:$TITLE"
		if [ "$DEBUGSQL" = "ON" ]
		then
			cat <<-EOF
			insert into videometadata set
			title = "$TITLE",
			director = "$DIRECTOR",
			plot = "$PLOT",
			rating = "$MOVIERATING",
			inetref = "$INETREF",
			year = $YEAR,
			userrating = $USERRATING,
			length = $RUNTIME,
			showlevel = 1,
			filename = "$FILENAME",
			coverfile = "$COVERFILE",
			childid = -1,
			browse = 1,
			playcommand = NULL,
			category = 0;
			EOF
		fi
		mysql --user=${DBUserName} --password=${DBPassword} -h ${DBHostName} ${DBName} <<-EOF
		insert into videometadata set
		title = "$TITLE",
		director = "$DIRECTOR",
		plot = "$PLOT",
		rating = "$MOVIERATING",
		inetref = "$INETREF",
		year = $YEAR,
		userrating = $USERRATING,
		length = $RUNTIME,
		showlevel = 1,
		filename = "$FILENAME",
		coverfile = "$COVERFILE",
		childid = -1,
		browse = 1,
		playcommand = NULL,
		category = 0;
		EOF
		CATEGORY=$(getcategory "$CHANID" "$STARTTIME")
		if [ -n "$GENRES" -o -n "$COUNTRIES" -o -n "$CATEGORY" ]
		then
			INTID=$(mysql --batch --skip-column-names --user=${DBUserName} --password=${DBPassword} -h ${DBHostName} ${DBName} <<-EOF
			select intid from videometadata where filename = "$FILENAME";
			EOF)
		fi
		if [ -n "$INTID" ]
		then
			# This will not create new genres, countries or categories.
			if [ -n "$GENRES" ]
			then
				scriptlog DEBUG "Will check for genres $GENRES"
				OLDIFS="$IFS"; IFS=','; set - $GENRES; IFS="$OLDIFS"
				COUNT="$#"
				WHERE=""
				for TMP in "$@"
				do
					TMP=$(echo $TMP | tr [A-Z] [a-z])
					[ -n "$WHERE" ] && WHERE="$WHERE or lcase(genre) = \"$TMP\"" || WHERE="where lcase(genre) = \"$TMP\""
				done
				[ "$DEBUGSQL" = "ON" ] && echo "select intid from videogenre $WHERE"
				IDS=$(mysql --batch --skip-column-names --user=${DBUserName} --password=${DBPassword} -h ${DBHostName} ${DBName} <<-EOF
				select intid from videogenre $WHERE; 
				EOF)
				for TMP in $IDS
				do
					INSERT="$INSERT insert into videometadatagenre set idvideo = $INTID, idgenre = $TMP;"
				done
				[ "$COUNT" -gt $(echo "$IDS" | wc -l) ] && scriptlog INFO "Not all genres $GENRES found"
			fi

			if [ -n "$COUNTRIES" ]
			then
				scriptlog DEBUG "Will check for countries $COUNTRIES"
				OLDIFS="$IFS"; IFS=','; set - $COUNTRIES; IFS="$OLDIFS"
				COUNT="$#"
				WHERE=""
				for TMP in "$@"
				do
					TMP=$(echo $TMP | tr [A-Z] [a-z])
					[ -n "$WHERE" ] && WHERE="$WHERE or lcase(country) = \"$TMP\"" || WHERE="where lcase(country) = \"$TMP\""
				done
				[ "$DEBUGSQL" = "ON" ] && echo "select intid from videocountry $WHERE"
				IDS=$(mysql --batch --skip-column-names --user=${DBUserName} --password=${DBPassword} -h ${DBHostName} ${DBName} <<-EOF
				select intid from videocountry $WHERE; 
				EOF)
				for TMP in $IDS
				do
					INSERT="$INSERT insert into videometadatacountry set idvideo = $INTID, idcountry = $TMP;"
				done
				[ "$COUNT" -gt $(echo "$IDS" | wc -l) ] && scriptlog INFO "Not all countries $COUNTRIES found"
			fi

			if [ -n "$CATEGORY" ]
			then
				CATEGORY=$(echo "$CATEGORY" | tr -d ' ')
				OLDIFS="$IFS"; IFS='/'; set - $CATEGORY; IFS="$OLDIFS"
				for TMP in "$@"
				do
					# Use mappings
					[ -n "${mythcat[$TMP]}" ] && TMP=${mythcat[$TMP]}
					[ "$DEBUGSQL" = "ON" ] && echo "select intid from videocategory where lcase(category) = lcase("$TMP")"
					IDS=$(mysql --batch --skip-column-names --user=${DBUserName} --password=${DBPassword} mythconverg <<-EOF
					select intid from videocategory where lcase(category) = lcase("$TMP"); 
					EOF)
					if [ -n "$IDS" ]
					then
						INSERT="$INSERT update videometadata set category = $IDS where intid = $INTID;"
						scriptlog INFO "Added to category $TMP"
						# only 1 category
						break
					else
						scriptlog INFO "Category $TMP does not exist"
					fi
				done
			fi

			if [ -n "$INSERT" ]
			then
				[ "$DEBUGSQL" = "ON" ] && echo "$INSERT"
				mysql --batch --skip-column-names --user=${DBUserName} --password=${DBPassword} mythconverg <<-EOF
				$INSERT
				EOF
			fi
		fi
	fi
	return 0
}

insertmythlogentry() {
local PRIORITY="$1"
local LEVEL="$2"
local PID="$3"
local DETAILS="$(echo $4 | tr -d '[:cntrl:]' | tr -d '[\\\"]')"
local DATETIME=$(date '+%Y%m%d%H%M%S')
local HOST=$(hostname)
	mysql --user=${DBUserName} --password=${DBPassword} -h ${DBHostName} ${DBName} <<-EOF
	insert into mythlog set
	module = "mythnuv2mkv.sh",
	priority = $PRIORITY,
	acknowledged = 0,
	logdate = $DATETIME,
	host = "$HOST",
	message = "mythnuv2mkv.sh [$PID] $LEVEL",
	details = "$DETAILS";
	EOF
}

getjobqueuecmds() {
local JOBID="$1"
local DATA
local JQCMDSTR[0]="RUN"
local JQCMDSTR[1]="PAUSE"
local JQCMDSTR[2]="RESUME"
local JQCMDSTR[4]="STOP"
local JQCMDSTR[8]="RESTART"
	DATA=$(mysql --batch --skip-column-names --user=${DBUserName} --password=${DBPassword} -h ${DBHostName} ${DBName} <<-EOF
	select cmds from jobqueue where id = $JOBID;
	EOF)
	echo ${JQCMDSTR[$DATA]}
}

setjobqueuecmds() {
local JOBID="$1"
local CMDSSTR="$2"
local CMDS
	if echo "$CMDSSTR" | egrep '^[0-9]+$' >/dev/null 2>&1
	then
		CMDS=$CMDSSTR
	elif [ "$CMDSSTR" = "RUN" ]
	then
		CMDS=0
	fi
	if [ -n "$CMDS" ]
	then
		mysql --user=${DBUserName} --password=${DBPassword} -h ${DBHostName} ${DBName} <<-EOF
		update jobqueue set cmds = $CMDS where id = $JOBID;
		EOF
	else
		scriptlog ERROR "Invalid Job Queue Command."
	fi
}

getjobqueuestatus() {
local JOBID="$1"
local DATA
local JQSTATUSSTR[0]="UNKNOWN"
local JQSTATUSSTR[1]="QUEUED"
local JQSTATUSSTR[2]="PENDING"
local JQSTATUSSTR[3]="STARTING"
local JQSTATUSSTR[4]="RUNNING"
local JQSTATUSSTR[5]="STOPPING"
local JQSTATUSSTR[6]="PAUSED"
local JQSTATUSSTR[7]="RETRY"
local JQSTATUSSTR[8]="ERRORING"
local JQSTATUSSTR[9]="ABORTING"
local JQSTATUSSTR[256]="DONE"
local JQSTATUSSTR[272]="FINISHED"
local JQSTATUSSTR[288]="ABORTED"
local JQSTATUSSTR[304]="ERRORED"
local JQSTATUSSTR[320]="CANCELLED"
	DATA=$(mysql --batch --skip-column-names --user=${DBUserName} --password=${DBPassword} -h ${DBHostName} ${DBName} <<-EOF
	select status from jobqueue where id = $JOBID;
	EOF)
	echo ${JQSTATUSSTR[$DATA]}
}

setjobqueuestatus() {
local JOBID="$1"
local STATUSSTR="$2"
local STATUS
	if echo "$STATUSSTR" | egrep '^[0-9]+$' >/dev/null 2>&1
	then
		STATUS=$STATUSSTR
	elif [ "$STATUSSTR" = "RUNNING" ]
	then
		STATUS=4
	elif [ "$STATUSSTR" = "PAUSED" ]
	then
		STATUS=6
	elif [ "$STATUSSTR" = "ABORTING" ]
	then
		STATUS=9
	elif [ "$STATUSSTR" = "FINISHED" ]
	then
		STATUS=272
	elif [ "$STATUSSTR" = "ERRORED" ]
	then
		STATUS=304
	fi
	if [ -n "$STATUS" ]
	then
		mysql --user=${DBUserName} --password=${DBPassword} -h ${DBHostName} ${DBName} <<-EOF
		update jobqueue set status = $STATUS where id = $JOBID;
		EOF
	else
		scriptlog ERROR "Invalid Job Queue Status."
	fi
}

getjobqueuecomment() {
local JOBID="$1"
local COMMENT="$2"
	mysql --batch --skip-column-names --user=${DBUserName} --password=${DBPassword} -h ${DBHostName} ${DBName} <<-EOF
	select comment from jobqueue where id = $JOBID;
	EOF
}

setjobqueuecomment() {
local JOBID="$1"
local COMMENT="$2"
	mysql --user=${DBUserName} --password=${DBPassword} -h ${DBHostName} ${DBName} <<-EOF
	update jobqueue set comment = "$COMMENT" where id = $JOBID;
	EOF
}

# My channelprofiles table for setting aspect at channel level.
# See http://web.aanet.com.au/auric/?q=node/1
# You probably don't have it.
getchannelaspect() {
local CHANID=$1
local DATA
	DATA=$(mysql --batch --skip-column-names --user=${DBUserName} --password=${DBPassword} ${DBName} <<-EOF
	select aspectratio from channelprofiles
		where channum = (select channum from channel where chanid = $CHANID)
		and sourceid = (select sourceid from channel where chanid = $CHANID);
	EOF)
	case $DATA in
		16:9|4:3) true ;;
		'') DATA=$DEFAULTMPEG2ASPECT ;;
		*) DATA=NA ;;
	esac
	echo $DATA
}

# aspect ratio of the V4L or MPEG capture card associated with CHANID
# No good for any other type of card. e.g. DVB.
querycardaspect() {
local CHANID=$1
local DATA
	DATA=$(mysql --batch --skip-column-names --user=${DBUserName} --password=${DBPassword} ${DBName} <<-EOF
	select value from codecparams where name = 'mpeg2aspectratio'
	and profile = (select id from recordingprofiles where name = 'default'
		and profilegroup = (select id from profilegroups
			where cardtype = (select cardtype from capturecard
				where cardid = (select cardid from cardinput
					where sourceid = (select sourceid from channel
						where chanid = $CHANID)
					)
				)
			)
		);
	EOF)
	[ "$DATA" != "4:3" -a "$DATA" != "16:9" ] && DATA="NA"
	echo $DATA
}

getaviinfo() {
local FILE="$1"
shift
local PROPS="$@"
local MPOP
local TMP
local p
local RES
local ASPECTFOUNDIN
readonly width=1		; infokey[1]="ID_VIDEO_WIDTH"
readonly height=2		; infokey[2]="ID_VIDEO_HEIGHT"
readonly fps=3			; infokey[3]="ID_VIDEO_FPS"
readonly audio_sample_rate=4	; infokey[4]="ID_AUDIO_RATE"
readonly audio_channels=5	; infokey[5]="ID_AUDIO_NCH"
readonly aspect=6		; infokey[6]="ID_VIDEO_ASPECT"
	MPOP=$(mplayer -really-quiet -nojoystick -nolirc -nomouseinput -vo null -ao null -frames 0 -identify "$FILE" 2>/dev/null)
	for p in $PROPS
	do
		[ -n "${infokey[$p]}" ] && p=${infokey[$p]}
		case $p in
			"finfo")
				TMP="NA"
			;;
			"ID_VIDEO_ASPECT")
				TMP="$(echo "$MPOP" | awk -F'=' '/ID_VIDEO_ASPECT/ {if($2>1.1 && $2<1.5)print "4:3";if($2>1.6 && $2<2)print "16:9"}')"
				[ "$TMP" != "4:3" -a "$TMP" != "16:9" ] && TMP="NA"
				ASPECTFOUNDIN="File"
				if [ "$TMP" = "NA" ] && echo "$FILE" | grep '\.mpg$' >/dev/null 2>&1 && [ -n "$CHANID" ]
				then
					TMP=$(getchannelaspect $CHANID)
					ASPECTFOUNDIN="Channel"
				fi
				if [ "$TMP" = "NA" ] && echo "$FILE" | grep '\.mpg$' >/dev/null 2>&1 && [ -n "$CHANID" ]
				then
					TMP=$(querycardaspect $CHANID)
					ASPECTFOUNDIN="Card"
				fi
				if [ "$TMP" = "NA" ] && echo "$FILE" | grep '\.mpg$' >/dev/null 2>&1
				then
					TMP=$DEFAULTMPEG2ASPECT
					ASPECTFOUNDIN="Default"
				fi
				TMP="$TMP,$ASPECTFOUNDIN"
			;;
			*)
				TMP="$(echo "$MPOP" | grep $p | tail -1 | cut -d'=' -f2)"
			;;
		esac
		[ -z "$RES" ] && RES="$TMP" || RES="${RES}:${TMP}"
	done
	echo "$RES"
}

getnuvinfo() {
export NUVINFOFILE="$1"
shift
export NUVINFOPROPS="$@"
	PROPS=$(sed -n '/^#STARTNUVINFO$/,/#ENDNUVINFO/p' $CMD | perl)
	echo "$PROPS"
}

getvidinfo() {
local FILE="$1"
shift
local PROPS="$@"
local RES
	if echo "$FILE" | grep '\.nuv' >/dev/null 2>&1
	then	
		RES=$(getnuvinfo "$FILE" $PROPS)
	else
		RES=$(getaviinfo "$FILE" $PROPS)
	fi
	echo "$RES"
}

getaspect() {
local FILE="$1"
local ASPECT="NA"
	ASPECT=$(getvidinfo "$FILE" aspect)
	echo "$ASPECT" | grep ',' >/dev/null 2>&1 || ASPECT="$ASPECT,File"
	echo "$ASPECT"
}

stoptime() {
local STARTSECS=$1
local MAXRUNHOURS=$2
local CURSECS
local ENDSECS
	[ "$MAXRUNHOURS" = "NA" ] && return 1
	CURSECS=$(date +%s)
	ENDSECS=$(( $STARTSECS + ( $MAXRUNHOURS * 60 * 60 ) ))
	[ "$ENDSECS" -gt "$CURSECS" ] && return 1 || return 0
}

checkoutput() {
local INPUT=$1
local OUTPUT=$2
local MENCODERRES=$3
local AVIDET
local OUTSIZE
local INSIZE
local RAT
local SCANOUTFILE
local LCOUNT
local ECOUNT
local INFRAMES
local OUTFRAMES
local DIFF
	AVIDET=$(getvidinfo "$OUTPUT" ID_DEMUXER ID_VIDEO_FORMAT)
	if [ "$AVIDET" != "avi:FMP4" -a "$AVIDET" != "avi:h264" -a "$AVIDET" != "mov:avc1" -a "$AVIDET" != "mkv:avc1" ]
	then
		scriptlog ERROR "$OUTPUT does not look like correct avi/mp4/mkv file."
		return 1
	fi

	OUTSIZE=$(stat -c %s "$OUTPUT" 2>/dev/null || echo 0)
	if [ "$OUTSIZE" -eq 0 ]
	then
		scriptlog ERROR "$OUTPUT zero length."
		return 1
	fi

	INSIZE=$(stat -c %s "$INPUT" 2>/dev/null || echo 0)
	RAT=$(( $INSIZE / $OUTSIZE ))
	if ! hascutlist $CHANID $STARTTIME && [ "$RAT" -gt 8 ]
	then
		scriptlog ERROR "ratio between $INPUT and $OUTPUT sizes greater than 8."
		return 1
	fi

	SCANOUTFILE="${FIFODIR}/mplayerscan-out"
	nice mplayer -benchmark -nojoystick -nolirc -nomouseinput -vo null -ao null -speed 10 "$OUTPUT" 2>&1 | tr '\r' '\n' >$SCANOUTFILE 2>&1
	LCOUNT=$(wc -l $SCANOUTFILE 2>/dev/null | awk '{T=$1} END {if(T>0){print T}else{print 0}}')
	if [ "$LCOUNT" -lt 1000 ]
	then
		scriptlog ERROR "mplayer line count ($LCOUNT) to low on $OUTPUT."
		return 1
	fi
	ECOUNT=$(egrep -ic 'sync|error|skip|damaged|overflow' $SCANOUTFILE)
	if [ "$ECOUNT" -gt 5 ]
	then
		scriptlog ERROR "mplayer error count ($ECOUNT) to great on $OUTPUT."
		return 1
	fi

	if [ -f "$MENCODERRES" ]
	then
		OUTFRAMES=$(tail -40 $SCANOUTFILE | awk '/A-V:/ {if(match($5,"/"))F=$5;if(match($6,"/"))F=$6;if(match($7,"/"))F=$7;if(match($8,"/"))F=$8;if(match($9,"/"))F=$9} END {print substr(F,index(F,"/")+1)}')
		INFRAMES=$(tail -40 $MENCODERRES | awk '/Video stream:/ {F=$12} END {print F}')
		scriptlog INFO "Frames $INFRAMES $INPUT."
		scriptlog INFO "Frames $OUTFRAMES $OUTPUT."
		if echo ${INFRAMES} : ${OUTFRAMES} | grep '[0-9] : [0-9]' >/dev/null 2>&1
		then
			DIFF=$([ $INFRAMES -gt $OUTFRAMES ] && echo $(( $INFRAMES - $OUTFRAMES )) || echo $(( $OUTFRAMES - $INFRAMES )))
		else
			DIFF=100000
		fi
		if [ "$DIFF" -gt 10 ]
		then
			scriptlog ERROR "Frame count difference of $DIFF to big on $OUTPUT."
			return 1
		fi
	fi

	return 0
}

getcategory() {
local CHANID="$1"
local STARTTIME="$2"
local DATA
	[ -n "$CHANID" ] || return 1
	DATA=$(mysql --batch --skip-column-names --user=${DBUserName} --password=${DBPassword} -h ${DBHostName} ${DBName} <<-EOF
	select category from recorded where chanid = $CHANID and starttime = "$STARTTIME";
	EOF)
	echo $DATA | tr -d '[:cntrl:]' | tr -d '[:punct:]'
}

getplot() {
local CHANID="$1"
local STARTTIME="$2"
local DATA
	[ -n "$CHANID" ] || return 1
	DATA=$(mysql --batch --skip-column-names --user=${DBUserName} --password=${DBPassword} -h ${DBHostName} ${DBName} <<-EOF
	select description from recorded where chanid = $CHANID and starttime = "$STARTTIME";
	EOF)
	echo $DATA | tr -d '[:cntrl:]' | tr -d '[:punct:]'
}

getyear() {
local CHANID="$1"
local STARTTIME="$2"
local DATA
	[ -n "$CHANID" ] || return 1
	# STARTTIME is not always the same in both tables for matching programs. ???
	DATA=$(mysql --batch --skip-column-names --user=${DBUserName} --password=${DBPassword} -h ${DBHostName} ${DBName} <<-EOF
	select airdate from recorded a,recordedprogram b
	where a.chanid = $CHANID and a.starttime = "$STARTTIME" and a.chanid = b.chanid
	and a.title = b.title and a.subtitle = b.subtitle;
	EOF)
	[ -n "$DATA" -a $DATA -gt 1800 ] && echo $DATA || echo $(date +%Y)
}

getseriesepisode() {
local CHANID="$1"
local STARTTIME="$2"
local INETREF="$3"
local DATA
local SE
	[ -n "$CHANID" ] || return 1
	{
	# STARTTIME is not always the same in both tables for matching programs. ???
	DATA=$(mysql --batch --skip-column-names --user=${DBUserName} --password=${DBPassword} -h ${DBHostName} ${DBName} <<-EOF
	select syndicatedepisodenumber from recorded a,recordedprogram b
	where a.chanid = $CHANID and a.starttime = "$STARTTIME" and a.chanid = b.chanid
	and a.title = b.title and a.subtitle = b.subtitle;
	EOF)
	DATA=$(echo "$DATA" | awk -F '[SE]' '/S/ {printf("S%02dE%02d\n",$3,$2)}')
	if echo "$DATA" | grep '^S[0-9][0-9]E[0-9][0-9]$' >/dev/null 2>&1
	then
		SE="$DATA"
	elif [ -n "$INETREF" ]
	then
		# Lets try passing imdb page
		wget -o /dev/null -O "${FIFODIR}/${INETREF}.html" "http://www.imdb.com/title/tt${INETREF}/"
		SE=$(awk '/Season.*Episode/ {
		a=match($0,/Season ([0-9]+)/,s);b=match($0,/Episode ([0-9]+)/,e);if(a>0 && b>0){printf("S%02dE%02d\n",s[1],e[1]);exit}
		}' "${FIFODIR}/${INETREF}.html")
	fi
	} >/dev/null 2>&1
	echo "$SE" | grep '^S[0-9][0-9]E[0-9][0-9]$'
}

gettitlestr() {
local CHANID="$1"
local STARTTIME="$2"
local DATA
local T
local S
local SE
	[ -n "$CHANID" ] || return 1
	DATA=$(mysql --batch --skip-column-names --user=${DBUserName} --password=${DBPassword} -h ${DBHostName} ${DBName} <<-EOF
	select title from recorded where chanid = $CHANID and starttime = "$STARTTIME";
	EOF)
	T=$(echo $DATA | tr -d '[:cntrl:]' | tr -d '[:punct:]' | tr '[:space:]' '_')

	DATA=$(mysql --batch --skip-column-names --user=${DBUserName} --password=${DBPassword} -h ${DBHostName} ${DBName} <<-EOF
	select subtitle from recorded where chanid = $CHANID and starttime = "$STARTTIME";
	EOF)
	S=$(echo $DATA | tr -d '[:cntrl:]' | tr -d '[:punct:]' | tr '[:space:]' '_')

	SE=$(getseriesepisode $CHANID $STARTTIME)
	if [ -n "$T" -a -n "$SE" -a -n "$S" ]
	then
		echo "${T}:${SE}:${S}"
	elif [ -n "$T" -a -n "$S" ]
	then
		echo "${T}:${S}"
	else
		echo "${T}"
	fi
}

encloseincontainer() {
local OUTBASE="$1"
local NUVFPS="$2"
local AUDEXT="$3"
local CONTYPE="$4"
local ASPECT="$5"
local TITLE="$6"
	if [ -f "${OUTBASE}_video.h264" -o "${OUTBASE}_audio.${AUDEXT}" ]
	then
		if [ "$CONTYPE" = "mkv" ]
		then
			mkvmerge --default-duration 0:${NUVFPS}fps --aspect-ratio 0:${ASPECT} --title "$TITLE" \
			"${OUTBASE}_video.h264" "${OUTBASE}_audio.${AUDEXT}" -o "${OUTBASE}.mkv"
			RET=$? ; [ $RET -eq 1 ] && RET=0 # mkvmerge return code of 1 is only a warning
		elif [ "$CONTYPE" = "mp4" ]
		then
			MP4Box -add "${OUTBASE}_audio.${AUDEXT}" -add "${OUTBASE}_video.h264:par=1:$ASPECT" -fps $FPS "${OUTBASE}.mp4"
			RET=$?
		fi
		if [ $RET -eq 0 ]
		then
			[ "$DEBUG" != "ON" ] && rm "${OUTBASE}_video.h264" "${OUTBASE}_audio.${AUDEXT}"
		else
			[ "$DEBUG" != "ON" ] && rm "${OUTBASE}_video.h264" "${OUTBASE}_audio.${AUDEXT}" "${OUTBASE}.mkv" >/dev/null 2>&1
			return 1
		fi
	else
		scriptlog ERROR "${OUTBASE}_video.h264 or ${OUTBASE}_audio.${AUDEXT} does not exist."
		return 1
	fi
	return 0
}

cleanup() {
local SIG="$1"
local JOBID="$2"
local OUTPUT="$3"
local OUTBASE
local TRANPID
	scriptlog DEBUG "$SIG Clean up."
	if [ "$SIG" = "ABRT" ]
	then
		scriptlog ERROR "Job Aborted. Removing incomplete $OUTPUT."
		OUTBASE=$(echo "$OUTPUT" | sed -e 's/\.[ma][pv][4i]$//')
		[ "$DEBUG" != "ON" ] && rm -rf ${OUTBASE}.avi ${OUTBASE}_video.h264 ${OUTBASE}_audio.aac {OUTBASE}_audio.ogg ${OUTBASE}.mp4 ${OUTBASE}.mkv >/dev/null 2>&1
	fi

	TRANPID=$(jobs -l | awk '/mythtranscode/ {P=$2" "P} END {print P}')
	if [ -n "$TRANPID" ]
	then
		scriptlog DEBUG "Killing mythtranscode [$TRANPID]"
		ps -p $TRANPID >/dev/null 2>&1 && kill $TRANPID >/dev/null 2>&1
	fi

	if [ "$FINALEXIT" -eq 0 ]
	then
		[ "$DEBUG" != "ON" ] && rm -rf "$FIFODIR" >/dev/null 2>&1
		scriptlog INFO "Exiting. Successfull."
		if [ "$JOBID" -ne 99999999 ]
		then
			setjobqueuestatus "$JOBID" "FINISHED"
			setjobqueuecomment "$JOBID" "[${$}] Successfully Completed"
		fi
		exit 0
	else
		scriptlog INFO "Exiting. Errored."
		if [ "$JOBID" -ne 99999999 ]
		then
			setjobqueuestatus "$JOBID" "ERRORED"
			setjobqueuecomment "$JOBID" "[${$}] Errored"
		fi
		#exit 1
		#exit 304
		# Only error code jobqueue.cpp interprets is 246. This is translated to "unable to find executable".
		scriptlog ERROR "This error could be for many reasons. Mythtv will report unable to find executable, this is incorrect."
		exit 246
	fi
}

MYSQLLIST="~mythtv/.mythtv/mysql.txt /.mythtv/mysql.txt /usr/local/share/mythtv/mysql.txt /usr/share/mythtv/mysql.txt /etc/mythtv/mysql.txt /usr/local/etc/mythtv/mysql.txt mysql.txt"
for m in $MYSQLLIST
do
	[ -f $m ] && . $m
done
if [ -z "$DBName" ]
then
	echo "Can't find mysql.txt"
	exit 1
fi

##### BG Monitor #####################################
# This will be fired off in background to update the jobqueue comment and process stop/pause/resume requests.
if echo "$1" | egrep -i '\-\-monitor=' >/dev/null 2>&1
then
	readonly MONJOBID=$(echo "$1" | cut -d'=' -f2)
	readonly MONPID="$2"
	readonly MONTRANSOP="$3"
	readonly LOGFILE="$4"
	readonly DBLOGGING=$(getsetting "LogEnabled")

	[ "$MONJOBID" -ne 99999999 -a -n "$MONPID" ] || exit 1

	PAUSEALREADYPRINTED="" ; RESUMEALREADYPRINTED=""
	
	scriptlog INFO "Starting monitoring process."
	sleep 5
	while ps -p $MONPID >/dev/null 2>&1
	do
		JQCMD=$(getjobqueuecmds "$MONJOBID")
		if [ "$JQCMD" = "PAUSE" ]
		then
			JQSTATUS=$(getjobqueuestatus "$MONJOBID")
			if [ "$JQSTATUS" != "PAUSED" ]
			then
				MENCODERPID=$(ps --ppid $MONPID | awk '/mencoder/ {print $1}')
				if [ -n "$MENCODERPID" ]
				then
					PAUSEALREADYPRINTED=""
					STARTPAUSESECS=$(date +%s)
					kill -s STOP $MENCODERPID
					setjobqueuestatus "$MONJOBID" "PAUSED"
					SAVEDCC=$(getjobqueuecomment "$MONJOBID")
					setjobqueuecomment "$MONJOBID" "[$MONPID] Paused for 0 Seconds"
					scriptlog STOP "Job Paused due to job queue pause request."
				else
					[ -z "$PAUSEALREADYPRINTED" ] && scriptlog ERROR "Sorry, could not pause. Will keep trying"
					PAUSEALREADYPRINTED=TRUE
				fi
			else
				NOW=$(date +%s)
				PAUSESECS=$(( $NOW - $STARTPAUSESECS ))
				PAUSEMINS=$(( $PAUSESECS / 60 ))
				PAUSEHOURS=$(( $PAUSEMINS / 60 ))
				PAUSEMINS=$(( $PAUSEMINS - ( $PAUSEHOURS * 60 ) ))
				PAUSESECS=$(( $PAUSESECS - ( ( $PAUSEHOURS * 60 * 60 ) + ( $PAUSEMINS * 60 ) ) ))
				setjobqueuecomment "$MONJOBID" "[$MONPID] Paused for $PAUSEHOURS Hrs $PAUSEMINS Mins $PAUSESECS Secs"
			fi
		elif [ "$JQCMD" = "RESUME" ]
		then
			JQSTATUS=$(getjobqueuestatus "$MONJOBID")
			if [ "$JQSTATUS" != "RUNNING" ]
			then
				MENCODERPID=$(ps --ppid $MONPID | awk '/mencoder/ {print $1}')
				if [ -n "$MENCODERPID" ]
				then
					RESUMEALREADYPRINTED=""
					kill -s CONT $MENCODERPID
					setjobqueuestatus "$MONJOBID" "RUNNING"
					setjobqueuecomment "$MONJOBID" "$SAVEDCC"
					scriptlog START "Job resumed due to job queue resume request."
					setjobqueuecmds "$MONJOBID" "RUN"
				else
					[ -z "$RESUMEALREADYPRINTED" ] && scriptlog ERROR "Sorry, could not resume. Will keep trying"
					RESUMEALREADYPRINTED=TRUE
				fi
			fi
		elif [ "$JQCMD" = "STOP" ]
		then
			setjobqueuestatus "$MONJOBID" "ABORTING"
			setjobqueuecomment "$MONJOBID" "[$MONPID] Stopping"
			scriptlog STOP "Stopping due to job queue stop request."
			setjobqueuecmds "$MONJOBID" "RUN"
			kill -s ABRT $MONPID
			sleep 2
			kill $MONPID
		elif [ "$JQCMD" = "RESTART" ]
		then
			scriptlog ERROR "Sorry, can't restart job."
			setjobqueuecmds "$MONJOBID" "RUN"
		else
			CC=$(getjobqueuecomment "$MONJOBID")
			if echo "$CC" | grep 'audio pass' >/dev/null 2>&1
			then
				PASSNU="audio pass"
			elif echo "$CC" | grep 'Single video pass' >/dev/null 2>&1
			then
				PASSNU="Single video pass"
			elif echo "$CC" | grep '1st video pass' >/dev/null 2>&1
			then
				PASSNU="1st video pass"
			elif echo "$CC" | grep '2nd video pass' >/dev/null 2>&1
			then
				PASSNU="2nd video pass"
			else
				sleep 15
				continue
			fi
			PCTLINE=$(tail -10 $MONTRANSOP | grep 'mythtranscode:' | cut -c39- | tail -1)
			[ -n "$PASSNU" -a -n "$PCTLINE" ] && setjobqueuecomment "$MONJOBID" "[$MONPID] $PASSNU $PCTLINE"
		fi
		sleep 15
	done
	exit
fi

##### Globals ########################################
readonly CMD="$0"
readonly LOGFILE="/var/tmp/mythnuv2mkv${$}.log"
readonly FIFODIR="/var/tmp/mythnuv2mkv${$}"
readonly MENCODEROP="${FIFODIR}/mencoder.op"
readonly TRANSOP="${FIFODIR}/transcode.op"
readonly STOPREQUEST="${FIFODIR}/STOPREQUEST"
readonly CFDIR=$(getsetting "VideoArtworkDir")
if ! tty >/dev/null 2>&1
then
	readonly BOLDON=""
	readonly ALLOFF=""
	readonly REDFG=""
	readonly GREENFG=""
	readonly COLOURORIG=""
	[ "$DEBUG" = "ON" ] && exec 3>/var/tmp/DEBUG || exec 3>/dev/null
	exec 1>&3
	exec 2>&3
else
	readonly BOLDON=`tput bold`
	readonly ALLOFF=`tput sgr0`
	readonly REDFG=`tput setaf 1`
	readonly GREENFG=`tput setaf 2`
	readonly COLOURORIG=`tput op`
fi
# DBLOGGING is reverse to shell true/false
DBLOGGING=0
OUTPUT=""
JOBID=99999999
FINALEXIT=0
STARTSECS="NA"
MAXRUNHOURS="NA"

##### Main ###########################################
if echo "$1" | egrep -i '\-help|\-usage|\-\?' >/dev/null 2>&1
then
	echo "$HELP"
	exit 1
fi

if [ "$CONTYPE" = "mkv" ]
then
	chkreqs "$MKVREQPROGS" "$MKVREQLIBS" || exit 1
elif [ "$CONTYPE" = "mp4" ]
then
	chkreqs "$MP4REQPROGS" "$MP4REQLIBS" || exit 1
elif [ "$CONTYPE" = "avi" ]
then
	chkreqs "$AVIREQPROGS" "$AVIREQLIBS" || exit 1
fi

# Jobid from myth user job %JOBID%
if echo "$1" | egrep -i '\-\-jobid=' >/dev/null 2>&1
then
	JOBID=$(echo "$1" | cut -d'=' -f2)
	DBLOGGING=$(getsetting "LogEnabled")
	shift
fi

if echo "$1" | egrep -i '\-\-findtitle=' >/dev/null 2>&1
then
	SEARCHTITLE=$(echo "$1" | cut -d'=' -f2)
	MATCHTITLE=$(findchanidstarttime "$SEARCHTITLE")	
	echo "$MATCHTITLE"
	exit 0
fi

if echo "$1" | grep -i '\-\-maxrunhours=' >/dev/null 2>&1
then
	STARTSECS=$(date +%s)
	MAXRUNHOURS=$(echo "$1" | cut -d'=' -f2)
	shift
fi

trap 'cleanup ABRT "$JOBID" "$OUTPUT"' INT ABRT
trap 'touch $STOPREQUEST ; scriptlog INFO "USR1 received. Will stop after current file completes."' USR1
trap 'cleanup EXIT "$JOBID"' EXIT
mkdir ${FIFODIR} >/dev/null 2>&1

for INPUT in "$@"
do
	if stoptime $STARTSECS $MAXRUNHOURS
	then
		scriptlog STOP "Stopping due to max runtime $MAXRUNHOURS."
		scriptlog BREAK 
		break
	fi
	if [ -f "$STOPREQUEST" ]
	then
		scriptlog STOP "Stopping due to USR1 request."
		scriptlog BREAK 
		break
	fi

	if echo "$INPUT" | grep -i '\-\-debug=' >/dev/null 2>&1
	then
		DEBUG=$(echo "$INPUT" | cut -d'=' -f2 | tr [a-z] [A-Z])
		continue
	fi
	if echo "$INPUT" | grep -i '\-\-info=' >/dev/null 2>&1
	then
		INFO=$(echo "$INPUT" | cut -d'=' -f2 | tr [a-z] [A-Z])
		continue
	fi
	if echo "$INPUT" | grep -i '\-\-savenuv=' >/dev/null 2>&1
	then
		SAVENUV=$(echo "$INPUT" | cut -d'=' -f2 | tr [a-z] [A-Z])
		continue
	fi

	if echo "$INPUT" | grep -i '\-\-copydir=' >/dev/null 2>&1
	then
		COPYDIR=$(echo "$INPUT" | cut -d'=' -f2)
		if [ -d "$COPYDIR" -a -w "$COPYDIR" ]
		then
			scriptlog INFO "AVI will be located in $COPYDIR."
		else
			scriptlog ERROR "$COPYDIR does not exist or is not writable. Continuing but result will be left in source directory unless $COPYDIR is created before job completes."
		fi	
		continue
	fi

	if echo "$INPUT" | grep -i '\-\-contype=' >/dev/null 2>&1
	then
		TMP=$(echo "$INPUT" | cut -d'=' -f2 | tr [A-Z] [a-z])
		OLDIFS="$IFS"; IFS=","; set - $TMP; IFS="$OLDIFS"
		TMP1="$1" ; TMP2="$2"
		if [ "$TMP1" = "mp4" ]
		then
			if [ -n "$CHANID" -a -z "$COPYDIR" ]
			then
				scriptlog ERROR "Changed to $TMP1 failed. mp4 not supported in MythRecord."
			elif ! chkreqs "$MP4REQPROGS" "$MP4REQLIBS"
			then
				scriptlog ERROR "Changed to $TMP1 failed. Missing Requirements."
			else
				CONTYPE="mp4"
				scriptlog INFO "Changed to $CONTYPE."
			fi
		elif [ "$TMP1" = "mkv" ]
		then
			if [ -n "$CHANID" -a -z "$COPYDIR" ]
			then
				scriptlog ERROR "Changed to $TMP1 failed. mkv not supported in MythRecord."
			elif ! chkreqs "$MKVREQPROGS" "$MKVREQLIBS"
			then
				scriptlog ERROR "Changed to $TMP1 failed. Missing Requirements."
			else
				CONTYPE="mkv"
				[ "$TMP2" = "ogg" ] && MKVAUD="ogg"
				[ "$TMP2" = "acc" ] && MKVAUD="acc"
				scriptlog INFO "Changed to ${CONTYPE},${MKVAUD}."
			fi
		elif [ "$TMP1" = "avi" ]
		then
			if ! chkreqs "$AVIREQPROGS" "$AVIREQLIBS"
			then
				scriptlog ERROR "Changed to $TMP1 failed. Missing Requirements."
			else
				CONTYPE="avi"
				scriptlog INFO "Changed to $CONTYPE."
			fi
		else
			scriptlog ERROR "Changed to $TMP1 failed. Invalid contype."
		fi
		continue
	fi

	if echo "$INPUT" | grep -i '\-\-pass=' >/dev/null 2>&1
	then
		TMP=$(echo "$INPUT" | cut -d'=' -f2 | tr [A-Z] [a-z])
		if [ "$TMP" = "one" -o "$TMP" = "1" ]
		then
			scriptlog INFO "Changed to $TMP pass."
			PASS="one"
		elif [ "$TMP" = "two" -o "$TMP" = "2" ]
		then
			scriptlog INFO "Changed to $TMP pass."
			PASS="two"
		else
			scriptlog ERROR "Changed to $TMP failed. Invalid contype."
		fi
		continue
	fi

	if echo "$INPUT" | grep -i '\-\-quality=' >/dev/null 2>&1
	then
		QLEVEL=$(echo "$INPUT" | cut -d'=' -f2)
		if echo "$QLEVEL" | grep -i "high" >/dev/null 2>&1
		then
			SCALE43=$HIGH_SCALE43
			SCALE169=$HIGH_SCALE169
			MPEG4_CQ=$HIGH_MPEG4_CQ
			MPEG4_OPTS=$HIGH_MPEG4_OPTS
			MP3_ABITRATE=$HIGH_MP3_ABITRATE
			X264_CQ=$HIGH_X264_CQ
			X264_OPTS=$HIGH_X264_OPTS
			#AAC_ABITRATE=$HIGH_AAC_ABITRATE
			AAC_AQUAL=$HIGH_AAC_AQUAL
			OGG_AQUAL=$HIGH_OGG_AQUAL
		elif echo "$QLEVEL" | grep -i "med" >/dev/null 2>&1
		then
			SCALE43=$MED_SCALE43
			SCALE169=$MED_SCALE169
			MPEG4_CQ=$MED_MPEG4_CQ
			MPEG4_OPTS=$MED_MPEG4_OPTS
			MP3_ABITRATE=$MED_MP3_ABITRATE
			X264_CQ=$MED_X264_CQ
			X264_OPTS=$MED_X264_OPTS
			#AAC_ABITRATE=$MED_AAC_ABITRATE
			AAC_AQUAL=$MED_AAC_AQUAL
			OGG_AQUAL=$MED_OGG_AQUAL
		elif echo "$QLEVEL" | grep -i "low" >/dev/null 2>&1
		then
			SCALE43=$LOW_SCALE43
			SCALE169=$LOW_SCALE169
			MPEG4_CQ=$LOW_MPEG4_CQ
			MPEG4_OPTS=$LOW_MPEG4_OPTS
			MP3_ABITRATE=$LOW_MP3_ABITRATE
			X264_CQ=$LOW_X264_CQ
			X264_OPTS=$LOW_X264_OPTS
			#AAC_ABITRATE=$LOW_AAC_ABITRATE
			AAC_AQUAL=$LOW_AAC_AQUAL
			OGG_AQUAL=$LOW_OGG_AQUAL
		fi
		scriptlog INFO "Changed to $QLEVEL quality."
		continue
	fi

	if echo "$INPUT" | grep -i '\-\-chanid=' >/dev/null 2>&1
	then
		CHANID=$(echo "$INPUT" | cut -d'=' -f2)
		continue
	fi
	if echo "$INPUT" | grep -i '\-\-starttime=' >/dev/null 2>&1
	then
		STARTTIME=$(echo "$INPUT" | cut -d'=' -f2)
		if [ -z "$CHANID" ]
		then
			scriptlog ERROR "Skipping $STARTTIME. chanid not specified."
			scriptlog BREAK 
			unset STARTTIME
			continue
		fi
		RECFILE=$(getrecordfile "$CHANID" "$STARTTIME")
		if [ -z "$RECFILE" ]
		then
			scriptlog ERROR "Skipping $CHANID $STARTTIME. Did not match a recording."
			scriptlog BREAK 
			unset CHANID STARTTIME
			continue
		fi
		RECDIR=$(getsetting "RecordFilePrefix")
		INPUT="${RECDIR}/${RECFILE}"
		TITLE=$(gettitle $CHANID $STARTTIME)
		MYTHTRANSSOURCE="--chanid $CHANID --starttime $STARTTIME"
		hascutlist $CHANID $STARTTIME && MYTHTRANSSOURCE="$MYTHTRANSSOURCE --honorcutlist"
		scriptlog INFO "$CHANID $STARTTIME matches $TITLE ($INPUT)"
	else
		echo "$INPUT" | grep '^\/' >/dev/null 2>&1 || INPUT="`pwd`/${INPUT}"
		MYTHTRANSSOURCE="--infile $INPUT"
	fi

	if [ ! -f "$INPUT" ]
	then
		scriptlog ERROR "Skipping $INPUT does not exist."
		scriptlog BREAK 
		unset CHANID STARTTIME
		continue
	fi

	if echo "$INPUT" | grep -v '\.[nm][up][vg]$' >/dev/null 2>&1
	then
		scriptlog ERROR "Skipping $INPUT not a nuv or mpg file."
		scriptlog BREAK 
		unset CHANID STARTTIME
		continue
	fi

	OUTBASE=$(echo "$INPUT" | sed -e 's/\.[nm][up][vg]$//')
	OUTPUT="${OUTBASE}.${CONTYPE}"
	if [ -f "$OUTPUT" ]
	then
		scriptlog ERROR "Skipping $INPUT. $OUTPUT already exists."
		scriptlog BREAK 
		unset CHANID STARTTIME
		continue
	fi

	INSIZE=$(( `stat -c %s ${INPUT}` / 1024 ))
	FREESPACE=$(df -k "$INPUT" | awk 'END {print $3}')
	if [ $(( $FREESPACE - $INSIZE )) -lt 10000 ]
	then
		scriptlog ERROR "Stopping due to disk space shortage."
		scriptlog BREAK 
		break
	fi

	ASPECTSTR="NA";ASPECT="NA";SCALE="NA";VBITRATE="NA";ASPECTFOUNDIN="NA"
	TMP=$(getaspect "$INPUT")
	ASPECTSTR=$(echo "$TMP" | cut -d',' -f1)
	ASPECTFOUNDIN=$(echo "$TMP" | cut -d',' -f2)
	if [ "$ASPECTSTR" != "4:3" -a "$ASPECTSTR" != "16:9" ]
	then
		scriptlog ERROR "Skipping $INPUT. Aspect is $ASPECTSTR must be 16:9 or 4:3."
		scriptlog ERROR "If this is a mpg file make sure to set DEFAULTMPEG2ASPECT at top of this script."
		scriptlog BREAK 
		unset CHANID STARTTIME
		continue
	fi
	scriptlog INFO "Aspect $ASPECTSTR. Found in $ASPECTFOUNDIN"

	if [ "$ASPECTSTR" = "4:3" ]
	then
		ASPECT=1.333333333
		SCALE=$SCALE43
	elif [ "$ASPECTSTR" = "16:9" ]
	then
		ASPECT=1.77777777778
		SCALE=$SCALE169
	fi
	SCALESTR=$( echo $SCALE | tr ':' 'x' )

	FILEINFO=$(getvidinfo "$INPUT" width height fps audio_sample_rate audio_channels)
	OLDIFS="$IFS"; IFS=":"; set - $FILEINFO; IFS="$OLDIFS"
	INWIDTH="$1"; INHEIGHT="$2"; INFPS="$3"; INARATE="$4"; CHANNELS="$5"
	if [ "$#" -ne 5 ]
	then
		scriptlog ERROR "Skipping $INPUT. Could not obtain vid format details"
		scriptlog BREAK 
		unset CHANID STARTTIME
		continue
	fi

	CROPX=$CROP
	CROPY=$CROP
	CROPW=$(( $INWIDTH - ( 2 * $CROPX ) ))
	CROPH=$(( $INHEIGHT - ( 2 * $CROPY ) ))
	CROPVAL="${CROPW}:${CROPH}:${CROPX}:${CROPY}"

	# Force avi for videos staying in MythRecord
	if [ "$CONTYPE" = "avi" ] || [ -n "$CHANID" -a -z "$COPYDIR" ]
	then
		VBITRATE=$(calcbitrate $ASPECT $SCALE $MPEG4_CQ)
		ABITRATE=$MP3_ABITRATE
		PASSCMD="vpass"
		VIDEOCODEC="-ovc lavc -lavcopts ${MPEG4_OPTS}:vbitrate=${VBITRATE}"
		VIDEXT="mpeg4"
		AUDIOCODEC="-oac mp3lame -lameopts vbr=2:br=${ABITRATE}"
		AUDEXT="mp3"
		MENOUT1STPASS="-aspect $ASPECT -force-avi-aspect $ASPECTSTR -o /dev/null"
		MENOUTOPT="-aspect $ASPECT -force-avi-aspect $ASPECTSTR -o"
		MENOUTFILE="$OUTPUT"
	elif [ "$CONTYPE" = "mp4" ]
	then
		VBITRATE=$(calcbitrate $ASPECT $SCALE $X264_CQ)
		#ABITRATE=$AAC_ABITRATE
		AQUAL=$AAC_AQUAL
		PASSCMD="pass"
		VIDEOCODEC="-ovc x264 -x264encopts ${X264_OPTS}:bitrate=${VBITRATE}"
		VIDEXT="h264"
		AUDIOCODEC="-oac copy"
		AUDEXT="aac"
		MENOUT1STPASS="-of rawvideo -o /dev/null"
		MENOUTOPT="-of rawvideo -o"
		MENOUTFILE="${OUTBASE}_video.h264"
	elif [ "$CONTYPE" = "mkv" ]
	then
		VBITRATE=$(calcbitrate $ASPECT $SCALE $X264_CQ)
		if [ "$MKVAUD" = "ogg" ]
		then
			AQUAL=$OGG_AQUAL
			AUDEXT="ogg"
		else
			#ABITRATE=$AAC_ABITRATE
			AQUAL=$AAC_AQUAL
			AUDEXT="aac"
		fi
		PASSCMD="pass"
		VIDEOCODEC="-ovc x264 -x264encopts ${X264_OPTS}:bitrate=${VBITRATE}"
		VIDEXT="h264"
		AUDIOCODEC="-oac copy"
		MENOUT1STPASS="-of rawvideo -o /dev/null"
		MENOUTOPT="-of rawvideo -o"
		MENOUTFILE="${OUTBASE}_video.h264"
	else
		scriptlog ERROR "Skipping $INPUT. Incorrect video contype selected. $CONTYPE"
		scriptlog BREAK 
		unset CHANID STARTTIME
		continue
	fi

	RETCODE=0
	# Fireoff a background monitoring job to update the job queue details
	[ "$JOBID" -ne 99999999 ] && $CMD --monitor=$JOBID ${$} $TRANSOP $LOGFILE &

	# mp4/mkv have seperate Audio/Video transcodes.
	if [ "$AUDEXT" = "aac" ]
	then
		scriptlog START "Starting $AUDEXT audio trans of $INPUT. quality $AQUAL."
		[ "$JOBID" -ne 99999999 ] && setjobqueuecomment "$JOBID" "[${$}] audio pass started"

		if [ ! -f ${OUTBASE}_audio.${AUDEXT} ]
		then
			rm -f ${FIFODIR}/*out $TRANSOP $MENCODEROP
			nice -n 19 mythtranscode --profile autodetect $MYTHTRANSSOURCE --fifodir $FIFODIR | tee -a $TRANSOP &
			sleep 10
			# Throw away video
			nice -n 19 dd bs=512k if=${FIFODIR}/vidout of=/dev/null &
			nice -n 19 faac ${FIFODIR}/audout -P -R ${INARATE} -C ${CHANNELS} -X -q ${AQUAL} --mpeg-vers 4 -o ${OUTBASE}_audio.${AUDEXT}
			RETCODE=$?
			sleep 10
			if [ $RETCODE -ne 0 ]
			then
				scriptlog ERROR "Skipping $INPUT. Problem with audio pass."
				scriptlog BREAK 
				unset CHANID STARTTIME
				continue
			fi
		fi
	elif [ "$AUDEXT" = "ogg" ]
	then
		scriptlog START "Starting $AUDEXT audio trans of $INPUT. quality $AQUAL."
		[ "$JOBID" -ne 99999999 ] && setjobqueuecomment "$JOBID" "[${$}] audio pass started"

		if [ ! -f ${OUTBASE}_audio.${AUDEXT} ]
		then
			rm -f ${FIFODIR}/*out $TRANSOP $MENCODEROP
			nice -n 19 mythtranscode --profile autodetect $MYTHTRANSSOURCE --fifodir $FIFODIR | tee -a $TRANSOP &
			sleep 10
			# Throw away video
			nice -n 19 dd bs=512k if=${FIFODIR}/vidout of=/dev/null &
			nice -n 19 oggenc --raw-chan=${CHANNELS} --raw-rate=${INARATE} --quality=${AQUAL} -o ${OUTBASE}_audio.${AUDEXT} ${FIFODIR}/audout
			RETCODE=$?
			sleep 10
			if [ $RETCODE -ne 0 ]
			then
				scriptlog ERROR "Skipping $INPUT. Problem with audio pass."
				scriptlog BREAK 
				unset CHANID STARTTIME
				continue
			fi
		fi
	fi

	if [ "$PASS" = "one" ]
	then
		[ "$JOBID" -ne 99999999 ] && setjobqueuecomment "$JOBID" "[${$}] Single video pass started."
		scriptlog START "Starting $VIDEXT Single video pass trans of $INPUT. crop $CROPVAL scale $SCALESTR aspect $ASPECTSTR vbr $VBITRATE abr $ABITRATE."
		if [ ! -f "${MENOUTFILE}" ]
		then
			rm -f ${FIFODIR}/*out $TRANSOP $MENCODEROP
			nice -n 19 mythtranscode --profile autodetect $MYTHTRANSSOURCE --fifodir $FIFODIR | tee -a $TRANSOP &
			sleep 10
			nice -n 19 mencoder -idx -noskip \
			${FIFODIR}/vidout -demuxer rawvideo -rawvideo w=${INWIDTH}:h=${INHEIGHT}:fps=${INFPS} \
			-audiofile ${FIFODIR}/audout -audio-demuxer rawaudio -rawaudio rate=${INARATE}:channels=${CHANNELS} \
			${VIDEOCODEC} \
			${AUDIOCODEC} \
			-vf pp=fd,crop=${CROPVAL},scale=${SCALE},harddup -sws 7 \
			${MENOUTOPT} ${MENOUTFILE} | tee -a $MENCODEROP
			RETCODE=$?
			sleep 10
		fi
	else
		scriptlog START "Starting $VIDEXT 1st video pass trans of $INPUT. crop $CROPVAL scale $SCALESTR aspect $ASPECTSTR vbr $VBITRATE abr $ABITRATE."
		[ "$JOBID" -ne 99999999 ] && setjobqueuecomment "$JOBID" "[${$}] 1st video pass started."
		if [ ! -f "${MENOUTFILE}" ]
		then
			rm -f ${FIFODIR}/*out $TRANSOP $MENCODEROP
			nice -n 19 mythtranscode --profile autodetect $MYTHTRANSSOURCE --fifodir $FIFODIR | tee -a $TRANSOP &
			sleep 10
			nice -n 19 mencoder -idx \
			${FIFODIR}/vidout -demuxer rawvideo -rawvideo w=${INWIDTH}:h=${INHEIGHT}:fps=${INFPS} \
			-audiofile ${FIFODIR}/audout -audio-demuxer rawaudio -rawaudio rate=${INARATE}:channels=${CHANNELS} \
			${VIDEOCODEC}:${PASSCMD}=1:turbo -passlogfile ${FIFODIR}/2pass.log \
			${AUDIOCODEC} \
			-vf pp=fd,crop=${CROPVAL},scale=${SCALE} -sws 7 \
			${MENOUT1STPASS}
			RETCODE=$?
			sleep 10
			if [ $RETCODE -ne 0 ]
			then
				scriptlog ERROR "Skipping $INPUT. Problem with 1st video pass of 2."
				scriptlog BREAK 
				unset CHANID STARTTIME
				continue
			fi
		fi

		scriptlog START "Starting $VIDEXT 2nd video pass trans of $INPUT. crop $CROPVAL scale $SCALESTR aspect $ASPECTSTR vbr $VBITRATE abr $ABITRATE."
		[ "$JOBID" -ne 99999999 ] && setjobqueuecomment "$JOBID" "[${$}] 2nd video pass started."
		if [ ! -f "${MENOUTFILE}" ]
		then
			rm -f ${FIFODIR}/*out $TRANSOP $MENCODEROP
			nice -n 19 mythtranscode --profile autodetect $MYTHTRANSSOURCE --fifodir $FIFODIR | tee -a $TRANSOP &
			sleep 10
			nice -n 19 mencoder -idx -noskip \
			${FIFODIR}/vidout -demuxer rawvideo -rawvideo w=${INWIDTH}:h=${INHEIGHT}:fps=${INFPS} \
			-audiofile ${FIFODIR}/audout -audio-demuxer rawaudio -rawaudio rate=${INARATE}:channels=${CHANNELS} \
			${VIDEOCODEC}:${PASSCMD}=2 -passlogfile ${FIFODIR}/2pass.log \
			${AUDIOCODEC} \
			-vf pp=fd,crop=${CROPVAL},scale=${SCALE} -sws 7 \
			${MENOUTOPT} ${MENOUTFILE} | tee -a $MENCODEROP
			RETCODE=$?
			sleep 10
		fi
	fi

	if [ $RETCODE -ne 0 ]
	then
		scriptlog ERROR "Skipping $INPUT. Problem with final video pass. $OUTPUT may exist."
		scriptlog BREAK 
		unset CHANID STARTTIME
		continue
	fi

	if [ -n "$CHANID" ]
	then
		TITLE=$(gettitlestr "$CHANID" "$STARTTIME")
	else
		TITLE=$(basename "$OUTPUT" | sed -e 's/\.[am][vkp][iv4]$//')
	fi

	if [ "$CONTYPE" = "mp4" -o "$CONTYPE" = "mkv" ]
	then
		scriptlog START "Joining ${OUTBASE}_video.h264 ${OUTBASE}_audio.${AUDEXT} in $CONTYPE container."
		[ "$JOBID" -ne 99999999 ] && setjobqueuecomment "$JOBID" "[${$}] Joining in $CONTYPE container."
		if ! encloseincontainer "$OUTBASE" $INFPS $AUDEXT $CONTYPE $ASPECTSTR $TITLE
		then
			scriptlog ERROR "$CONTYPE container Failed for $OUTPUT."
			scriptlog BREAK 
			unset CHANID STARTTIME
			continue
		fi
	fi

	scriptlog START "Checking $OUTPUT."
	[ "$JOBID" -ne 99999999 ] && setjobqueuecomment "$JOBID" "[${$}] Checking result."
	if ! checkoutput "$INPUT" "$OUTPUT" "$MENCODEROP"
	then
		mv "$OUTPUT" "${OUTPUT}-SUSPECT"
		scriptlog ERROR "$OUTPUT may be faulty. Saved as ${OUTPUT}-SUSPECT. $INPUT kept."
		scriptlog BREAK 
		unset CHANID STARTTIME
		continue
	fi

	if [ -n "$COPYDIR" ]
	then
		# Is this a good idea?
		#CATEGORY=$(getcategory "$CHANID" "$STARTTIME")
		#[ -n "$CATEGORY" ]
		#then
		#	COPYDIR="${COPYDIR}/${CATEGORY}"
		#fi
		[ -d "$COPYDIR" ] || mkdir -p "$COPYDIR"
		COPYFILE="${TITLE}.${CONTYPE}"
		while [ -f "${COPYDIR}/${COPYFILE}" ]
		do
			COUNT=$(( ${COUNT:=0} + 1 ))
			COPYFILE="${TITLE}_${COUNT}.${CONTYPE}"
		done
		if cp "$OUTPUT" "${COPYDIR}/${COPYFILE}"
		then
			rm $OUTPUT
			scriptlog SUCCESS "Successful trans. $INPUT trans to ${COPYDIR}/${COPYFILE}. $INPUT kept"
			MYTHVIDDIR=$(getsetting VideoStartupDir)
			echo "$COPYDIR" grep "$MYTHVIDDIR" >/dev/null 2>&1 && createvideometadata "${COPYDIR}/${COPYFILE}" "$ASPECTSTR" "$CHANID" "$STARTTIME"
		else
			scriptlog ERROR "Successful trans but copy to $COPYDIR bad. $INPUT trans to $OUTPUT. $INPUT kept"
		fi
	else
		if [ -n "$CHANID" ]
		then
			scriptlog INFO "Updating MythRecord db to $OUTPUT."
			updatemetadata "REC" "$INPUT" "$OUTPUT" "$CHANID" "$STARTTIME"
			# mythcommflag --rebuild does not work correctly for avi files.
			# Without this you can't edit files, but with it seeks don't work correctly.
			#scriptlog INFO "Rebuilding seektable for $OUTPUT."
			#mythcommflag --chanid $CHANID_CFOLD --starttime "$STARTTIME_CFNEW" --rebuild >/dev/null
			rm "${INPUT}.png"
		else
			# This is to handle my bad coverfile names done by V0.1 videocovers.sh
			# i.e. mv video.nuv.png to video.png
			INPUTCOVERFILE="${CFDIR}/$(basename ${INPUT}).png"
			OUTPUTCOVERFILE="${CFDIR}/$(basename ${OUTBASE}).png"
			mv "$INPUTCOVERFILE" "$OUTPUTCOVERFILE" >/dev/null 2>&1
			scriptlog INFO "Updating MythVideo db to $OUTPUT."
			updatemetadata "VIDEO" "$INPUT" "$OUTPUT" "$INPUTCOVERFILE" "$OUTPUTCOVERFILE"
		fi
		[ "$DEBUG" = "ON" -o "$SAVENUV" = "ON" ] && mv "$INPUT" "${INPUT}OK-DONE"
		[ "$DEBUG" != "ON" -a "$SAVENUV" != "ON" ] && rm "$INPUT"
		scriptlog SUCCESS "Successful trans to $OUTPUT. $INPUT removed."
	fi
	scriptlog BREAK 
	unset CHANID STARTTIME
done
exit $FINALEXIT


#STARTNUVINFO
#!/usr/bin/perl
# $Date: 2008/07/18 12:50:11 $
# $Revision: 1.26 $
# $Author: mythtv $
#
#  mythtv::nuvinfo.pm
#
#   exports one routine:  nuv_info($path_to_nuv)
#   This routine inspects a specified nuv file, and returns information about
#   it, gathered either from its nuv file structure
#
# Auric grabbed from nuvexport and Modified. Thanks to the nuvexport guys, I never would have been able to work this out
#
# finfo version width height desiredheight desiredwidth pimode aspect fps videoblocks audioblocks textsblocks keyframedist video_type audio_type audio_sample_rate audio_bits_per_sample audio_channels audio_compression_ratio audio_quality rtjpeg_quality rtjpeg_luma_filter rtjpeg_chroma_filter lavc_bitrate lavc_qmin lavc_qmax lavc_maxqdiff seektable_offset keyframeadjust_offset

# Byte swap a 32-bit number from little-endian to big-endian
    sub byteswap32 {
       # Read in a 4-character string
       my $in = shift;
       my $out = $in;

       if ($Config{'byteorder'} == 4321) {
           substr($out, 0, 1) = substr($in, 3, 1);
           substr($out, 3, 1) = substr($in, 0, 1);
           substr($out, 1, 1) = substr($in, 2, 1);
           substr($out, 2, 1) = substr($in, 1, 1);
       }

       return $out;
    }

# Byte swap a 64-bit number from little-endian to big-endian
    sub byteswap64 {
       # Read in a 8-character string
       my $in = shift;
       my $out = $in;

       if ($Config{'byteorder'} == 4321) {
           substr($out, 4, 4) = byteswap32(substr($in, 0, 4));
           substr($out, 0, 4) = byteswap32(substr($in, 4, 4));
       }

       return $out;
    }

# Opens a .nuv file and returns information about it
    sub nuv_info {
        my $file = shift;
        my(%info, $buffer);
    # open the file
        open(DATA, $file) or die "Can't open $file:  $!\n\n";
    # Read the file info header
        read(DATA, $buffer, 72);
    # Byte swap the buffer
        if ($Config{'byteorder'} == 4321) {
            substr($buffer, 20, 4) = byteswap32(substr($buffer, 20, 4));
            substr($buffer, 24, 4) = byteswap32(substr($buffer, 24, 4));
            substr($buffer, 28, 4) = byteswap32(substr($buffer, 28, 4));
            substr($buffer, 32, 4) = byteswap32(substr($buffer, 32, 4));
            substr($buffer, 40, 8) = byteswap64(substr($buffer, 40, 8));
            substr($buffer, 48, 8) = byteswap64(substr($buffer, 48, 8));
            substr($buffer, 56, 4) = byteswap32(substr($buffer, 56, 4));
            substr($buffer, 60, 4) = byteswap32(substr($buffer, 60, 4));
            substr($buffer, 64, 4) = byteswap32(substr($buffer, 64, 4));
            substr($buffer, 68, 4) = byteswap32(substr($buffer, 68, 4));
        }
    # Unpack the data structure
        ($info{'finfo'},          # "NuppelVideo" + \0
         $info{'version'},        # "0.05" + \0
         $info{'width'},
         $info{'height'},
         $info{'desiredheight'},  # 0 .. as it is
         $info{'desiredwidth'},   # 0 .. as it is
         $info{'pimode'},         # P .. progressive, I .. interlaced  (2 half pics) [NI]
         $info{'aspect'},         # 1.0 .. square pixel (1.5 .. e.g. width=480: width*1.5=720 for capturing for svcd material
         $info{'fps'},
         $info{'videoblocks'},    # count of video-blocks -1 .. unknown   0 .. no video
         $info{'audioblocks'},    # count of audio-blocks -1 .. unknown   0 .. no audio
         $info{'textsblocks'},    # count of text-blocks  -1 .. unknown   0 .. no text
         $info{'keyframedist'}
            ) = unpack('Z12 Z5 xxx i i i i a xxx d d i i i i', $buffer);
    # Perl occasionally over-reads on the previous read()
        seek(DATA, 72, 0);
    # Read and parse the first frame header
        read(DATA, $buffer, 12);
    # Byte swap the buffer
        if ($Config{'byteorder'} == 4321) {
            substr($buffer, 4, 4) = byteswap32(substr($buffer, 4, 4));
            substr($buffer, 8, 4) = byteswap32(substr($buffer, 8, 4));
        }
        my ($frametype,
            $comptype,
            $keyframe,
            $filters,
            $timecode,
            $packetlength) = unpack('a a a a i i', $buffer);
    # Parse the frame
        die "Illegal nuv file format:  $file\n\n" unless ($frametype eq 'D');
    # Read some more stuff if we have to
        read(DATA, $buffer, $packetlength) if ($packetlength);
    # Read the remaining frame headers
        while (12 == read(DATA, $buffer, 12)) {
        # Byte swap the buffer
            if ($Config{'byteorder'} == 4321) {
                substr($buffer, 4, 4) = byteswap32(substr($buffer, 4, 4));
                substr($buffer, 8, 4) = byteswap32(substr($buffer, 8, 4));
            }
        # Parse the frame header
            ($frametype,
             $comptype,
             $keyframe,
             $filters,
             $timecode,
             $packetlength) = unpack('a a a a i i', $buffer);
        # Read some more stuff if we have to
            read(DATA, $buffer, $packetlength) if ($packetlength);
        # Look for the audio frame
            if ($frametype eq 'X') {
            # Byte swap the buffer
                if ($Config{'byteorder'} == 4321) {
                    substr($buffer, 0, 4)  = byteswap32(substr($buffer, 0, 4));
                    substr($buffer, 12, 4) = byteswap32(substr($buffer, 12, 4));
                    substr($buffer, 16, 4) = byteswap32(substr($buffer, 16, 4));
                    substr($buffer, 20, 4) = byteswap32(substr($buffer, 20, 4));
                    substr($buffer, 24, 4) = byteswap32(substr($buffer, 24, 4));
                    substr($buffer, 28, 4) = byteswap32(substr($buffer, 28, 4));
                    substr($buffer, 32, 4) = byteswap32(substr($buffer, 32, 4));
                    substr($buffer, 36, 4) = byteswap32(substr($buffer, 36, 4));
                    substr($buffer, 40, 4) = byteswap32(substr($buffer, 40, 4));
                    substr($buffer, 44, 4) = byteswap32(substr($buffer, 44, 4));
                    substr($buffer, 48, 4) = byteswap32(substr($buffer, 48, 4));
                    substr($buffer, 52, 4) = byteswap32(substr($buffer, 52, 4));
                    substr($buffer, 56, 4) = byteswap32(substr($buffer, 56, 4));
                    substr($buffer, 60, 8) = byteswap64(substr($buffer, 60, 8));
                    substr($buffer, 68, 8) = byteswap64(substr($buffer, 68, 8));
                }
                my $frame_version;
                ($frame_version,
                 $info{'video_type'},
                 $info{'audio_type'},
                 $info{'audio_sample_rate'},
                 $info{'audio_bits_per_sample'},
                 $info{'audio_channels'},
                 $info{'audio_compression_ratio'},
                 $info{'audio_quality'},
                 $info{'rtjpeg_quality'},
                 $info{'rtjpeg_luma_filter'},
                 $info{'rtjpeg_chroma_filter'},
                 $info{'lavc_bitrate'},
                 $info{'lavc_qmin'},
                 $info{'lavc_qmax'},
                 $info{'lavc_maxqdiff'},
                 $info{'seektable_offset'},
                 $info{'keyframeadjust_offset'}
                 ) = unpack('ia4a4iiiiiiiiiiiill', $buffer);
            # Found the audio data we want - time to leave
                 last;
            }
        # Done reading frames - let's leave
            else {
                last;
            }
        }
    # Close the file
        close DATA;
    # Make sure some things are actually numbers
        $info{'width'}  += 0;
        $info{'height'} += 0;
    # HD fix
        if ($info{'height'} == 1080) {
            $info{'height'} = 1088;
        }
    # Make some corrections for myth bugs
        $info{'audio_sample_rate'} = 44100 if ($info{'audio_sample_rate'} == 42501 || $info{'audio_sample_rate'} =~ /^44\d\d\d$/);
    # NEIL Don't know why he hard set it?
    #    $info{'aspect'} = '4:3';
    # Cleanup
        $info{'aspect'}   = aspect_str($info{'aspect'});
        $info{'aspect_f'} = aspect_float($info{'aspect'});
    # Return
        return %info;
    }

    sub aspect_str {
        my $aspect = shift;
    # Already in ratio format
        return $aspect if ($aspect =~ /^\d+:\d+$/);
    # European decimals...
        $aspect =~ s/\,/\./;
    # Parse out decimal formats
        if ($aspect == 1)          { return '1:1';    }
        elsif ($aspect =~ m/^1.3/) { return '4:3';    }
        elsif ($aspect =~ m/^1.7/) { return '16:9';   }
        elsif ($aspect == 2.21)    { return '2.21:1'; }
    # Unknown aspect
        print STDERR "Unknown aspect ratio:  $aspect\n";
        return $aspect.':1';
    }

    sub aspect_float {
        my $aspect = shift;
    # European decimals...
        $aspect =~ s/\,/\./;
    # In ratio format -- do the math
        if ($aspect =~ /^\d+:\d+$/) {
            my ($w, $h) = split /:/, $aspect;
            return $w / $h;
        }
    # Parse out decimal formats
        if ($aspect eq '1')        { return  1;     }
        elsif ($aspect =~ m/^1.3/) { return  4 / 3; }
        elsif ($aspect =~ m/^1.7/) { return 16 / 9; }
    # Unknown aspect
        return $aspect;
    }

my %info = nuv_info($ENV{'NUVINFOFILE'});
my $c = 0;
foreach my $key (split(' ', $ENV{'NUVINFOPROPS'})) {
	($c++ < 1) and print "$info{$key}" or print ":$info{$key}";
}
print "\n";
#ENDNUVINFO

###########################################################################################################
License Notes:
--------------

This software product is licensed under the GNU General Public License
(GPL). This license gives you the freedom to use this product and have
access to the source code. You can modify this product as you see fit
and even use parts in your own software. If you choose to do so, you
also choose to accept that a modified product or software that use any
code from mythnuv2mkv.sh MUST also be licensed under the GNU General Public
License.

In plain words, you can NOT sell or distribute mythnuv2mkv.sh, a modified
version or any software product based on any parts of mythnuv2mkv.sh as a
closed source product. Likewise you cannot re-license this product and
derivates under another license other than GNU GPL.

See also the article, "Free Software Matters: Enforcing the GPL" by
Eben Moglen. http://emoglen.law.columbia.edu/publications/lu-13.html
###########################################################################################################
