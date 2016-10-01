Telegram bot for executing snippets of code.

"Official" deploy: [@rextester_bot][1]

## Setup ##

    npm install

    # without angle brackets
    export TELEGRAM_BOT_TOKEN=<Telegram bot token>
    # alternatively, you can put your token in token.json

    # if the app is behind https => http proxy,
    # and you wish to use Webhook, set also these:
    export NOW_URL=https://<url to set webhook to>
    export PORT=<port to listen to updates on>

    npm start

[1]: https://telegram.me/rextester_bot
