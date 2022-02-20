function subtreeFlow {
    local repo=$1
    local branch=$2
    local prefix="$3"

    local curBranch=`git rev-parse --abbrev-ref HEAD`

    echo "> Switch to temporary branch"
    git checkout -b "temp-update-subtree" "$curBranch"

    if [[ -d "$prefix" ]]; then
        echo "> backup $prefix"
        mv "$prefix" "$prefix-bak"

        git commit -am "backup $prefix"
    fi

    echo "> Adding subtree"
    git subtree add --prefix "$prefix" "$repo" "$branch" --squash -m "sync(subtree): add $repo"

    echo "> Restore $prefix backup"
    rm -rf $prefix
    mv "$prefix-bak" "$prefix"

    git add -A
    git diff-index --quiet HEAD || git commit -m "restore $prefix-bak"

    echo "> Pulling latest changes from remote subtree: "$prefix" "$repo" "$branch""
    git subtree pull --prefix "$prefix" "$repo" "$branch" --squash  -m "sync(subtree): pull latest changes from $repo"

    echo "> Push latest changes to remote subtree: "$prefix" "$repo" "$branch""
    git subtree push --prefix "$prefix" "$repo" "$branch"

    echo "> Pulling again after a push: "$prefix" "$repo" "$branch""
    git subtree pull --prefix "$prefix" "$repo" "$branch" --squash  -m "sync(subtree): sync pushed changes from $repo"

    git add -A
    git diff-index --quiet HEAD || git commit -m "commit all pulled changes"

    echo "> Switch to previous branch and squash+delete temporary one"
    git checkout "$curBranch"

    git merge --squash "temp-update-subtree"

    git branch -D "temp-update-subtree"

    #git subtree split --prefix "$prefix" -b "$branch"  --rejoin 
}
