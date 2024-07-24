# file : download_nerd_font.sh
```bash
#/bin/bash
# install DroidSansMono Nerd Font --> u can choose another at: https://www.nerdfonts.com/font-downloads
echo "[-] Download fonts [-]"
echo "https://github.com/ryanoasis/nerd-fonts/releases/download/v2.1.0/DroidSansMono.zip"
wget https://github.com/ryanoasis/nerd-fonts/releases/download/v2.1.0/DroidSansMono.zip
unzip DroidSansMono.zip -d ~/.fonts
fc-cache -fv
echo "done!"
```
# Run the script 
```
bash download_nerd_font.sh
```
# Install starship 
```
curl -sS https://starship.rs/install.sh | sh
```
# update the configuration 
```
mkdir -p ~/.config && touch ~/.config/starship.toml
export STARSHIP_CONFIG=~/.config/starship.toml
eval "$(starship init bash)"
# eval "$(starship init zsh)"
```
# vfarcic's starship toml file 
```
curl -O https://raw.githubusercontent.com/vfarcic/dotfiles-demo/main/starship.toml
mv starship.toml  ~/.config/
```

ref: 
- https://gist.github.com/matthewjberger/7dd7e079f282f8138a9dc3b045ebefa0?permalink_comment_id=3839120#gistcomment-3839120
- https://devopstoolkit.live/terminal/from-boring-to-productive-customize-your-shell-prompt-with-starship/
