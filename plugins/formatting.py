import irc3


@irc3.plugin
class Formatting(object):
    class Color(object):
        RESET = '\x0f'
        WHITE = '00'
        BLACK = '01'
        BLUE = '02'
        GREEN = '03'
        RED = '04'
        BROWN = '05'
        PURPLE = '06'
        ORANGE = '07'
        YELLOW = '08'
        LIGHT_GREEN = '09'
        TEAL = '10'
        LIGHT_CYAN = '11'
        LIGHT_BLUE = '12'
        PINK = '13'
        GRAY = '14'
        LIGHT_GRAY = '15'

    def __init__(self, bot):
        self.bot = bot
        self.bot.color = self.Color

    @irc3.extend
    def format(self, text, color=None, bold=False, antiping=False):
        # Insert a single zero-width space in the middle of each word of a string to prevent unwanted IRC client pings
        if antiping:
            newtext = []
            for word in text.split():
                word_middle = int(len(word) / 2)
                newtext.append(word[:word_middle] + '\u200B' + word[word_middle:])
            text = ' '.join(newtext)
            print(text.encode('UTF-8'))
        if bold:
            text = '\x02{0}'.format(text)
        if color:
            text = '\x03{0}{1}'.format(color, text)
        if bold or color:
            text += self.bot.color.RESET
        return text
