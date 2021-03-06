#!/bin/bash
#supervised  By Chunhua Liao, 
#implemented by intern Manal Abdalla 02/23/2018
# how large the form can handle 22,684 chars?
# 85,967 too large to handle
# common variables
ROSE_INSTALL_PATH=/home/ubuntu/opt/rose_inst/bin

# use a timestamp+pid to avoid file writting conflicts from multiple runs
TIMESTAMP=$(date +%Y%m%d_%H%M%S)
mypid="-${TIMESTAMP}-$$"

LOG_FILE=/tmp/help_page.sh.${mypid}.log

# we process the decoding of file content and write it to a file, not yet knowing its suffix
tmp_input0_nosuffix="/tmp/test0$mypid"
tmp_input_nosuffix="/tmp/test$mypid"

# make sure the directory exist

DIR="/tmp/man_pages"

if [ -d "$DIR" ]; then
 rm -rf "$DIR"
 mkdir "$DIR"
else
 mkdir "$DIR"
fi

#------------------------------------------------------------------------------
# a function to display a file within a textarea
function display_code()
{
# automatically adjust line count
linecount=`wc -l $1 | cut -f 1 -d ' '`

#echo "Debug: in display_code(), linecount=$linecount for $1"

let "linecount+=2" # add a bit margin
echo "<textarea rows=\"$linecount\" cols=\"80\" style=\"width:100%\">"
# space sensitive here: '=' must immediately follow 'IFS' !
# otherwise it does not work!
# not sure why?
while IFS= read -r line
do
   echo "$line"
done < "$1"  

echo "</textarea><br>"
}

#------------------------------------------------------------------------------
#This code for getting code from post data is from http://oinkzwurgl.org/bash_cgi and
#was written by Phillippe Kehi <phkehi@gmx.net> and flipflip industries

# (internal) routine to store POST data
function cgi_get_POST_vars()
{
#   echo "debug begin of cgi_get_POST_vars()  " >> $LOG_FILE
    # check content type
    # FIXME: not sure if we could handle uploads with this..
    [ "${CONTENT_TYPE}" != "application/x-www-form-urlencoded" ] && \
	echo "Warning: you should probably use MIME type "\
	     "application/x-www-form-urlencoded!" 1>&2

    # save POST variables (only first time this is called)
    # read will obtain the standard input from the post data
    [ -z "$QUERY_STRING_POST" \
      -a "$REQUEST_METHOD" = "POST" -a ! -z "$CONTENT_LENGTH" ] && \
	read -n $CONTENT_LENGTH QUERY_STRING_POST

    echo "debug cgi_get_POST_vars () read $CONTENT_LENGTH bytes into $QUERY_STRING_POST" >> $LOG_FILE    
    return
}

