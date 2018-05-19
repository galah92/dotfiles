echo "- Creating symlinks..."
files=".bashrc .bash_profile .vimrc .gitconfig"
for file in $files; do
    ln -sf dotfiles/"$file" ~/"$file"
    echo "- Done: $file"
done
