"""
Holmes Slack Bot - Listens for @holmes mentions and sends queries to Holmes GPT
"""
import os
import re
import logging
from slack_bolt import App
from slack_bolt.adapter.socket_mode import SocketModeHandler
import requests
import json

# Configure logging
logging.basicConfig(level=logging.INFO)
logger = logging.getLogger(__name__)

# Initialize Slack app
app = App(token=os.environ.get("SLACK_BOT_TOKEN"))

# Holmes GPT service configuration
HOLMES_API_URL = os.environ.get("HOLMES_API_URL", "http://holmesgpt-holmes.holmesgpt.svc.cluster.local:80")
HOLMES_MODEL = os.environ.get("HOLMES_MODEL", "azure-gpt4o")

def query_holmes(question: str) -> str:
    """
    Send a question to Holmes GPT and get the response
    """
    try:
        logger.info(f"Sending query to Holmes: {question}")

        response = requests.post(
            f"{HOLMES_API_URL}/api/chat",
            json={
                "ask": question,
                "model": HOLMES_MODEL
            },
            timeout=300  # 5 minute timeout for complex queries (especially git operations)
        )

        if response.status_code == 200:
            result = response.json()
            logger.info(f"Holmes API response: {result}")
            # Holmes returns the analysis in the 'analysis' field
            return result.get("analysis", result.get("response", "No response from Holmes"))
        else:
            logger.error(f"Holmes API returned status {response.status_code}: {response.text}")
            return f"❌ Holmes API error (status {response.status_code})"

    except requests.exceptions.Timeout:
        logger.error("Holmes API timeout")
        return "⏱️ Holmes took too long to respond. The query might be too complex."
    except Exception as e:
        logger.error(f"Error querying Holmes: {str(e)}")
        return f"❌ Error communicating with Holmes: {str(e)}"

@app.event("app_mention")
def handle_mention(event, say, client):
    """
    Handle @holmes mentions in Slack
    """
    try:
        logger.info(f"Received mention event: {event}")

        # Extract the message text
        text = event.get("text", "")
        channel = event.get("channel")
        thread_ts = event.get("thread_ts") or event.get("ts")

        # Remove the bot mention from the text to get the actual query
        # Pattern: <@BOTID> query text
        query = re.sub(r'<@[A-Z0-9]+>\s*', '', text).strip()

        if not query:
            say(
                text="👋 Hi! I'm Holmes, your AI Kubernetes assistant. Ask me anything about your cluster!\n\nExample: `@holmes what pods are crashlooping?`",
                thread_ts=thread_ts
            )
            return

        # Send thinking message
        thinking_msg = client.chat_postMessage(
            channel=channel,
            thread_ts=thread_ts,
            text="🔍 Investigating... Let me check that for you."
        )

        # Query Holmes GPT
        holmes_response = query_holmes(query)

        # Update the message with the response
        client.chat_update(
            channel=channel,
            ts=thinking_msg["ts"],
            text=f"🔍 **Holmes Analysis:**\n\n{holmes_response}"
        )

        logger.info("Successfully posted Holmes response to Slack")

    except Exception as e:
        logger.error(f"Error handling mention: {str(e)}")
        say(
            text=f"❌ Sorry, I encountered an error: {str(e)}",
            thread_ts=thread_ts
        )

@app.event("message")
def handle_message_events(body, logger):
    """
    Handle general message events (we ignore these, only respond to mentions)
    """
    pass

# Health check endpoint for Kubernetes
from flask import Flask, jsonify
flask_app = Flask(__name__)

@flask_app.route("/health")
def health():
    return jsonify({"status": "healthy"}), 200

if __name__ == "__main__":
    # Verify environment variables
    slack_bot_token = os.environ.get("SLACK_BOT_TOKEN")
    slack_app_token = os.environ.get("SLACK_APP_TOKEN")

    if not slack_bot_token:
        raise ValueError("SLACK_BOT_TOKEN environment variable is required")
    if not slack_app_token:
        raise ValueError("SLACK_APP_TOKEN environment variable is required")

    logger.info(f"Starting Holmes Slack Bot")
    logger.info(f"Holmes API URL: {HOLMES_API_URL}")
    logger.info(f"Holmes Model: {HOLMES_MODEL}")

    # Start the bot using Socket Mode
    handler = SocketModeHandler(app, slack_app_token)
    handler.start()
