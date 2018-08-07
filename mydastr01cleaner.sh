groupfolder=$1

arycfg=("win32_release" "win32_debug" "master" "linux32_release" "hpux32_release" "sol32_release" "partial_builds" "aix32_release")

remove_expired_folders()
{
    groupname=$1
    productname=$2
    configname=$3
    basedir=/products/${groupname}/${productname}/${configname}
    outputdir=/products/${groupname}
    if [ ! -d "${basedir}" ]; then
        echo "not existing config folder ${configname}"
        return
    fi
    find ${basedir}/ -maxdepth 1 -type l -printf "%f\n" > ${outputdir}/${productname}_${configname}_lk.txt
    find ${basedir}/ -maxdepth 1 -mtime +7 -type d -printf "%f\n" > ${outputdir}/${productname}_${configname}_dir.txt


    if [ -f ${outputdir}/${productname}_${configname}_keep_dir.txt ]; then
        rm -f ${outputdir}/${productname}_${configname}_keep_dir.txt
    fi
    while IFS='' read -r line || [[ -n "$line" ]]; do
        if [ "" != "$line" ]; then
            readlink ${basedir}/$line >> ${outputdir}/${productname}_${configname}_keep_dir.txt
        fi
    done < "${outputdir}/${productname}_${configname}_lk.txt"

    echo "keep the folders below:"
    cat  ${outputdir}/${productname}_${configname}_keep_dir.txt

    while IFS='' read -r line || [[ -n "$line" ]]; do
        findres=$(cat ${outputdir}/${productname}_${configname}_keep_dir.txt | grep ${line})
        if [ "${findres}" == "" ]; then
            echo ${line} >> ${outputdir}/${productname}_${configname}_remove_dir.txt
        fi 
    done < "${outputdir}/${productname}_${configname}_dir.txt"

    echo "folders will be removed! in ${groupname} ${productname} ${configname}"
    cat ${outputdir}/${productname}_${configname}_remove_dir.txt
}

find /products/${groupfolder}/* -type d -maxdepth 1 -printf "%f\n" | 
    while IFS='' read -r productfolder || [[ -n "$productfolder" ]]; do
        echo "product folder = ${productfolder}"
        if [ -d "/products/${groupfolder}/${productfolder}" ]; then
            for cfg in ${arycfg[@]}; do
                echo "config folder = ${cfg}"
                remove_expired_folders $groupfolder $productfolder $cfg
            done
        else        
            echo "not existing the product folder ${productfolder}"
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




