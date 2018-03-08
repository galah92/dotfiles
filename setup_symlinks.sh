echo "- Creating symlinks..."
files=".bashrc .vimrc .tmux.conf .gitconfig"
for file in $files; do
    ln -sf dotfiles/"$file" ~/"$file"
    echo "- Done: $file"
done
