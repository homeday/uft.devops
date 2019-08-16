groupfolder=$1

arycfg=("win32_release" "win32_debug" "master" "mac" "Linux" "linux32_release" "hpux32_release" "sol32_release" "partial_builds" "aix32_release")
ignoreprods="@LT-PCQC@LT-PCQC-FIST@"


search_ignore_list() 
{
    productname=$1
    ignoreprods=("LT-PCQC" "LT-PCQC-FIST" "LeanFT")
	#ignoreprods=("LT-PCQC" "LT-PCQC-FIST")

    for ignoreprod in "${ignoreprods[@]}"; do
        if [[ "$productname" == "$ignoreprod" ]]; then
            return 1
        fi
    done    

    return 0
}

remove_expired_folders()
{
    groupname=$1
    productname=$2
    configname=""
	if [ $# -gt 3 ]; then
		configname=$3
		basedir=/products/${groupname}/${productname}/${configname}
	else
		basedir=/products/${groupname}/${productname}
	fi
	
	echo "basedir = ${basedir}"
    outputdir=/products/${groupname}
    if [ ! -d "${basedir}" ]; then
        echo "not existing config folder ${configname}"
        return
    fi
    find ${basedir}/ -maxdepth 1 -mindepth 1 -type l -printf "%f\n" > ${outputdir}/${productname}_${configname}_lk.txt
    find ${basedir}/ -maxdepth 1 -mindepth 1 -mtime +7 -type d -name '*[0-9]' -printf "%f\n" | grep '[0-9]\{1,2\}.[0-9]\{1,4\}.[0-9]\{1,4\}' > ${outputdir}/${productname}_${configname}_dir.txt


    if [ -f ${outputdir}/${productname}_${configname}_keep_dir.txt ]; then
        rm -f ${outputdir}/${productname}_${configname}_keep_dir.txt
    fi
    if [ -f ${outputdir}/${productname}_${configname}_remove_dir.txt ]; then
        rm -f ${outputdir}/${productname}_${configname}_remove_dir.txt
    fi
    while IFS='' read -r line || [[ -n "$line" ]]; do
        if [ "" != "$line" ]; then
            readlink ${basedir}/$line >> ${outputdir}/${productname}_${configname}_keep_dir.txt
        fi
    done < "${outputdir}/${productname}_${configname}_lk.txt"

    #echo "keep the folders below:"
    #cat  ${outputdir}/${productname}_${configname}_keep_dir.txt

    while IFS='' read -r line || [[ -n "$line" ]]; do
        findres=
        if [ -f "${outputdir}/${productname}_${configname}_keep_dir.txt" ]; then
            findres=$(cat ${outputdir}/${productname}_${configname}_keep_dir.txt | grep ${line})
        fi
        if [ "${findres}" == "" ]; then
            echo ${line} >> ${outputdir}/${productname}_${configname}_remove_dir.txt
        fi 
    done < "${outputdir}/${productname}_${configname}_dir.txt"
    #echo "removing ${groupname} ${productname} ${configname}"
    if [ -f ${outputdir}/${productname}_${configname}_remove_dir.txt ]; then
        while IFS='' read -r line || [[ -n "$line" ]]; do
            if [ -d ${basedir}/${line} ]; then
                echo "removing ${basedir}/${line}"
                rm -rf ${basedir}/${line}
            fi
        done < "${outputdir}/${productname}_${configname}_remove_dir.txt"
    fi
    
}

if [ "${groupfolder}" == "FT" ]; then
	echo "FT group"
	find /products/${groupfolder}/CDLS-TOOLS -maxdepth 1 -mindepth 1 -type d -printf "%f\n" | 
		while IFS='' read -r productfolder || [[ -n "$productfolder" ]]; do
			echo "product folder = ${productfolder}"
			if  [ -d "/products/${groupfolder}/CDLS-TOOLS/${productfolder}" ]; then
				remove_expired_folders $groupfolder $productfolder ""
			else        
				echo "not existing the product folder ${productfolder} or ignore it"
			fi   
		done
	echo "FT group end"
fi


find /products/${groupfolder}/ -maxdepth 1 -mindepth 1 -type d -printf "%f\n" | 
    while IFS='' read -r productfolder || [[ -n "$productfolder" ]]; do
        echo "product folder = ${productfolder}"
        #isignore=$(echo $ignoreprods | grep ${productfolder})
        search_ignore_list ${productfolder}
        if [ "$?" == "0" ] && [ -d "/products/${groupfolder}/${productfolder}" ]; then
            for cfg in ${arycfg[@]}; do
                echo "config folder = ${cfg}"
                remove_expired_folders $groupfolder $productfolder $cfg
            done
        else        
            echo "not existing the product folder ${productfolder} or ignore it"
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




