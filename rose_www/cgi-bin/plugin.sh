#!/bin/bash
# Supervised by Chunhua Liao, 
# Implemented by Manal Abdalla 3/22/2018

ROSE_INSTALL_PATH=/home/ubuntu/opt/rose_inst
# use a timestamp+pid to avoid file writting conflicts from multiple runs
TIMESTAMP=$(date +%Y%m%d_%H%M%S)
mypid="-${TIMESTAMP}-$$"

LOG_FILE=/tmp/plugin.sh.${mypid}.log

# we process the decoding of file content and write it to a file, not yet knowing its suffix
tmp_plugin0_nosuffix="/tmp/plugin0$mypid"
tmp_plugin_nosuffix="/tmp/plugin$mypid"
tmp_input0_nosuffix="/tmp/test0$mypid"
tmp_input_nosuffix="/tmp/test$mypid"


#------------------------------------------------------------------------------
# a function to display a file within a textarea
function display_code()
{
# automatically adjust line count
linecount=`wc -l $1 | cut -f 1 -d ' '`

#echo "Debug: in display_code(), linecount=$linecount for $1"

let "linecount+=2" # add a bit margin
echo "<textarea rows=\"$linecount\" cols=\"80\">"
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
       if [ "$k" == "plugin" ]; then
	  echo  "preprocessing plugin file ..." >> $LOG_FILE
	  cgi_decodevar "$v" > "$tmp_plugin0_nosuffix"
	  #echo "Debug: Input file is: "$tmp_input" <br />"
	  # preprocess the file content
	  # ^M is inputed by typing ctrl-v followed by ctrl-m
	  # replace ^M with \n 
	  sed -e "s//\n/g" "$tmp_plugin0_nosuffix" > "$tmp_plugin_nosuffix"
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
tmp_lib="/tmp/lib$mypid.cpp"
tmp_input="/tmp/test$mypid.$suffix"
# copy the naked decoded file without suffix into the input file with suffix
cp "$tmp_input_nosuffix" "$tmp_input"
cp "$tmp_plugin_nosuffix" "$tmp_lib"

# sed -e "s/^M/\n/g" test.c >test2.c
roseTranslator="$ROSE_INSTALL_PATH/bin/identityTranslator"

echo "debug: rosetool selected is: Plugin"  >> $LOG_FILE
#this is where the compiled plugin go
lib_so="/tmp/lib$mypid.so"
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
echo "<p>"
#echo "Target is a $suffix code <br />"
#echo "Action name is $action <br>"
#echo "Argument is $argument <br>"

# The Following are standard C++ compiler stuff
CXX=$(/home/ubuntu/opt/rose_inst/bin/rose-config cxx)
CPPFLAGS=$(/home/ubuntu/opt/rose_inst/bin/rose-config cppflags)
CXXFLAGS=$(/home/ubuntu/opt/rose_inst/bin/rose-config cxxflags)
LIBDIRS=$(/home/ubuntu/opt/rose_inst/bin/rose-config libdirs)
LDFLAGS=$(/home/ubuntu/opt/rose_inst/bin/rose-config ldflags)$(addprefix -Wl,-rpath -Wl,, subst :, , $LIBDIRS)

sooutputfile="/tmp/plugin.compilation.$mypid.$suffix"
Compile_so="$CXX -g $tmp_lib -fpic -shared $CPPFLAGS -I. $LDFLAGS -L. -o $lib_so &>$sooutputfile"
#echo "Plugin compilation command line:<br>"
#echo "${Compile_so}"
#echo "<br />"
#echo "<p>"

echo "debug and run ${Compile_so}" >> $LOG_FILE
eval ${Compile_so}
# must immediately check the error code
if [ $? -eq 0 ]
then
  echo "Plugin compilation succeeded with the following message (if any): <br>"
else  
  echo "Plugin compilation failed with the following message:<br>"
fi 
display_code "$sooutputfile"

outputfile="/tmp/rose_test$mypid.$suffix"
screenoutputfile="/tmp/test$mypid.$suffix.output"
Final_Command="$roseTranslator -c -rose:plugin_lib $lib_so -rose:plugin_action $action -rose:plugin_arg_${action} $argument -I. $tmp_input -rose:output $outputfile &>$screenoutputfile"

echo "debug: ${Final_Command}" >> $LOG_FILE
#gcc -E /tmp/test.$suffix -o /tmp/rose_test.$suffix
# be very carefull about the file and dir permission here
# the translator will write rose_*.c and *.o file to two places respectively
# cgi-bin for the .o file and /tmp for the output source file

echo  "start running the translator  ..." >> $LOG_FILE
echo  `date` >> $LOG_FILE

#echo "Plugin execution command line:<br>"
#echo "${Final_Command}"
#echo "<p>"
eval ${Final_Command}

# must immediately check the error code
if [ $? -eq 0 ]
then
  echo "Plugin execution succeeded with the following message (if any): <br>"
else  
  echo "Plugin execution failed with the following message (if any):<br>"
fi 

display_code "$screenoutputfile"

echo "Generated unparsed file (if any):<br>"
display_code "$outputfile"
echo "<br />"

echo  "Finished running the translator" >> $LOG_FILE
echo  `date` >> $LOG_FILE

#echo "Compilation message (empty if no warnings or errors): <br />"
#  echo "Log file is: /tmp/test.$suffix.output <br />"
#display_code "/tmp/test$mypid.$suffix.output"
#echo "return $? after running:  $roseTranslator -c /tmp/test.$suffix -rose:output /tmp/rose_test.$suffix &>/tmp/test.$suffix.output <br />" 

echo "<p>"
echo "Version of the translator used is:<br />"
$roseTranslator --version &>/tmp/rose$mypid.version
display_code "/tmp/rose$mypid.version"

echo "<p>"
echo "<button onclick=\"goBack()\">Go Back To Try Another One</button>"
echo "</body></html>"

