#!/app/sd/app/bash

folder=$1
output=$2

for file in $(find $folder -type f) ; do
  echo "Catting file ${file}"

  echo "#### FILE START ####" >> $output
  echo ${file} >> $output
  echo " " >> $output
  cat ${file} >> $output
  echo "#### FILE END ####" >> $output
  echo " " >> $output


done
