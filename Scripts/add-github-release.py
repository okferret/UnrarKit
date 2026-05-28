#!/usr/bin/env python3
# -*- coding: UTF-8 -*-

# Usage: add-github-release.py <API token> <repo> <tag being released> <archive path> <release notes>
#
# Creates a release in GitHub for the given tag and uploads the xcframework archive
#

import json
import os
import urllib.request
import sys

def add_release(token, repo, tag, archive_path, notes):
    '''
    Creates a release on GitHub for the given arguments
    '''
    print('token: "{}", repo: "{}", tag: "{}", archive: "{}" notes: "{}"'.format('SECURE' if token else '', repo, tag, archive_path, notes))
    
    assert token, 'No API token given'
    assert repo, 'No repo given'
    assert '/' in repo, "Repo doesn't look like a valid GitHub repo (e.g. abbeycode/UnrarKit)"
    assert tag, 'No tag given'
    assert archive_path, 'No archive path given'
    assert notes, 'No notes given'

    is_beta = tag_is_beta(tag)

    url = 'https://api.github.com/repos/{}/releases'.format(repo)
    headers = {
        'Authorization': 'token {}'.format(token),
        'Content-Type': 'application/json'
    }
    values = {
        'tag_name': tag,
        'name': 'v{}'.format(tag),
        'body': notes,
        'prerelease': True if is_beta else False
    }
    
    data = json.dumps(values).encode('utf-8')
    request = urllib.request.Request(url, data=data, headers=headers)
    with urllib.request.urlopen(request) as response:
        the_page = response.read()
    
    response_dict = json.loads(the_page)
    upload_url = response_dict['upload_url']
    release_url = response_dict['url']
    
    upload_xcframework_archive(token, upload_url, archive_path)

    print('Release added: {}'.format(release_url))
    return True

def tag_is_beta(tag):
    '''
    Returns True if the tag contains a label indicating it's a beta build
    
    >>> tag_is_beta('1.2.3')
    False
    >>> tag_is_beta('1.2.3-beta')
    True
    >>> tag_is_beta('1.2.3-beta2')
    True
    >>> tag_is_beta('1.2.3-RC')
    True
    >>> tag_is_beta('1.2.3-RC1')
    True
    >>> tag_is_beta('1.2.3-prerelease')
    True
    >>> tag_is_beta('1.2.3-prerelease2')
    True
    >>> tag_is_beta('1.2.3-alpha')
    True
    >>> tag_is_beta('1.2.3-alpha2')
    True
    '''
    
    return 'beta' in tag or 'RC' in tag or 'prerelease' in tag or 'alpha' in tag

def upload_xcframework_archive(token, upload_url, archive_path):
    '''
    Uploads the xcframework archive at the given path to GitHub for the release specified
    '''
    
    upload_url = upload_url.split('{')[0]
    archive_name = os.path.basename(archive_path)
    url = '{}?name={}'.format(upload_url, archive_name)
    headers = {
        'Authorization': 'token {}'.format(token),
        'Content-Type': 'application/zip',
        'Content-Length': str(os.path.getsize(archive_path))
    }

    with open(archive_path, 'rb') as f:
        data = f.read()
    
    request = urllib.request.Request(url, data=data, headers=headers)
    with urllib.request.urlopen(request) as response:
        page = response.read()
    
    response_dict = json.loads(page)
    return True

    
if __name__ == '__main__':
    # Allow script to be called with 'test' argument
    if len(sys.argv) == 2 and sys.argv[1].lower() == 'test':
        import doctest
        result = doctest.testmod()
        sys.exit(0 if result.failed == 0 else 1)

    expected_arg_count = 6

    if len(sys.argv) != expected_arg_count:
        print('\nadd-github-release given {} arguments ({}). Expecting {}\n'.format(len(sys.argv) - 1, sys.argv[1:], expected_arg_count - 1))
        sys.exit(1)

    exit_code = 0 if add_release(*sys.argv[1:]) else 1
    sys.exit(exit_code)
