#!/bin/sh

#  deployment.sh
#  
#
#  Created by Valdeva Crema on 4/22/19.
#

deploy_dir='dev'
datestamp=$(date +"%Y-%m-%d")

#start in home dir
cd

backup_dir="$deploy_dir.$datestamp"
echo "=======> Backing up current working directory $backup_dir <========"
mv $deploy_dir $backup_dir

echo "=======> Creating new $deploy_dir directory <========"
mkdir $deploy_dir

release_file=""

for entry in deploy/*.tar.gz
do
  release_file="$(basename $entry)"
  break
done

if [ -z $release_file ]; then
    echo "=======> Can not find release file to unzip. Please make sure it is in the ~/deploy directory=======>"
    echo "Terminating deploy"
    exit 1
fi

#Copy the file to the deploy directory
cp "deploy/$release_file" $deploy_dir/.

#Cd into deploy directory
cd $deploy_dir

#Unzip the file
tar -xvzf $release_file

echo "=======> Installing proper gems =======> "

#cd to home directory
cd

#Create temp app
rails new temp_app

#cd into temp app
cd temp_app

#Copy the unzipped Gemfile into
cp ../$deploy_dir/Gemfile .

#Delete the Gemfile.lock
rm Gemfile.lock

#Run bundle install
bundle install

#Cd to home directory
cd

#Remove temp directory
rm -rf temp_app

#Move back into the deploy directory
cd $deploy_dir

If migrations exist, run the migrations command
if [ -z "$(ls -A db/migrate)" ]; then
    echo "=======> No migrations to run=======>"
else
    echo "=======> Running migrations=======>"
#    bundle exec rake db:migrate
fi

#Restart apache
echo "=======> Setup complete. Please restart Apache =======>"
