function subtreeFlow {
    local repo=$1
    local branch=$2
    local prefix="$3"

    if [[ -d "$prefix" ]]; then
        echo "> Split subtree for existing prefix $prefix $repo -b $branch..."
        #git subtree split --prefix "$prefix" -b "$branch"
    else
        echo "> Adding subtree if not exists"
        git subtree add --prefix "$prefix" "$repo" "$branch" --squash -m "sync(subtree): add $repo"
    fi

    echo "> Pulling latest changes from remote subtree: "$prefix" "$repo" "$branch""
    git subtree pull --prefix "$prefix" "$repo" "$branch" --squash  -m "sync(subtree): pull latest changes from $repo"
    echo "> Push latest changes to remote subtree: "$prefix" "$repo" "$branch""
    git subtree push --prefix "$prefix" "$repo" "$branch"

    echo "> Pulling again after a push: "$prefix" "$repo" "$branch""
    git subtree pull --prefix "$prefix" "$repo" "$branch" --squash  -m "sync(subtree): sync pushed changes from $repo"

    #git subtree split --prefix "$prefix" -b "$branch"  --rejoin 
}
