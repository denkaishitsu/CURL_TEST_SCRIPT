#!bin/bash -evx

##############################
#
# watson conversationに対して、QAログを取得するスクリプト
#
# 引数
#   $1:Qデータ(.csv)
#   $2:Host
#   $3:上記QデータのQuestionの列の位置[デフォルト1]
#
#############################

echo 'start script'
start_time=`date +%s`

#LOG Dir
if [ -e QA_LOG ]; then
  :
else
  mkdir QA_LOG
fi

#LOG
ERR_LOG=ERR_LOG.$(basename $0).$(date +%Y%m%d).$(date +%H%M%S).$$
exec 2> QA_LOG/$ERR_LOG

#Arguments
DATA=$1
HOST=$2
COL=${3:-1}

#OUTPUT
RESULTS=RESULT.$(basename $0).$(date +%Y%m%d).$(date +%H%M%S).$$.csv

#Add conma to data file each row's end
cat ${DATA} | awk -F"," '{print(sprintf("%s,''", $0))}' > TMP_INPUT_DATA

#Read Data file
while read line
do
  QUEST=$(echo ${line}                        | 
        sed 's/"//g'                          | 
        awk -v col=$COL -F',' '{print $col}'  )
  Q=$(echo ${QUEST} | perl -MURI::Escape -lne 'print uri_escape($_)' | sed 's/\n//g')
  if [ "${HOST}" = "localhost" ]; then
    ANSWER=$(curl localhost:8080/cv1/curl_test?text=${Q})
  else
    ANSWER=$(curl https://${HOST}/cv1/curl_test?text=${Q})
  fi
  A=$(echo $ANSWER | tr '\n' '|||')
  echo $A | sed -e 's/|//g' >> QA_LOG/${RESULTS}
  wait $!
  echo $Q | perl -MURI::Escape -lne 'print uri_unescape($_)'
  echo $A
done < TMP_INPUT_DATA

if [ -z "$(cat QA_LOG/${ERR_LOG})" ]; then 
  rm -f QA_LOG/ERR_LOG
fi

rm -f TMP_INPUT_DATA

end_time=`date +%s`
time=$((end_time - start_time))

echo "Time:"$time
echo "finish script"

exit 0 
