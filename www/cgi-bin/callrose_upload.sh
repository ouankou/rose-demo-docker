#!/bin/bash
# Supervised By Chunhua Liao, 
# Implemented by Manal Abdalla 02/28/2018

ROSE_INSTALL_PATH=/home/ubuntu/opt/rose_inst/bin

# use a timestamp+pid to avoid file writting conflicts from multiple runs
TIMESTAMP=$(date +%Y%m%d_%H%M%S)
mypid="-${TIMESTAMP}-$$"

LOG_FILE=/tmp/callrose_upload.sh.${mypid}.log

# we process the decoding of file content and write it to a file, not yet knowing its suffix
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
# This code will take the query string for post method and stor it in POST_DATA
if [ "$REQUEST_METHOD" = "POST" ]; then
    if [ "$CONTENT_LENGTH" -gt 0 ]; then
        read -N $CONTENT_LENGTH POST_DATA <&0
    else
        echo " POST_DATA string is empty \n " >> $LOG_FILE
    fi
else
    echo "form method must be POST \n " >> $LOG_FILE
fi
# the following will write the content of POST_DATA to tmp_input0_nosuffix
(
    echo "$POST_DATA" | while read line
    do
        echo "$line"
    done
 ) > $tmp_input0_nosuffix
# the following will extract the suffix and the options from tmp_input0_nosuffix
linecount=`cat $tmp_input0_nosuffix | wc -l $1 | cut -f 1 -d ' '`
# this will extract the suffix from the file name given in form
suff=`sed -n "2p" "$tmp_input0_nosuffix" | sed -e "s//\n/g" | awk -F";" '{ print $NF}' | awk -F"=" '{ print $NF}'`
suffi=${suff##*.}
suffix=`echo $suffi | cut -f1 -d"\""`
echo "suffix extracted $suffix \n" >>$LOG_FILE
# this will extract the tool options if given
NUM=`expr $linecount - 10`
options=`sed "${NUM}q;d" "$tmp_input0_nosuffix" | sed -e "s//\n/g"`
echo "options extracted $options \n" >> $LOG_FILE
# This will extract the tool
NUM=`expr $linecount - 6`
tool=`sed "${NUM}p;d" "$tmp_input0_nosuffix" | sed -e "s//\n/g"`
echo "tool extracted $tool \n" >> $LOG_FILE
# this will extarctt file content to a file
NUM=`expr $linecount - 14`
sed -n "5,${NUM}p" "$tmp_input0_nosuffix" | sed -e "s//\n/g" > "$tmp_input_nosuffix"
echo "source code extracted \n" >> $LOG_FILE


#------------------------------------------------------------------------------
start_time=`date`
echo  $start_time >> $LOG_FILE
# change the current directory to /tmp, to avoid file permission problem
cd /tmp
#rm -f /tmp/rose_test*.$suffix

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
roseTranslator="$ROSE_INSTALL_PATH/$tool"

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
echo "<p>"
echo "Selected file suffix is $suffix<br />"
echo "Added options: $options <br>"

TOOL_FLAGS=""

if [ "$suffix" == "cpp" ]; then
  TOOL_FLAGS+="-std=c++11"
fi

Final_Command="$roseTranslator $options ${TOOL_FLAGS} -c /tmp/test${mypid}.${suffix} -rose:output /tmp/rose_test$mypid.$suffix &>/tmp/test$mypid.$suffix.output"

echo "debug: ${Final_Command}" >> $LOG_FILE
#gcc -E /tmp/test.$suffix -o /tmp/rose_test.$suffix
# be very carefull about the file and dir permission here
# the translator will write rose_*.c and *.o file to two places respectively
# cgi-bin for the .o file and /tmp for the output source file

echo  "start running the translator  ..." >> $LOG_FILE
echo  `date` >> $LOG_FILE

eval ${Final_Command}

# must immediately check the error code
if [ $? -eq 0 ]
then
  echo "Compilation is successful!<br>"
  PROCESSED=`cat /tmp/rose_test$mypid."$suffix"`
  outputfile="/tmp/rose_test$mypid.$suffix"
  if [ $tool == "dotGenerator" ]
  then
      dot -Tpng test$mypid.$suffix.dot -o /tmp/test$mypid.png
      dot -Tpdf test$mypid.$suffix.dot -o /tmp/test$mypid.pdf
      echo "Available formats of DotGenerator tool: <br>"
      echo "<a href=\"/imgs/test$mypid.png\" target=\"_blank\">.PNG</a> "
      echo "<a href=\"/imgs/test$mypid.pdf\" target=\"_blank\">.PDF</a> "
      echo"<p>"
  elif [ $tool == "dotGeneratorWholeASTGraph" ]
  then
      dot -Tpng test$mypid.${suffix}_WholeAST.dot -o /tmp/test${mypid}_WholeAST.png
      dot -Tpdf test$mypid.${suffix}_WholeAST.dot -o /tmp/test${mypid}_WholeAST.pdf
      echo "Available formats of the dotGeneratorWholeASTGraph tool: <br>"
      echo "<a href=\"/imgs/test${mypid}_WholeAST.png\" target=\"_blank\">.PNG</a> "
      echo "<a href=\"/imgs/test${mypid}_WholeAST.pdf\" target=\"_blank\">.PDF</a> "
      echo "<p>"
  elif [ $tool == "pdfGenerator" ]
  then
      echo "Available formats of pdfGenerator tool: <br>"
      echo "<a href=\"/imgs/test$mypid.$suffix.pdf\" target=\"_blank\">Bookmarked .PDF</a> "
      echo "<p>"
  elif [ $tool == "buildCallGraph" ]
  then
      dot -Tpng test$mypid.${suffix}_callGraph.dot -o /tmp/test${mypid}_callGraph.png
      dot -Tpdf test$mypid.${suffix}_callGraph.dot -o /tmp/test${mypid}_callGraph.pdf
      echo "Available formats for callGraphGenerator tool: <br>"
      echo "<a href=\"/imgs/test${mypid}_callGraph.png\" target=\"_blank\">.PNG</a> "
  
      echo "<a href=\"/imgs/test${mypid}_callGraph.pdf\" target=\"_blank\">.PDF</a> "
      echo "<p>"
#display_code "/tmp/test$mypid.$suffix"
  else 
      echo "Output file is:<br />"
      # reading and output a file using bash
      echo "Processed input (also available for <a href=\"${outputfile}\" download>download</a>)<br> "
      display_code "/tmp/rose_test$mypid.$suffix"
  fi
else  
  echo "Compilation failed!"
fi 
echo "<br />"

echo  "Finished running the translator" >> $LOG_FILE
echo  `date` >> $LOG_FILE

echo "Compilation message (empty if no warnings or errors): <br />"
#  echo "Log file is: /tmp/test.$suffix.output <br />"
display_code "/tmp/test$mypid.$suffix.output"
#echo "return $? after running:  $roseTranslator -c /tmp/test.$suffix -rose:output /tmp/rose_test.$suffix &>/tmp/test.$suffix.output <br />" 

echo "<p>"
echo "Version of the translator used is:<br />"
$roseTranslator --version &>/tmp/rose$mypid.version
display_code "/tmp/rose$mypid.version"

echo "<p>"
echo "<button onclick=\"goBack()\">Go Back To Try Another One</button>"
echo "</body></html>"

