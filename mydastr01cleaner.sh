groupfolder=$1

arycfg=("win32_release" "win32_debug" "master" "linux32_release" "hpux32_release" "sol32_release" "partial_builds" "aix32_release")

remove_expired_folders()
{
    groupname=$1
    productname=$2
    configname=$3
    basedir=/products/${groupname}/${productname}/${configname}
    if [ ! -d "${basedir}" ]; then
        echo "not existing ${basedir}"
        return
    fi
    find ${basedir}/ -maxdepth 1 -type l -printf "%f\n" > ${productname}_${configname}_lk.txt
    find ${basedir}/ -maxdepth 1 -mtime +7 -type d -printf "%f\n" > ${productname}_${configname}_dir.txt


    if [ -f ${productname}_${configname}_keep_dir.txt ]; then
        rm -f ${productname}_${configname}_keep_dir.txt
    fi
    while IFS='' read -r line || [[ -n "$line" ]]; do
        echo $line
        if [ "" != "$line" ]; then
            readlink ${basedir}/$line >> ${productname}_${configname}_keep_dir.txt
        fi
    done < "${productname}_${configname}_lk.txt"


    while IFS='' read -r line || [[ -n "$line" ]]; do
        findres=$(cat ${productname}_${configname}_keep_dir.txt | grep ${line})
        if [ "${findres}" == "" ]; then
            echo ${line} >> ${productname}_${configname}_remove_dir.txt
        fi 
    done < "${productname}_${configname}_dir.txt"

    echo "folders will be removed! in ${groupname} ${productname} ${configname}"
    cat ${productname}_${configname}_remove_dir.txt
}

find /products/${groupfolder}/* -type d -maxdepth 1 -printf "%f\n" | 
    while IFS='' read -r productfolder || [[ -n "$productfolder" ]]; do
        echo "productfolder = ${productfolder}"
        if [ -d "/products/${groupfolder}/${productfolder}" ]; then
            for cfg in ${arycfg[@]}; do
                echo "config folder = ${cfg}"
                remove_expired_folders $groupfolder $productfolder $cfg
            done
        fi   
    done
# for productfolder in $(find /products/${groupfolder}/* -type d -maxdepth 1 -printf "%f\n"); do
#     if [ -d "${productfolder}" ]; then
#         echo "productfolder = ${productfolder}"
#         for cfg in ${arycfg[@]}; do
#             echo "config folder = ${cfg}"
#             remove_expired_folders $groupfolder $productfolder $cfg
#         done
#     fi
# done




