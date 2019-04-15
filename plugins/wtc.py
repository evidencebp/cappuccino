from contextlib import closing

import irc3
import requests
from bs4 import BeautifulSoup
from irc3.plugins.command import command
from requests import RequestException

USER_AGENT = 'cappuccino/wtc.py (https://github.com/FoxDev/cappuccino/plugins/wtc.py)'
REQUEST_TIMEOUT = 5

REQUEST_HEADERS = {
    'User-Agent': USER_AGENT,
    'Accept-Language': 'en-GB,en-US,en;q=0.5'
}

REQUEST_OPTIONS = {
    'timeout': REQUEST_TIMEOUT,
    'allow_redirects': True,
    'headers': REQUEST_HEADERS
}


@irc3.plugin
class BotUI(object):

    requires = [
        'irc3.plugins.command',
        'plugins.formatting'
    ]

    def __init__(self, bot):
        self.bot = bot

    @command(permission='view', aliases=['whatthecommit'])
    def wtc(self, mask, target, args):
        """Grab a random commit message.

            %%wtc
        """

        try:
            with closing(requests.get('https://whatthecommit.com/', **REQUEST_OPTIONS)) as response:
                commit_message = BeautifulSoup(response.text, 'html.parser').find('p').text.strip()
                commit_message = self.bot.format(commit_message, bold=True)
        except RequestException as ex:
            yield ex.strerror

        yield f'git commit -m "{commit_message}"'