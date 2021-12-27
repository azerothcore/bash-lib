function subtreeFlow {
    local repo=$1
    local branch=$2
    local prefix="$3"

    if [[ -d "$prefix" ]]; then
        echo "> Creating subtree for existing prefix $prefix $repo -b $branch..."
        git subtree split --prefix "$prefix" -b "$branch"
    else
        echo "> Adding subtree if not exists"
        git subtree add --prefix "$prefix" "$repo" "$branch"
    fi

    echo "> Pulling latest changes from remote subtree: "$prefix" "$repo" "$branch""
    git subtree pull --prefix "$prefix" "$repo" "$branch"
    echo "> Push latest changes to remote subtree: "$prefix" "$repo" "$branch""
    git subtree push --prefix "$prefix" "$repo" "$branch"  --squash

    git subtree split --prefix "$prefix" -b "$branch"  --rejoin 
}
