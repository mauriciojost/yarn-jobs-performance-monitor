#!/bin/bash

CURL="curl -s -f"
CONFIG_FILE=$1

source $CONFIG_FILE

NEW_LINE='<br>'

TABLE_BEGIN='<table class="table table-striped">'
    TABLE_HEAD_BEGIN='<thead class="thead-inverse">'
        TABLE_ROW_BEGIN='<tr>'
            TABLE_HEAD_LABEL_BEGIN='<th>'
            TABLE_HEAD_LABEL_END='</th>'
            # ...
        TABLE_ROW_END='</tr>'
    TABLE_HEAD_END='</thead>'
    TABLE_BODY_BEGIN='<tbody>'
        #TABLE_ROW_BEGIN
            TABLE_BODY_VALUE_BEGIN='<td>'
            TABLE_BODY_VALUE_END='</td>'
            # ...
        #TABLE_ROW_END
    TABLE_BODY_END='</tbody>'
TABLE_END='</table>'

function retrieve-job-executions-details() {

  export JOB_ID=$1
  JENKINS_JOB_URL_BASE=$JENKINS_URL_BASE/$JOB_ID
  LOG_DIR=logs/$JOB_ID/
  OUT_DIR=output
  OUT_HTML=$OUT_DIR/$JOB_ID.html

  rm -fr $LOG_DIR
  mkdir -p $LOG_DIR
  mkdir -p $OUT_DIR

  export TITLE=$JOB_ID

  cat html/header.html | envsubst > $OUT_HTML

  echo "$TABLE_BEGIN" >> $OUT_HTML
  echo "$TABLE_HEAD_BEGIN" >> $OUT_HTML
  echo "$TABLE_ROW_BEGIN" >> $OUT_HTML

    echo "$TABLE_HEAD_LABEL_BEGIN" >> $OUT_HTML
    echo "DATE" >> $OUT_HTML
    echo "$TABLE_HEAD_LABEL_END" >> $OUT_HTML

    echo "$TABLE_HEAD_LABEL_BEGIN" >> $OUT_HTML
    echo "LINKS" >> $OUT_HTML
    echo "$TABLE_HEAD_LABEL_END" >> $OUT_HTML

    echo "$TABLE_HEAD_LABEL_BEGIN" >> $OUT_HTML
    echo "APP" >> $OUT_HTML
    echo "$TABLE_HEAD_LABEL_END" >> $OUT_HTML

    echo "$TABLE_HEAD_LABEL_BEGIN" >> $OUT_HTML
    echo "MB-SECONDS" >> $OUT_HTML
    echo "$TABLE_HEAD_LABEL_END" >> $OUT_HTML

    echo "$TABLE_HEAD_LABEL_BEGIN" >> $OUT_HTML
    echo "VCORE-SECONDS" >> $OUT_HTML
    echo "$TABLE_HEAD_LABEL_END" >> $OUT_HTML

    echo "$TABLE_HEAD_LABEL_BEGIN" >> $OUT_HTML
    echo "SETTINGS" >> $OUT_HTML
    echo "$TABLE_HEAD_LABEL_END" >> $OUT_HTML

  echo "$TABLE_ROW_END" >> $OUT_HTML
  echo "$TABLE_HEAD_END" >> $OUT_HTML

  echo "$TABLE_BODY_BEGIN" >> $OUT_HTML
  export CHART_VCORES=""
  export CHART_MB=""
  for i in `seq $TO_JOB -1 $FROM_JOB`;
  do
    JENKINS_JOB_URL=$JENKINS_JOB_URL_BASE/$i/consoleFull
    $CURL $JENKINS_JOB_URL > $LOG_DIR/$i.jenkins.log
    TRACKING_URL_LINE=`cat $LOG_DIR/$i.jenkins.log | grep "tracking URL"`
    TRACKING_URL=`echo $TRACKING_URL_LINE | sed "s/.*'\(.*\)'.*/\1/"`
    YARN_JOB_ID=`echo $TRACKING_URL | sed "s/.*\(application.*\)\/.*/\1/"`
    if [ "$YARN_JOB_ID" != "" ]
    then
      echo "$TABLE_ROW_BEGIN" >> $OUT_HTML

      echo "$TABLE_BODY_VALUE_BEGIN" >> $OUT_HTML # DATE
      cat $LOG_DIR/$i.jenkins.log | grep "UTC 20" >> $OUT_HTML
      echo "$TABLE_BODY_VALUE_END" >> $OUT_HTML

      echo "$TABLE_BODY_VALUE_BEGIN" >> $OUT_HTML # LINKS
      echo "<a href=\"$JENKINS_JOB_URL\">Jenkins</a>" >> $OUT_HTML
      echo "$NEW_LINE" >> $OUT_HTML
      echo "<a href=\"$TRACKING_URL\">Yarn</a>" >> $OUT_HTML
      echo "$TABLE_BODY_VALUE_END" >> $OUT_HTML

      echo "$TABLE_BODY_VALUE_BEGIN" >> $OUT_HTML # APP
      YARN_JOB_URL=$YARN_JOB_URL_BASE/$YARN_JOB_ID
      $CURL $YARN_JOB_URL >> $LOG_DIR/$i.yarn.log
      cat $LOG_DIR/$i.jenkins.log | grep "++ PROJECT=" | sed "s/++ PROJECT=//" >> $OUT_HTML
      echo "$NEW_LINE" >> $OUT_HTML
      cat $LOG_DIR/$i.jenkins.log | grep "++ VERSION=" | sed "s/++ VERSION=//" >> $OUT_HTML
      echo "$NEW_LINE" >> $OUT_HTML
      cat $LOG_DIR/$i.jenkins.log | grep "+ CLASS=" | sed "s/+ CLASS=//" >> $OUT_HTML
      echo "$NEW_LINE" >> $OUT_HTML
      echo "$TABLE_BODY_VALUE_END" >> $OUT_HTML

      echo "$TABLE_BODY_VALUE_BEGIN" >> $OUT_HTML # MB-SECONDS
      MB_SECONDS=`cat $LOG_DIR/$i.yarn.log | grep vcore |  sed "s/\W*\([0-9]*\) MB-seconds.*/\1/"`
      echo $MB_SECONDS >> $OUT_HTML
      echo "$TABLE_BODY_VALUE_END" >> $OUT_HTML

      if [ "$MB_SECONDS" != "" ]
      then
          export CHART_MB="[$i, $MB_SECONDS], $CHART_MB"
      fi

      echo "$TABLE_BODY_VALUE_BEGIN" >> $OUT_HTML # VCORE-SECONDS
      VCORE_SECONDS=`cat $LOG_DIR/$i.yarn.log | grep vcore |  sed "s/.*, \([0-9]*\) vcore-seconds.*/\1/"`
      echo $VCORE_SECONDS >> $OUT_HTML
      echo "$TABLE_BODY_VALUE_END" >> $OUT_HTML

      if [ "$VCORE_SECONDS" != "" ]
      then
          export CHART_VCORES="[$i, $VCORE_SECONDS], $CHART_VCORES"
      fi

      echo "$TABLE_BODY_VALUE_BEGIN" >> $OUT_HTML # SETTINGS
      cat $LOG_DIR/$i.jenkins.log | grep "spark.executor.instances" >> $OUT_HTML
      echo "$NEW_LINE" >> $OUT_HTML
      cat $LOG_DIR/$i.jenkins.log | grep "spark.executor.cores" >> $OUT_HTML
      echo "$TABLE_BODY_VALUE_END" >> $OUT_HTML

      echo "$TABLE_ROW_END" >> $OUT_HTML

    fi

  done
  echo "$TABLE_BODY_END" >> $OUT_HTML
  echo "$TABLE_END" >> $OUT_HTML

  cat html/tail.html | envsubst  >> $OUT_HTML

  echo ""
  echo "Generated: $JOB_ID $JENKINS_THIS_JOB_WORKSPACE_URL/$OUT_HTML"
  echo ""

}

for job_id in $JOB_IDS
do
  retrieve-job-executions-details $job_id
done

