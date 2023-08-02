 
add_content_to_new_line() {
  local content_to_add="$1"
  local file_path="$2"

  if grep -qF "$content_to_add" "$file_path"; then
    echo "The content is already present in $file_path. No changes made."
  else
    # Add the content to the file on a new line
    echo -e "\n$content_to_add" >> "$file_path"
    echo "Content added to $file_path successfully."
  fi
}

install_mega_cmd() {
    mkdir -p ~/Downloads/MEGAcmd
    curl --silent --location --retry 3 "https://mega.nz/MEGAcmdSetup.dmg" --output ~/Downloads/MEGAcmd/MEGAcmdSetup.dmg
    yes | PAGER=cat hdiutil attach -quiet -mountpoint /Volumes/MEGAcmd ~/Downloads/MEGAcmd/MEGAcmdSetup.dmg
    sudo cp -R /Volumes/MEGAcmd/MEGAcmd.app /Applications/
    hdiutil detach /Volumes/MEGAcmd
    rm -rf ~/Downloads/MEGAcmd
}

application_folder="/Applications"
megacmd_app="MEGAcmd.app"
if [ -d "$application_folder/$megacmd_app" ]; then
    echo "MEGAcmd is already installed."
else
    echo "MEGAcmd is not installed. Installing MEGAcmd."
    install_mega_cmd
fi

export_path='export PATH="/Applications/MEGAcmd.app/Contents/MacOS:$PATH"'
default_shell=$(dscl . -read "/Users/$(whoami)" UserShell | awk '{print $NF}')
if [ "$default_shell" = "/bin/zsh" ]; then
    add_content_to_new_line "$export_path" ~/.zshrc
else
    add_content_to_new_line "$export_path" ~/.bash_profile
fi