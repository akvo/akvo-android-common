#!/usr/bin/python

"""
Generates a release notes markdown file with list of issues grouped by
specified issue labels for a particular milestone in GitHub repo

Tested on: Ubuntu 16.10, Windows 10, OS X El Capitan

Usage:
1. Create a file for config named 'local_release_notes.cfg' (sample below)

SAMPLE OF CONFIG FILE:
-----------------------------------------------------------------------
[config]
# the project repo path on GitHub
repo = akvo/akvo-flow-mobile

# the milestone for which the release notes are to be generated
milestone = 2.2.11

# the GitHub issue labels by which to filter and group the notes
labels = New and noteworthy, Resolved issues
-----------------------------------------------------------------------

2. Run command: python release-notes.py
3. The release notes file is generated in temp folder and opened in default editor

"""

import os
import json
import time
import sys
import urllib2
import contextlib
import ConfigParser
import subprocess

config = ConfigParser.RawConfigParser()
config.read(r'local_release_notes.cfg')

MILESTONE = config.get('config', 'milestone')
LABELS = config.get('config', 'labels').split(",")
REPO = config.get('config', 'repo')

API_URL = 'https://api.github.com/search/issues?q=milestone:' \
    + MILESTONE + '+repo:' + REPO + '+label:'
OUTPUT_FOLDER = 'temp'
OUTPUT_FILE = OUTPUT_FOLDER + '/release_notes.md'

if not os.path.exists(OUTPUT_FOLDER):
    os.makedirs(OUTPUT_FOLDER)


def open_file(filename):
    """
    Opens a file with the default application

    Parameters
    ----------
    filename : str
        The file to open

    """
    if sys.platform == "win32":
        os.startfile(filename)
    else:
        opener = "open" if sys.platform == "darwin" else "xdg-open"
        subprocess.call([opener, filename])


def load_issues(url):
    """
    Loads all GitHub issues given a url

    Parameters
    ----------
    url : str
        The full url to use

    Returns
    -------
    json array
        containing issues

    """
    with contextlib.closing(urllib2.urlopen(url)) as github_request:
        json_result = json.JSONDecoder().decode(github_request.read())
        return json_result['items']


try:
    # create output file and write the release notes details in markdown format
    with open(OUTPUT_FILE, 'w') as f:
        f.write('# ver ' + MILESTONE + '\n')
        f.write('Date: ' + time.strftime("%d %B %Y") + '\n')

        for label in LABELS:
            f.write('\n# ' + label + '\n')

            for issue in load_issues(API_URL + '"' + label.replace(" ", "+") + '"'):
                f.write('* **{}** - [#{}]({})\n'.format(
                    issue['title'], issue['number'], issue['html_url']))

        # open the generated file in the default text editor
        open_file(os.path.join(os.path.realpath('./'), OUTPUT_FILE))

except IOError:
    print 'Error: Could not get list. Check connectivity, config, etc...'
