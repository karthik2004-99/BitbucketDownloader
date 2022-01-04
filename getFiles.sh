###########################################################
Help()
{
   # Display Help
   echo "getFiles.sh file is used to download the latest files from bitbucket."
   echo
   echo "Syntax: sh getFiles.sh [options] <u> <pat>"
   echo "user input:"
   echo "u   -Required    Enter username"
   echo "pat -Required    Enter your personal access token from bitbucket."
   echo
}


#############################################################
recursive_create() {
fullstring=$1
index=$2
level=$3
index_level_string=$4
items=( $(curl -s -u $fullstring | awk '{print $2"-"$4}') )
size=${#items[@]};
OLDIFS=$IFS
if [ $index -eq $size ]; then
    IFS=/; read -a reduced_path <<< "$fullstring"
    IFS=/; read -a reduced_level <<< "$index_level_string"
    IFS=$OLDIFS
    recreate_path=""
    for ((i=0; i<${#reduced_path[@]}-1; i++));
    do
    recreate_path=$recreate_path${reduced_path[i]}/
    done
    fullstring=$recreate_path

    index=${reduced_level[$level]}
    level=$((level-1))
    recreate_index=""
    for ((i=0; i<${#reduced_level[@]}-1; i++));
    do
    recreate_index=$recreate_index${reduced_level[i]}/
    done
    index_level_string=$recreate_index
  return
fi

if grep -q "blob" <<< ${items[index]}; then
   IFS=-; read -a file_array <<<"${items[index]}"
   IFS=$OLDIFS
   filename=${file_array[1]}
   tempstring=$fullstring$filename
   curl -s -O -u $tempstring

elif grep -q "tree" <<< ${items[index]}; then
   IFS=-; read -a folder_array <<<"${items[index]}"
   IFS=$OLDIFS
   foldername=${folder_array[1]}
   presentDir=$(pwd)
   dir=$presentDir/$foldername
   if [ ! -d "$dir" ]; then
        slash="/"
        tempstring=$fullstring$foldername$slash
        mkdir $foldername
        cd $foldername
        level=$((level+1))
        old_index=$index
        index_level_string=$index_level_string$old_index$slash

        recursive_create "$tempstring" 0 $level "$index_level_string"
        cd ..
   fi
fi
index=$((index+1))
recursive_create "$fullstring" $index $level "$index_level_string"


}
main() {

presentDir=$(pwd)
dir=$presentDir/bitbucketDownload
if [ ! -d "$dir" ]; then
  mkdir bitbucketDownload
  cd bitbucketDownload

  parentpath="" # Give the bitbucket repo link
  username=$1
  password=$2
  uspass=$username:$password
  fullpath=$username:$password" "$parentpath
  index_level_string=""
  recursive_create "$fullpath" 0 0 "$index_level_string"
else
  sudo rm -r bitbucketDownload
  main $1 $2
fi
}
############################################################################


while getopts "h" option; do
   case "${option}" in
      h) # display Help
         Help
         exit;;
   esac
done

if (( $OPTIND == 1 )); then
   echo "Getting latest files from Bitbucket"
   main $1 $2
   
   echo "Latest files have been downloaded."
fi
