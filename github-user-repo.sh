#!/usr/bin/env bash

# Script from http://codereview.stackexchange.com/questions/48050/bash-script-to-clone-all-public-repos-or-gists-for-a-specified-user-optionally


# Check if git is installed, if not bail
if [[ ! "$(type -P 'git')" ]]; then
    printf "$(tput setaf 1)⊘ Error:$(tput sgr0) %s. Aborting!\n" "Git is required to use $(basename "$0")"
    printf "\n"
    printf "Download it at http://git-scm.com"
    exit 2
fi

# Check if jq is installed, if not bail
if [[ ! "$(type -P 'jq')" ]]; then
    printf "$(tput setaf 1)⊘ Error:$(tput sgr0) %s. Aborting!\n" "jq is required to parse JSON." 
    printf "\n"
    printf "Download it at http://stedolan.github.io/jq"
    exit 2
fi

# variables
feed="repos"
path="${HOME}/Sources/kicad-pretty"
usage="$(basename "$0"): usage: $(basename "$0") [-h|--help] [-v|--version] [-f|--feed <value>] <github_username> [<path>]"

# Test for known flags
for opt in "$@"
do
    case "$opt" in
        -f | --feed) # choose feed type
            if [[ "$2" == "repos" || "$2" == "gists" ]]; then
                feed="$2"
            else
                printf "%s\n" "-bash: $(basename "$0"): $1: invalid feed type [repos|gists]"
                printf "%s" "$usage"
                exit 1
            fi
            shift 2
            ;;
        -h | --help) # Help text
            printf "\n"
            printf "%s\n" "Options:"
            printf "\n"
            printf "\t%s\n" "-h, --help              Print this help text"
            printf "\t%s\n" "-f, --feed [<value>]    <value> can be either gists or repos, default is repos"
            printf "\t%s\n" "-v, --version           Print out the version"
            printf "\n"
            printf "%s\n" "Documentation can be found at https://github.com/chriopedia/clone-all"
            exit 0
            ;;
        --test) # test suite using roundup
            roundup="$(type -P 'roundup')"
            [[ ! -z $roundup ]] || {
                printf "$(tput setaf 1)⊘ Error:$(tput sgr0) %s. Aborting!\n" "Roundup is required to run tests"
                printf "\n"
                printf "Download it at https://github.com/bmizerany/roundup"
                exit 2;
            }
            $roundup ./tests/*.sh
            exit 0
            ;;
        -v | --version) # Version of software
            printf "%s\n" "Version $(git describe --tags)"
            exit 0
            ;;
        --) # End of all options
            printf "%s\n" "-bash: $(basename "$0"): $1: invalid option"
            printf "%s" "$usage"
            exit 1
            ;;
        -*)
            printf "%s\n" "-bash: $(basename "$0"): $1: invalid option"
            printf "%s" "$usage"
            exit 1
            ;;
        *)  # No more options
            break
            ;;
    esac
done

# Check if username is passed in, if not bail
if [[ -z "$1" ]]; then
    printf "$(tput setaf 1)⊘ Error:$(tput sgr0) %s. Aborting!\n" "A valid Github user is required" 
    exit 3
fi

# check if directory is not blank and exists
if [[ ! -z "$2" && -d "$2" ]]; then
    # http://www.linuxforums.org/forum/programming-scripting/solved-delete-trailing-slashes-using-bash-board-means-print-172714.html
    # This matches from the start of the source string, any 
    # string ending with a non-slash.
    pattern="^.*[^/]"
    # Apply regex
    [[ ${2} =~ $pattern ]]
    # Print the portion of the source string which matched the regex.
    path="${BASH_REMATCH[0]}"
fi

# set some variables
user="$1"
api_url="https://api.github.com/users/${user}/${feed}"
current_page=1
per_page=100

printf "%s" "Checking status of user '${user}'"
# http://stackoverflow.com/questions/238073/how-to-add-a-progress-bar-to-a-shell-script
# start progress bar
while :;do echo -n .;sleep 1;done &

# check response header from github user passed in
# http://stackoverflow.com/a/10724976/1536779
response="$(curl --write-out %{http_code} --silent --output /dev/null "${api_url}")"

# kill the progress bar
kill $!; trap 'kill $!' SIGTERM

# if reponse is greater than or equal to 400 somethings wrong
if [[ "${response}" -ge 400 ]]; then
    printf "%s\n" "-bash: $(basename "$0"): $1: user doesn't exist"
    #debug statement
    printf "%s\n" "Github HTTP Response code: ${response}"
    exit 3
fi


# grab the total number of pages there are
# https://gist.github.com/michfield/4525251
total_pages="$(curl -sI "${api_url}?page=1&per_page=${per_page}" | sed -nE "s/^Link:.*page=([0-9]+)&per_page=${per_page}>; rel=\"last\".*/\1/p")"
if [[ -z ${total_pages} ]]; then
    total_pages=1
fi

# grab a list of repos or gists
# @params $1: page number
# example: get_repos_list 1
get_repos_list() {
    # get a json list of all repos and story as array
    if [[ ${feed} != 'gists' ]]; then
        repos=$(curl -fsSL "${api_url}?page=${1}&per_page=${per_page}" | jq '.[] | .name')
    else
        repos=$(curl -fsSL "${api_url}?page=${1}&per_page=${per_page}" | jq '.[] | .id')
    fi
    echo "$repos"
}

# loop through list of repos at the current page
clone_shit() {
    printf "%s" "Grabbing list of ${feed} for ${user}"
    # http://stackoverflow.com/questions/238073/how-to-add-a-progress-bar-to-a-shell-script
    # start progress bar
    while :;do echo -n .;sleep 1;done &

    # get the list of repos for user
    repos_list=($(get_repos_list "${current_page}"))

    # kill the progress bar
    kill $!; trap 'kill $!' SIGTERM
    printf "\n"

    # loop through all repos in array
    for index in ${!repos_list[*]}
    do
        # variable assignment
        repo="${repos_list[$index]}"
        # Strip quotes from string
        repo="${repo:1:${#repo}-2}"

        if [[ ${feed} != "gists" ]]; then
            printf "%s\n" "Cloning https://github.com/${user}/${repo} to ${path}/repos/${repo}"
            git clone "https://github.com/${user}/${repo}" "${path}/${repo}"
        else
            printf "%s\n" "Cloning https://gist.github.com/${repo}.git to ${path}/gists/${repo}"
            #git clone "https://gist.github.com/${repo}.git" "${path}/gists/${repo}"
        fi
    done
}

printf "\n"

clone_shit
if [[ ${total_pages} -gt 1 && ${current_page} -lt ${total_pages} ]]; then
    current_page=$((current_page + 1))
    clone_shit
fi
