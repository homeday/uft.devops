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

update_and_create_branch_by_sha()
{
    orgname=$1
    reponame=$2
    reftype=$3
    refname=$4
    shacode=$5    
    if [ ! "heads" == "$reftype" ]; then
        echo "Warning: reference type '${reftype}' does not equal to 'heads', update_and_create_branch_by_sha is skipped."
        return 1
    fi
    repourl="https://${GITHUB_SERVER}/api/v3/repos/${orgname}/${reponame}/branches/${refname}"
    rspcode=$(curl -s -o nul -w "%{http_code}" -H "Authorization: token ${GITHUB_USER_TOKEN}" -L ${repourl})
    if [ "200" == "${rspcode}" ]; then
        #found branch
        echo "The branch ${refname} already exists!"
        return 0
    elif [ "404" == "${rspcode}" ]; then
        #########################################################################
        #				Create a branch
        #########################################################################
        reqdata="{\"ref\": \"refs/${reftype}/${refname}\", \"sha\": \"${shacode}\"}"
        repourl="https://${GITHUB_SERVER}/api/v3/repos/${orgname}/${reponame}/git/refs"
        rspcode=$(curl -s -o nul -w "%{http_code}" -H "Authorization: token ${GITHUB_USER_TOKEN}" --request POST -L "${repourl}" -d "${reqdata}")
        if [ "201" != "${rspcode}" ]; then 
            echo "Create ${reponame} branch ${refname} error : ${rspcode}"
            return 1
        fi
        echo "Create ${reponame} branch ${refname} successfully"
        return 0
    else
        echo "Query ${reponame} branch ${refname} error - ${rspcode}"
        return 1
    fi
    return 0
}

update_and_create_tag_by_sha()
{
    orgname=$1
    reponame=$2
    reftype=$3
    refname=$4
    shacode=$5    
    if [ ! "tags" == "$reftype" ]; then
        echo "reference type is wrong! ${reftype}"
        return 1
    fi
    #########################################################################
    #				Check whethere tag exists
    #########################################################################
    repourl="https://${GITHUB_SERVER}/api/v3/repos/${orgname}/${reponame}/git/refs/${reftype}/${refname}"
    rspcode=$(curl -s -o nul -w "%{http_code}" -H "Authorization: token ${GITHUB_USER_TOKEN}" -L ${repourl})
    if [ "200" == "${rspcode}" ]; then
    #########################################################################
    #				Update tags with commit
    #########################################################################
        reqdata="{\"sha\": \"${shacode}\", \"force\": true}"
        rspcode=$(curl -s -o nul -w "%{http_code}" -H "Authorization: token ${GITHUB_USER_TOKEN}" --request PATCH -L "${repourl}" -d "${reqdata}")
        if [ "200" != "${rspcode}" ]; then 
            echo "Update ${reponame} tag error - ${rspcode}"
            return 1
        fi
        echo "Update ${reponame} tag ${refname} successfully"
        return 0
    elif [ "404" == "${rspcode}" ]; then
    #########################################################################
    #				Create a tag
    #########################################################################
        reqdata="{\"ref\": \"refs/${reftype}/${refname}\", \"sha\": \"${shacode}\"}"
        repourl="https://${GITHUB_SERVER}/api/v3/repos/${orgname}/${reponame}/git/refs"
        rspcode=$(curl -s -o nul -w "%{http_code}" -H "Authorization: token ${GITHUB_USER_TOKEN}" --request POST -L "${repourl}" -d "${reqdata}")
        if [ "201" != "${rspcode}" ]; then 
            echo "Create ${reponame} tag ${refname} error : ${rspcode}"
            return 1
        fi
        echo "Create ${reponame} tag ${refname} successfully"
        return 0
    else
        echo "Query ${reponame} tag ${refname} error - ${rspcode}"
        return 1
    fi
    return 0
}

update_and_create_ref_by_sha()
{  
    update_and_create_branch_by_sha "$@" || update_and_create_tag_by_sha "$@"
}

update_and_create_ref_by_srctag()
{
    orgname=$1
    reponame=$2
    reftype=$3
    refname=$4
    srctagtype=$5
    srctag=$6
    shacode=""
    ret=0

    if [ "${srctagtype}" == "sha" ]; then 
        shacode=$srctag
    else
        shacode=$(get_ref_sha $orgname $reponame $srctagtype $srctag)    
        ret=$?
    fi

    if [ 0 != $ret ]; then
        return 1
    fi
    update_and_create_ref_by_sha $orgname $reponame $reftype $refname $shacode
    return $?
}

# example: create a pre-release "v0.9" on tag "mytag123" in repository "myorg/demo_repo"
# create_release_by_tag myorg demo_repo mytag123 v0.9 "test release" pre-release
create_release_by_tag()
{
    orgname=$1
    reponame=$2
    tagname=$3
    relname=$4
    relmsg=$5
    release_type=$6 # pre-release | release

    prerelease="false"
    if [ "${release_type}" = "pre-release" ]; then prerelease="true"; fi

    requrl="https://${GITHUB_SERVER}/api/v3/repos/${orgname}/${reponame}/releases"
    reqdata="{\"tag_name\":\"${tagname}\",\"name\":\"${relname}\",\"body\":\"${relmsg}\",\"prerelease\":${prerelease}}"
    rspcode=$(curl -s -o nul -w "%{http_code}" -H "Authorization: token ${GITHUB_USER_TOKEN}" --request POST -L "${requrl}" -d "${reqdata}")
    if [ "201" != "${rspcode}" ]; then 
        echo "Create ${release_type} '${relname}' from tag '${tagname}' in repository '${orgname}/${reponame}' error : ${rspcode}"
        return 1
    fi
    echo "Create ${release_type} '${relname}' from tag '${tagname}' in repository '${orgname}/${reponame}' successfully"
    return 0
}