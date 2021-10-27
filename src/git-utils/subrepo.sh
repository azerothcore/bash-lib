
#!/usr/bin/env bash



CUR_PATH="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )/"

function subrepoUpdate() {
    repo=$1
    branch=$2
    folder=$3

    toClone=$(git ls-remote --heads "$repo" "$branch" | wc -l)

    if [[ -d "$folder" ]]; then
        if [[ ! -f "$folder/.gitrepo" ]]; then
            echo "> Initializing subrepo for existing $folder -r $repo -b $branch..."
            git subrepo init "$folder" -r "$repo" -b "$branch"
        fi

        if [[ $toClone -eq 0 ]]; then
            echo "> Pushing subrepo on $folder -b $branch..."
            git subrepo push "$folder" -b "$branch"
        fi
    else
        # try-catch
        set +e
        echo "> Cloning subrepo for $folder $repo -b $branch..."
        git subrepo clone "$repo" "$folder" -b "$branch"
        set -e
    fi

    git subrepo clean "$folder"
    echo "> Pulling subrepo on $folder -b $branch..."
    git subrepo pull -b "$branch" "$folder" --message="sync(subrepo): pull changes from $repo"

    curCommit=$(git rev-parse HEAD)

    # this empty commit is used to produce meaningful commits message when pushing with squash to external subrepos
    # instead of picking the last commit message as the text for the entire squashed commit
    git commit --allow-empty -m "sync(subrepo): changes from/to $repo"

    echo "> Pushing subrepo on $folder -b $branch..."
    git subrepo push  -b "$branch" -s "$folder"

    git reset --hard $curCommit

    # pull force to sync the .gitrepo file after the hard reset
    # we write the commit again after the soft reset to keep it in the main repo history
    # NOTE: it will be created only if we had changes
    git subrepo pull -f -b "$branch" "$folder" --message="sync(subrepo): push changes to $repo"
    
    git subrepo clean --ALL --force
}
