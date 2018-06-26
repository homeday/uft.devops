# -*- coding: utf-8 -*-
#
# Copyright (C) 2014, 2015, 2016 Carlos Jenkins <carlos@jenkins.co.cr>
#
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
#   http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing,
# software distributed under the License is distributed on an
# "AS IS" BASIS, WITHOUT WARRANTIES OR CONDITIONS OF ANY
# KIND, either express or implied.  See the License for the
# specific language governing permissions and limitations
# under the License.

from __future__ import print_function

import logging
from os import access, X_OK, remove, fdopen, environ
from os.path import isfile, abspath, normpath, dirname, join, basename
logfile = environ.get('WEBHOOKS_LOG_FILE', '/logs/webhooks.log')
verbose = environ.get('WEBHOOK_VERBOSE', 'false') == 'true'
loglevel = logging.DEBUG if verbose else logging.INFO
logging.basicConfig(filename=logfile,level=loglevel)
logging.info('Logging starts with verbose: {}'.format(verbose))

from sys import stderr, hexversion

import hmac
from hashlib import sha1
from json import loads, dumps
from subprocess import Popen, PIPE
from tempfile import mkstemp

import requests
from ipaddress import ip_address, ip_network
from flask import Flask, request, abort
from datetime import datetime


application = Flask(__name__)


