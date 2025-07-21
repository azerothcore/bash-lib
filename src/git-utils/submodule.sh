# Recursive function to update submodules and their nested submodules
# parameters:
# $1 - base directory to start from
# $2 - use fallback branch (default: 1)
# $3 - pull recursively (default: 1)
pull_submodules_recursive() {
    local base_dir="$1"
    local use_fallback_branch="${2:-1}"
    local pull_recursive="${3:-1}"
    local submodules=()
    if [ -f "$base_dir/.gitmodules" ]; then
        mapfile -t submodules < <(git -C "$base_dir" config --file .gitmodules --get-regexp path | awk '{ print $2 }')
    fi
    for submodule in "${submodules[@]}"; do
        local submodule_path="$base_dir/$submodule"
        if [ ! -d "$submodule_path" ]; then
            echo "Error: Submodule $submodule_path not found. Please check if the submodule is initialized correctly."
            exit 1
        fi

        cd "$submodule_path"
        local rel_path=$(realpath --relative-to="$base_dir" "$submodule_path")
        echo "Updating submodule: $rel_path"
        CURRENT_BRANCH=$(git rev-parse --abbrev-ref HEAD)
        if [ "$CURRENT_BRANCH" = "HEAD" ]; then
            if [ "$use_fallback_branch" -eq 0 ]; then
                echo "Submodule $rel_path is in detached HEAD. Skipping pull."
                cd "$base_dir"
                continue
            fi

            REMOTE="origin"
            echo "Submodule $rel_path is in detached HEAD. Trying to pull main or master..."
            if git show-ref --verify --quiet refs/remotes/$REMOTE/main; then
                echo "Pulling submodule: $rel_path ($REMOTE/main)"
                git pull "$REMOTE" main || echo "Warning: Could not pull main for $rel_path."
            elif git show-ref --verify --quiet refs/remotes/$REMOTE/master; then
                echo "Pulling submodule: $rel_path ($REMOTE/master)"
                git pull "$REMOTE" master || echo "Warning: Could not pull master for $rel_path."
            else
                echo "Warning: $submodule_path is in detached HEAD and neither main nor master found. Skipping pull."
            fi
        else
            REMOTE=$(git config branch."$CURRENT_BRANCH".remote)
            MERGE_REF=$(git config branch."$CURRENT_BRANCH".merge)
            if [ -z "$REMOTE" ]; then
                REMOTE="origin"
            fi
            if [ -z "$MERGE_REF" ]; then
                REMOTE_BRANCH="$CURRENT_BRANCH"
            else
                REMOTE_BRANCH="${MERGE_REF#refs/heads/}"
            fi
            echo "Pulling submodule: $submodule_path ($REMOTE/$REMOTE_BRANCH)"
            git pull "$REMOTE" "$REMOTE_BRANCH"
        fi
        cd "$base_dir"

        # Recursively pull submodules if requested
        if [ "$pull_recursive" -eq 1 ]; then
            pull_submodules_recursive "$submodule_path" "$use_fallback_branch" "$pull_recursive"
        fi
    done
}