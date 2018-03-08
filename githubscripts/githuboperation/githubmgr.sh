#!/bin/bash 

get_ref_sha()
{
    orgname=$1
    reponame=$2
    reftype=$3
    refname=$4
    repourl="https://${GITHUB_SERVER}/api/v3/repos/${orgname}/${reponame}/git/refs/${reftype}/${refname}"
    shacode=$(curl -s -H "Authorization: token ${GITHUB_USER_TOKEN}" -L ${repourl} | jq -r .object.sha)
    if [ "null" == "${shacode}" ]; then
        return 1
    fi
    echo $shacode
    return 0
} 

delete_ref() 
{
    orgname=$1
    reponame=$2
    reftype=$3
    refname=$4
    repourl="https://${GITHUB_SERVER}/api/v3/repos/${orgname}/${reponame}/git/refs/${reftype}/${refname}"
    rspcode=$(curl -s -o nul -w "%{http_code}" -H "Authorization: token ${GITHUB_USER_TOKEN}" -L ${repourl})
    # check whether ref exists or not 
    if [ "200" == "${rspcode}" ]; then
        rspcode=$(curl -s -w "%{http_code}" -H "Authorization: token ${GITHUB_USER_TOKEN}" --request DELETE -L "${repourl}")
        if [ "204" != "${rspcode}" ]; then 
            echo "Delete ${reponame} ref ${refname} error - ${rspcode}"
        fi
        echo "Delete ${reponame} ref ${refname} successfully"
    elif [ "404" == "${rspcode}" ]; then  
        #########################################################################
        #				ref doesn't exist
        #########################################################################
        echo "${reponame} Ref ${refname} doesn't exist"
    else
        echo "Query ${reponame} ref ${refname} error"
        return 1
    fi  
    return 0
}

update_and_create_ref_by_sha()
{
    orgname=$1
    reponame=$2
    reftype=$3
    refname=$4
    shacode=$5
    #########################################################################
    #				Check whethere ref exists
    #########################################################################
    repourl="https://${GITHUB_SERVER}/api/v3/repos/${orgname}/${reponame}/git/refs/${reftype}/${refname}"
    rspcode=$(curl -s -o nul -w "%{http_code}" -H "Authorization: token ${GITHUB_USER_TOKEN}" -L ${repourl})
    if [ "200" == "${rspcode}" ]; then
    #########################################################################
    #				Update ref with commit
    #########################################################################
        reqdata="{\"sha\": \"${shacode}\", \"force\": true}"
        rspcode=$(curl -s -o nul -w "%{http_code}" -H "Authorization: token ${GITHUB_USER_TOKEN}" --request PATCH -L "${repourl}" -d "${reqdata}")
        if [ "200" != "${rspcode}" ]; then 
            echo "Update ${reponame} ref error - ${rspcode}"
            return 1
        fi
        echo "Update ${reponame} ref ${refname} successfully"
        return 0
    elif [ "404" == "${rspcode}" ]; then
    #########################################################################
    #				Create a ref
    #########################################################################
        reqdata="{\"ref\": \"refs/${reftype}/${refname}\", \"sha\": \"${shacode}\"}"
        repourl="https://${GITHUB_SERVER}/api/v3/repos/${orgname}/${reponame}/git/refs"
        rspcode=$(curl -s -o nul -w "%{http_code}" -H "Authorization: token ${GITHUB_USER_TOKEN}" --request POST -L "${repourl}" -d "${reqdata}")
        if [ "201" != "${rspcode}" ]; then 
            echo "Create ${reponame} ref ${refname} error"
            return 1
        fi
        echo "Create ${reponame} ref ${refname} successfully"
        return 0
    else
        echo "Query ${reponame} ref ${refname} error - ${rspcode}"
        return 1
    fi
    return 0
}

update_and_create_ref_by_srctag()
{
    orgname=$1
    reponame=$2
    reftype=$3
    refname=$4
    srctagtype=$5
    srctag=$6

    shacode=$(get_ref_sha $orgname $reponame $srctagtype $srctag)    
    ret=$?

    if [ 0 != $ret ]; then
        return 1
    fi
    update_and_create_ref_by_sha $orgname $reponame $reftype $refname $shacode
    return $?
}