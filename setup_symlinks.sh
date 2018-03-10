echo "- Creating symlinks..."
files=".bashrc .bash_profile .vimrc .tmux.conf .gitconfig"
for file in $files; do
    ln -sf dotfiles/"$file" ~/"$file"
    echo "- Done: $file"
done
