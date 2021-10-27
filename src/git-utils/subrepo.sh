
#!/usr/bin/env bash



CUR_PATH="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )/"

echo "> Init and updating submodules..."

function subrepoUpdate() {
    repo=$1
    branch=$2
    folder=$3

    toClone=$(git ls-remote --heads "$repo" "$branch" | wc -l)

    curCommit=$(git rev-parse HEAD)

    if [[ -d "$folder" ]]; then
        if [[ ! -f "$folder/.gitrepo" ]]; then
            git subrepo init "$folder" -r "$repo" -b "$branch"
        fi

        if [[ $toClone -eq 0 ]]; then
            git subrepo push "$folder"
        fi
    else
        # try-catch
        set +e
        git subrepo clone "$repo" "$folder" -b "$branch"
        set -e
    fi

    git subrepo clean "$folder"
    git subrepo pull -f "$folder"

    # this empty commit is used to produce meaningful commits message when pushing with squash to external subrepos
    # instead of picking the last commit message as the text for the entire squashed commit
    git commit --allow-empty -m "sync(subrepo): changes from/to $repo"

    git subrepo push "$folder" -s
    git subrepo clean "$folder"

    git reset --soft $curCommit

    # we write the commit again after the soft reset to keep it in the main repo history
    # NOTE: it will be created only if we had changes
    git commit -m "sync(subrepo): changes from/to $repo" || true
}
