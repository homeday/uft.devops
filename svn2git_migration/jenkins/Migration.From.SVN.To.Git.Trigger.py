from __future__ import print_function
import os
import sys
import yaml
import base64


class InvalidArgument(Exception):
    """An exception indicates an argument is invalid."""
    pass

class FileNotFound(Exception):
    """An exception indicates file is not found."""
    pass


def _load_yaml_file(yaml_file):
    """Load YAML file and return an object represents the content"""

    if not os.path.exists(yaml_file):
        raise FileNotFound('File "{}" is not found.'.format(yaml_file))

    content = None
    with open(yaml_file, 'r') as ymlfile:
        content = yaml.load(ymlfile)

    return content


def _get(obj, field_name, fail_value=None, check=False):
    '''Return the value of the specified field'''

    ret_value = None
    if obj and field_name:
        tmp_value = obj
        for fld in field_name.split('.'):
            if not isinstance(tmp_value, dict):
                raise InvalidArgument('The obj has no such field: {}'.format(field_name))
            tmp_value = tmp_value.get(fld, {})

        if tmp_value:
            ret_value = tmp_value

    if not ret_value:
        if check:
            raise ValueError('The field "{}" is set to be checked and the field value is None or empty'.format(field_name))
        else:
            ret_value = fail_value

    return ret_value


# envs
enable_convert = os.environ.get('Enable_SVN2GIT_Convert', 'false') == 'true'
dry_run = os.environ.get('Dry_Run', 'false') == 'true'
mig_config = os.environ.get('Migration_Config_YAML')
mig_config_file = os.environ.get('Migration_Config_File')
push_git_remote = os.environ.get('Git_Push_RemoteRepo', 'false') == 'true'

if not enable_convert:
    print('SVN to GIT convertion is disabled')
    sys.exit()

# load yaml
if mig_config:
    config_obj = yaml.load(mig_config)

if mig_config_file:
    config_obj = _load_yaml_file(mig_config_file)

if not config_obj:
    raise ValueError('Failed to load YAML configuration')


# generate properties files for every GIT repository found in YAML configuration
svn_server_url = _get(config_obj, 'svn.server_url', check=True)
svn_project = _get(config_obj, 'svn.project', check=True)
svn_trunk = _get(config_obj, 'svn.trunk', check=True)
svn_branches = _get(config_obj, 'svn.branches', [])
svn_rev_start = _get(config_obj, 'svn.revisions.start', 0)
svn_rev_end = _get(config_obj, 'svn.revisions.end', 'HEAD')
github_default_org_name = _get(config_obj, 'git.github.org', check=True)
git_svn_temp_dir = _get(config_obj, 'git_svn.svn_temp_dir', check=True)

for repo_obj in _get(config_obj, 'repos', []):
    repo_name = _get(repo_obj, 'git_name', check=True)
    display_name = _get(repo_obj, 'display_name', repo_name)
    org_name = _get(repo_obj, 'org', github_default_org_name)

    svn_sub_dir_this = _get(repo_obj, 'svn_path_base', '')
    if svn_sub_dir_this: # prepend "/" which is required by Jenkins job
        svn_sub_dir_this = '/{}'.format(svn_sub_dir_this)

    svn_rev_start_this = _get(repo_obj, 'svn_revisions.start', svn_rev_start)
    svn_rev_end_this = _get(repo_obj, 'svn_revisions.end', svn_rev_end)
    if _get(repo_obj, 'skip_history') == True:
        svn_rev_start_this = svn_rev_end_this

    ignore_paths = _get(repo_obj, 'git_svn.ignore_path', '')
    ignore_paths_base64 = ''
    if ignore_paths:
        ignore_paths_base64 = base64.b64encode(ignore_paths.encode('utf-8')).decode('utf-8')

    ignore_addition = _get(repo_obj, 'git_svn.ignore_addition', '')
    ignore_addition_base64 = ''
    if ignore_addition:
        ignore_addition_base64 = base64.b64encode(ignore_addition.encode('utf-8')).decode('utf-8')

    include_paths = _get(repo_obj, 'git_svn.include_path', '')
    include_paths_base64 = ''
    if include_paths:
        include_paths_base64 = base64.b64encode(include_paths.encode('utf-8')).decode('utf-8')

    include_addition = _get(repo_obj, 'git_svn.include_addition', '')
    include_addition_base64 = ''
    if include_addition:
        include_addition_base64 = base64.b64encode(include_addition.encode('utf-8')).decode('utf-8')

    # prepare data written to properties file
    lines = []
    lines.append('SVN_Server={}'.format(svn_server_url))
    lines.append('SVN_Project={}'.format(svn_project))
    lines.append('SVN_trunk={}'.format(svn_trunk))
    lines.append('SVN_Sub_Directory={}'.format(svn_sub_dir_this))
    lines.append('SVN_Include_Branches={}'.format('\\n'.join(svn_branches)))
    lines.append('Revision_Start={}'.format(svn_rev_start_this))
    lines.append('Revision_End={}'.format(svn_rev_end_this))
    lines.append('Git_Ignore_Paths_Base64={}'.format(ignore_paths_base64))
    lines.append('Git_Ignore_Paths_Addition_Base64={}'.format(ignore_addition_base64))
    lines.append('Git_Include_Paths_Base64={}'.format(include_paths_base64))
    lines.append('Git_Include_Paths_Addition_Base64={}'.format(include_addition_base64))
    lines.append('GitHub_Organization={}'.format(org_name))
    lines.append('GitHub_Repository={}'.format(repo_name))
    lines.append('SVN_Migration_Copy_Target={}'.format(git_svn_temp_dir))
    lines.append('Git_Push_RemoteRepo={}'.format(push_git_remote))

    # write to file
    properties_file = 'convert.{}.properties'.format(repo_name)
    with open(properties_file, 'w') as propfile:
        propfile.write('\n'.join(lines))

    print('[{}] Properties file is generated: {}'.format(repo_name, properties_file))

