# CloudFlare DDNS Manager 🌐

A robust, Docker-based Dynamic DNS updater for Cloudflare domains with multi-channel notifications support.

## Features ✨

- 🔄 Automatic DNS record updates for multiple domains/subdomains
- 🐳 Lightweight Docker container based on Alpine Linux
- 🔔 Multi-channel notifications support:
  - Telegram
  - Discord
  - Slack
- 🛡️ Supports Cloudflare proxy status
- ⚡ Fast IP change detection
- 📝 Detailed logging
- 🎛️ Configurable notification preferences
- 🔌 Easy setup with environment variables

## Prerequisites 📋

- Docker and Docker Compose
- Cloudflare account with:
  - Domain(s) added to Cloudflare
  - Global API Key
  - Zone ID

## Quick Start 🚀

1. Clone the repository:
```bash
git clone https://github.com/yourusername/cloudflare-ddns-manager.git
cd cloudflare-ddns-manager
```

2. Configure your `.env` file:
```env
# Cloudflare Credentials
AUTH_EMAIL=your-email@example.com
AUTH_KEY=your-global-api-key
ZONE_IDENTIFIER=your-zone-id

# DNS Records (comma-separated lists)
RECORD_NAMES=example.com,www.example.com,subdomain.example.com
TTL=1
PROXY=true

# Notification Settings
REPORT_SUCCESS=true
REPORT_ERROR=true

# Telegram (Optional)
TELEGRAM_BOT_TOKEN=your-bot-token
TELEGRAM_CHAT_ID=your-chat-id

# Slack (Optional)
SLACK_URI=your-slack-webhook-url
SLACK_CHANNEL=#your-channel

# Discord (Optional)
DISCORD_URI=your-discord-webhook-url
```

3. Start the container:
```bash
docker compose up -d
```

## Configuration Guide 📝

### Cloudflare Settings

1. Get your Zone ID:
   - Log into Cloudflare
   - Select your domain
   - Find Zone ID on the overview page

2. Get your Global API Key:
   - Go to Profile > API Tokens
   - View Global API Key

### Notification Setup

#### Telegram
1. Create a bot via [@BotFather](https://t.me/botfather):
   - Start a chat with @BotFather
   - Send `/newbot`
   - Choose a name for your bot
   - Choose a username (must end in 'bot')
   - Save the API token provided

2. Get your chat ID (two methods):
   
   Method 1 (Easiest):
   - Start a chat with [@userinfobot](https://t.me/userinfobot)
   - It will reply with your chat ID

   Method 2 (Alternative):
   - Start a chat with your new bot
   - Send it any message
   - Visit: `https://api.telegram.org/bot<YourBOTToken>/getUpdates`
   - Look for `"chat":{"id":XXXXXXXXX}` in the response
   - The number (XXXXXXXXX) is your chat ID

3. Configure your `.env` file with:
   ```env
   TELEGRAM_BOT_TOKEN=your_bot_token
   TELEGRAM_CHAT_ID=your_chat_id  # Just the number, e.g., 123456789
   ```

#### Discord
1. Server Settings > Integrations
2. Create Webhook
3. Copy Webhook URL

#### Slack
1. Create an app in your workspace
2. Enable Incoming Webhooks
3. Copy the Webhook URL

## Environment Variables 🔧

| Variable | Description | Default |
|----------|-------------|---------|
| AUTH_EMAIL | Cloudflare account email | Required |
| AUTH_KEY | Cloudflare Global API Key | Required |
| ZONE_IDENTIFIER | Cloudflare Zone ID | Required |
| RECORD_NAMES | Comma-separated list of domains | Required |
| TTL | DNS record TTL | 1 |
| PROXY | Enable Cloudflare proxy | true |
| REPORT_SUCCESS | Send success notifications | true |
| REPORT_ERROR | Send error notifications | true |

## Logs Example 📊

```log
DDNS Updater: Current public IP is 203.0.113.1
DDNS Updater: Processing record example.com
DDNS Updater: IP change detected for example.com: 203.0.113.0 -> 203.0.113.1
DDNS Updater: Successfully updated example.com to IP: 203.0.113.1
```

## Contributing 🤝

Contributions are welcome! Please feel free to submit a Pull Request.

## License 📄

This project is licensed under the MIT License - see the [LICENSE](LICENSE) file for details.

## Support 💬

If you have any questions or need help, please open an issue on GitHub. 
