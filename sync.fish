#!/usr/bin/env fish
set cheatsheet_path $argv[1]
set sync_path $argv[2]

cp $cheatsheet_path $sync_path
cd $sync_path
if cd .git
    cd ..
else
    git init
end
git add .
git commit -m (date)