@application.route('/', methods=['GET', 'POST'])
def index():
    """
    Main WSGI application entry.
    """

    path = normpath(abspath(dirname(__file__)))

    logging.debug('[{} UTC] Request is received: {} {}'.format(datetime.utcnow().strftime("%Y-%m-%d %H:%M:%S"), request.method, request.url))

    # Only POST is implemented
    if request.method != 'POST':
        abort(501)

    # Load config
    with open(join(path, 'config.json'), 'r') as cfg:
        config = loads(cfg.read())

    hooks = config.get('hooks_path', join(path, 'hooks'))
    logging.debug('[{} UTC] Hook scripts path: {}'.format(datetime.utcnow().strftime("%Y-%m-%d %H:%M:%S"), hooks))

    # Allow Github IPs only
    if config.get('github_ips_only', True):
        src_ip = ip_address(
            u'{}'.format(request.access_route[0])  # Fix stupid ipaddress issue
        )
        whitelist = requests.get('https://api.github.com/meta').json()['hooks']

        for valid_ip in whitelist:
            if src_ip in ip_network(valid_ip):
                break
        else:
            logging.error('IP {} not allowed'.format(
                src_ip
            ))
            abort(403)

    # Enforce secret
    secret = config.get('enforce_secret', '')
    if secret:
        # Only SHA1 is supported
        header_signature = request.headers.get('X-Hub-Signature')
        if header_signature is None:
            abort(403)

        sha_name, signature = header_signature.split('=')
        if sha_name != 'sha1':
            abort(501)

        # HMAC requires the key to be bytes, but data is string
        mac = hmac.new(str(secret), msg=request.data, digestmod='sha1')

        # Python prior to 2.7.7 does not have hmac.compare_digest
        if hexversion >= 0x020707F0:
            if not hmac.compare_digest(str(mac.hexdigest()), str(signature)):
                abort(403)
        else:
            # What compare_digest provides is protection against timing
            # attacks; we can live without this protection for a web-based
            # application
            if not str(mac.hexdigest()) == str(signature):
                abort(403)

    # Implement ping
    event = request.headers.get('X-GitHub-Event', 'ping')
    if event == 'ping':
        logging.debug('[{} UTC] Response ping event. msg: pong'.format(datetime.utcnow().strftime("%Y-%m-%d %H:%M:%S")))
        return dumps({'msg': 'pong'})

    # Gather data
    try:
        payload = request.get_json()
    except Exception:
        logging.warning('Request parsing failed')
        abort(400)

    t = datetime.utcnow().strftime("%Y-%m-%d %H:%M:%S")
    if payload:
        logging.debug('[{} UTC] Payload is detected and not empty'.format(t))
    else:
        logging.debug('[{} UTC] Payload is detected but empty!'.format(t))

    # Determining the branch is tricky, as it only appears for certain event
    # types an at different levels
    branch = None
    try:
        # Case 1: a ref_type indicates the type of ref.
        # This true for create and delete events.
        if 'ref_type' in payload:
            if payload['ref_type'] == 'branch':
                branch = payload['ref']

        # Case 2: a pull_request object is involved. This is pull_request and
        # pull_request_review_comment events.
        elif 'pull_request' in payload:
            # This is the TARGET branch for the pull-request, not the source
            # branch
            branch = payload['pull_request']['base']['ref']

        elif event in ['push']:
            # Push events provide a full Git ref in 'ref' and not a 'ref_type'.
            branch = payload['ref'].split('/', 2)[2]

    except KeyError:
        # If the payload structure isn't what we expect, we'll live without
        # the branch name
        pass

    logging.debug('[{} UTC] Branch name: {}'.format(datetime.utcnow().strftime("%Y-%m-%d %H:%M:%S"), branch))

    # All current events have a repository, but some legacy events do not,
    # so let's be safe
    name = payload['repository']['name'] if 'repository' in payload else None
    logging.debug('[{} UTC] Repo name: {}'.format(datetime.utcnow().strftime("%Y-%m-%d %H:%M:%S"), name))

    meta = {
        'name': name,
        'branch': branch,
        'event': event
    }
    logging.info('Metadata:\n{}'.format(dumps(meta)))

    # Skip push-delete
    if event == 'push' and payload['deleted']:
        logging.info('Skipping push-delete event for {}'.format(dumps(meta)))
        return dumps({'status': 'skipped'})

    # Possible hooks
    scripts = []
    if branch and name:
        scripts.append(join(hooks, '{event}-{name}-{branch}'.format(**meta)))
    if name:
        scripts.append(join(hooks, '{event}-{name}'.format(**meta)))
    scripts.append(join(hooks, '{event}'.format(**meta)))
    scripts.append(join(hooks, 'all'))

    logging.debug('[{} UTC] Try to search any of these script files: {}'.format(datetime.utcnow().strftime("%Y-%m-%d %H:%M:%S"), ','.join(scripts)))

    # Check permissions
    scripts = [s for s in scripts if isfile(s) and access(s, X_OK)]
    if not scripts:
        logging.debug('[{} UTC] No script to run, exit. status: nop'.format(datetime.utcnow().strftime("%Y-%m-%d %H:%M:%S")))
        return dumps({'status': 'nop'})

    logging.debug('[{} UTC] Scripts permission check passed'.format(datetime.utcnow().strftime("%Y-%m-%d %H:%M:%S")))

    # Save payload to temporal file
    osfd, tmpfile = mkstemp()
    with fdopen(osfd, 'w') as pf:
        pf.write(dumps(payload))

    logging.debug('[{} UTC] Payload is saved to temporal file: {}'.format(datetime.utcnow().strftime("%Y-%m-%d %H:%M:%S"), tmpfile))

    # Run scripts
    ran = {}

    for s in scripts:

        proc = Popen(
            [s, tmpfile, event],
            stdout=PIPE, stderr=PIPE
        )

        logging.debug('[{} UTC] Popen with args: {}'.format(datetime.utcnow().strftime("%Y-%m-%d %H:%M:%S"), ' '.join([s, tmpfile, event])))

        stdout, stderr = proc.communicate()

        logging.debug('[{} UTC] Proc (pid: {}) completed with return code: {}'.format(datetime.utcnow().strftime("%Y-%m-%d %H:%M:%S"), proc.pid, proc.returncode))

        ran[basename(s)] = {
            'returncode': proc.returncode,
            'stdout': stdout.decode('utf-8'),
            'stderr': stderr.decode('utf-8'),
        }

        # Log errors if a hook failed
        if proc.returncode != 0:
            logging.error('{} : {} \n{}'.format(
                s, proc.returncode, stderr
            ))

    # Remove temporal file
    remove(tmpfile)

    info = config.get('return_scripts_info', False)
    if not info:
        return dumps({'status': 'done'})

    output = dumps(ran, sort_keys=True, indent=4)
    logging.info(output)

    logging.debug('[{} UTC] Done'.format(datetime.utcnow().strftime("%Y-%m-%d %H:%M:%S")))

    return output


if __name__ == '__main__':
    application.run(debug=True, host='0.0.0.0')
