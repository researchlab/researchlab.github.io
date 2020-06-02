
rm -rf db.json
rm -r $(ls |grep -v deploy.sh |grep -v node_modules | grep -v public)
mv public/* .
git add .
git commit -m"Site Update:$(date)"
git push origin master -vvv
