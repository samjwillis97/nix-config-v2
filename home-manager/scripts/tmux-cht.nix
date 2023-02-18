{ pkgs, ... }:
let
    languages = ''
        golang
        nodejs
        javascript
        tmux
        typescript
        zsh
        cpp
        c
        lua
        rust
        python
        bash
        haskell
        css
        html
    '';

    commands = ''
        ind
        man
        tldr
        sed
        awk
        tr
        cp
        ls
        grep
        xargs
        rg
        ps
        mv
        kill
        lsof
        less
        head
        tail
        tar
        cp
        rm
        rename
        jq
        cat
        ssh
        cargo
        git
        git-worktree
        git-status
        git-commit
        git-rebase
        docker
        docker-compose
        stow
        chmod
        chown
        make
    '';

    tmux-cht = pkgs.writeShellScriptBin "tmux-cht" ''
        selected=`cat ${languages} ${commands}| fzf`
        if [[ -z $selected ]]; then
            exit 0
        fi

        read -p "Enter Query: " query

        if grep -qs "$selected" ${languages} ; then
            query=`echo $query | tr ' ' '+'`
            tmux neww bash -c "echo \"curl cht.sh/$selected/$query/\" & curl cht.sh/$selected/$query & while [ : ]; do sleep 1; done"
        else
            tmux neww bash -c "curl -s cht.sh/$selected~$query | less"
        fi
    '';
in {
    home.packages = [
        tmux-cht
    ];
}
