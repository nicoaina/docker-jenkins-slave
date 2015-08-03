#!/usr/bin/python

"""Android SDK command-line install wrapper script.

Usage:
  android_sdk_installer.py list [--android-home=<path>] [<regexp>]
  android_sdk_installer.py update [--android-home=<path>] <regexp>

Options:
  -h --help     Show this screen.
"""

import os
import subprocess
import re

import pexpect
from docopt import docopt

arguments = docopt(__doc__)

if arguments['--android-home']:
    android_home = arguments['--android-home'];
else:
    android_home = os.environ.get('ANDROID_HOME')
    if not android_home:
        raise EnvironmentError("ANDROID_HOME is not defined")

android_cmd_path = android_home + '/tools/android'

output = subprocess.check_output([android_cmd_path, 'list', 'sdk', '--no-ui', '-a'])
matches = re.findall('(\d+)- (.*)', output)

if arguments['list']:
    names = map((lambda x: x[1]), matches)
    if arguments['<regexp>']:
        names = filter((lambda x: re.match(arguments['<regexp>'], x)), names)
    for name in names:
        print name

if arguments['update']:
    matches = filter((lambda x: re.match(arguments['<regexp>'], x[1])), matches)
    ids = ','.join(map((lambda x: x[0]), matches))
    child = pexpect.spawn(android_cmd_path, ['update', 'sdk', '--no-ui', '-a', '--filter', ids],echo=False)
    while True:
        i = child.expect([pexpect.EOF, 'License id: .*', 'Do you accept the license \'.*\' \[y/n\]:'],timeout=None)
        if i == 0:
            print child.before
            break
        if i == 1:
            print '-------------------------------\n', child.after
        if i == 2:
            print child.before
            print "\n... (python installer script will accept this license on your behalf) ...\n"
            child.sendline('y')
