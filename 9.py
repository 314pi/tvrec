import configparser

config = configparser.ConfigParser()
config.read('film.ini')
print(config['cgbg']['_title'])