# (internal) routine to decode urlencoded strings
# space is + in URL encoded string
# convert input paramter into 
function cgi_decodevar()
{
    [ $# -ne 1 ] && return
    local v t h
    # replace all + with whitespace and append %%
    t="${1//+/ }%%"
    while [ ${#t} -gt 0 -a "${t}" != "%" ]; do
	v="${v}${t%%\%*}" # digest up to the first %
	t="${t#*%}"       # remove digested part
	# decode if there is anything to decode and if not at end of string
	if [ ${#t} -gt 0 -a "${t}" != "%" ]; then
	    h=${t:0:2} # save first two chars
	    t="${t:2}" # remove these
	    v="${v}"`echo -e \\\\x${h}` # convert hex to special char
	fi
    done
    # return decoded string
    echo "${v}"
    echo "debug cgi_decodevar () result ${v}">> $LOG_FILE 
    return
}

# routine to get variables from http requests
# usage: cgi_getvars method varname1 [.. varnameN]
# method is either GET or POST or BOTH
# the magic varible name ALL gets everything
function cgi_getvars()
{
    echo "debug cgi_getvars() starts ... ">> $LOG_FILE 
    [ $# -lt 2 ] && return
    local q p k v s
    # get query
    case $1 in
	GET)
	    [ ! -z "${QUERY_STRING}" ] && q="${QUERY_STRING}&"
	    ;;
	POST)
	    cgi_get_POST_vars
	    [ ! -z "${QUERY_STRING_POST}" ] && q="${QUERY_STRING_POST}&"
	    ;;
	BOTH)
	    [ ! -z "${QUERY_STRING}" ] && q="${QUERY_STRING}&"
	    cgi_get_POST_vars
	    [ ! -z "${QUERY_STRING_POST}" ] && q="${q}${QUERY_STRING_POST}&"
	    ;;
    esac
# shift parameters by 1, 2nd parameter becomes the 1st one now
    shift
    s=" $* "
    # parse the query data stored in q
    while [ ! -z "$q" ]; do
	p="${q%%&*}"  # get first part of query string
	k="${p%%=*}"  # get the key (variable name) from it
	v="${p#*=}"   # get the value from it
	q="${q#$p&*}" # strip first part from query string

        echo "    extracted raw: $k = $v">> $LOG_FILE 
	# decode and evaluate var if requested
	[ "$1" = "ALL" -o "${s/ $k /}" != "$s" ] && \
	    eval "$k=\"`cgi_decodevar \"$v\"`\""

# special handling for large size file content
# buildin processing of lage file content, instead of doing it outside of the function call.    
       if [ "$k" == "filecontent" ]; then
         #echo "${v}" > "$tmp_input0"
# key=value method cannot handle large size file content somehow.
# we decode $v again and direct the content into a file now
#         echo "${filecontent}" > "$tmp_input0_nosuffix"
         echo  "preprocessing input file ..." >> $LOG_FILE
         cgi_decodevar "$v" > "$tmp_input0_nosuffix"
         #echo "Debug: Input file is: "$tmp_input" <br />"
          # preprocess the file content
          #  is inputed by typing ctrl-v followed by ctrl-m
          # replace  with \n 
          sed -e "s//\n/g" "$tmp_input0_nosuffix" > "$tmp_input_nosuffix"
       fi 
    done
    echo "debug cgi_getvars() ends ... ">> $LOG_FILE 
    return
}

#------------------------------------------------------------------------------
start_time=`date`
echo  $start_time >> $LOG_FILE
# change the current directory to /tmp, to avoid file permission problem
cd /tmp
#rm -f /tmp/rose_test*.$suffix

# register all GET and POST variables
#cgi_getvars BOTH ALL
# decode all key-value pair in the post data
# filecontent, suffix,  sub
cgi_getvars POST ALL

echo "Content-type: text/html"
echo ""
# suffix is only defined after processing post data!!
tmp_input="/tmp/test$mypid.$suffix"
# copy the naked decoded file without suffix into the input file with suffix
cp "$tmp_input_nosuffix" "$tmp_input"
# sed -e "s/^M/\n/g" test.c >test2.c
if [ "$tool" == "OpenMPLowering" ]
then
    tool="identityTranslator"
    options+="-rose:OpenMP:lowering"
fi
if [ "$tool" == "autoPar" ]
then
    PATH=/home/ubuntu/opt/jvm/jdk1.7.0_51/bin:$PATH
    LD_LIBRARY_PATH=$LD_LIBRARY_PATH:/home/ubuntu/opt/jvm/jdk1.7.0_51/jre/lib/amd64/server:/home/ubuntu/opt/jvm/jdk1.7.0_51/lib
    export PATH LD_LIBRARY_PATH
    export LD_LIBRARY_PATH=/home/ubuntu/opt/boost/1.61.0/gcc-4.9.3-default/lib:$LD_LIBRARY_PATH
    alias zgrviewer='/home/ubuntu/opt/zgrviewer-0.10.0/run.sh'
    export PATH=$PATH:/home/ubuntu/opt/rose_inst/bin
fi

roseTranslator="$ROSE_INSTALL_PATH/${tool}"

echo "debug: rosetool selected is: $roseTranslator"  >> $LOG_FILE
#------------------------------------------------------------------------------
echo "<html><head>"
echo "<script>"
echo "function goBack() {"
echo "      window.history.back();"
echo "} "
echo "</script>"
echo "<title>Execution results:</title>"
echo "</head>"

echo "<body>"
echo "Manual Page for $tool <br>"

Final_Command="$roseTranslator --help &> /tmp/man_pages/manual_${tool}.txt"

echo "debug: ${Final_Command}" >> $LOG_FILE
echo  "start running the translator  ..." >> $LOG_FILE
echo  `date` >> $LOG_FILE
eval ${Final_Command}
echo  "Finished running the translator" >> $LOG_FILE
echo  `date` >> $LOG_FILE

display_code "/tmp/man_pages/manual_${tool}.txt"

echo "</body></html>"

