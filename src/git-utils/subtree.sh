function subtreeFlow {
    local repo=$1
    local branch=$2
    local prefix="$3"

    echo "> Adding subtree if not exists"
    git subtree add --prefix "$prefix" "$repo" "$branch"
    echo "> Pulling latest changes from remote subtree: "$prefix" "$repo" "$branch""
    git subtree pull --prefix "$prefix" "$repo" "$branch"  --squash
    echo "> Push latest changes to remote subtree: "$prefix" "$repo" "$branch""
    git subtree push --prefix "$prefix" "$repo" "$branch"  --squash

    git subtree split --prefix "$prefix" -b "$branch"  --rejoin 
}
