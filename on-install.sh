cd node_modules/node-telegram-bot-api

# install devDependencies
npm install --only=dev

# build package
npm run prepublish

# remove devDependencies
npm prune --production
