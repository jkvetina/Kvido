# coding: utf-8
import sys, os, csv, time, pickle, argparse, datetime
import collections, multiprocessing, itertools, timeit, glob, re

sys.path.append(os.getcwd())
from oracle_wrapper import Oracle

#
# cd ~/Documents/JOB/DPP_UAT/python; source DPP/bin/activate
# cd ~/Documents/PROJECTS/GITHUB/BUG/python
# python wiki.py "../../BUG.wiki/*.md"
#

target  = sys.argv[1]



#
# CONNECTION STRING
#
db_conf_file = os.path.dirname(os.path.realpath(__file__)) + '/db.conf'
tns = {}
with open(db_conf_file, 'rb') as f:
  tns = pickle.load(f)



#
# CONNECT TO ORACLE
#
print('=' * 80)
print('CONNECTING TO ORACLE:', tns['host'], '\n')
ora = Oracle(tns)

ora.execute('BEGIN ctx.set_session(\'JKVETINA\', in_contexts => \'\'); bug.log_module(\'WIKI\'); END;')
data    = ora.fetch('SELECT bug.get_log_id() FROM DUAL')
log_id  = data[0][0]



#
# CREATE MISSING FILES
#
data = ora.fetch_assoc("""
SELECT
    LOWER(REPLACE(object_type, 'MATERIALIZED VIEW', 'VIEW') || 'S-' || object_name) || '.md' AS file_name
FROM user_objects
WHERE object_type IN (
        'TABLE',
        --'PACKAGE',
        'PROCEDURE',
        'VIEW',
        'MATERIALIZED VIEW',
        'JOB'
    )
    AND object_name NOT LIKE 'DBMS%'
    AND object_name NOT LIKE 'PLSQL%'
    AND object_name NOT LIKE '%\_E$' ESCAPE '\\'
UNION ALL
SELECT DISTINCT LOWER('PACKAGES-' || object_name || '.' || procedure_name) || '.md'
FROM user_procedures
WHERE object_name IN (
        'CTX', 'BUG'
    )
    AND procedure_name IS NOT NULL
ORDER BY 1
""")
for row in data:
  file_name = '{}/{}'.format('/'.join(target.split('/')[0:-1]), row.file_name)
  if not os.path.exists(file_name):
    with open(file_name, 'w'):
      pass



#
# PACKAGES OVERVIEW
#
data = ora.fetch_assoc("""
SELECT DISTINCT LOWER('PACKAGES-' || object_name) || '.md' AS file_name, object_name
FROM user_objects
WHERE object_name IN (
        'CTX', 'BUG'
    )
ORDER BY 1
""")
#
packages = []
for row in data:
  file_name = '{}/{}'.format('/'.join(target.split('/')[0:-1]), row.file_name)
  with open(file_name, 'w') as f:
    packages.append(file_name)
    query = "BEGIN wiki.desc_package('{}'); END;".format(row.object_name)
    fresh = ora.get_output(query)
    #print(query, len(fresh))
    if fresh and len(fresh):
      for line in fresh:
        if line == None:
          line = ''
        f.write(line + '\n')
      f.write('\n')



end_tag = '<!-- END -->'

#
# GO THRU FILES IN TARGET DIR
#
files   = glob.glob(target)
print('TARGET:', target, len(files))
for file in sorted(files):
  if not ('-' in file.split('/')[-1]):
    continue
  if file in packages:
    continue

  # get object type and name from filename
  object_type, object_name = file.split('/')[-1].replace('.md', '').split('-')
  print('  ', object_type, object_name)

  object_       = object_name.split('.')
  package_name  = object_[0]
  module_name   = object_[1] if len(object_) > 1 else object_[0]

  this__ = object_name
  spec__ = "../blob/master/{}/{}.spec.sql#{}".format(object_type, package_name, module_name)
  body__ = "../blob/master/{}/{}.sql#{}".format(object_type, package_name, module_name)

  # modify file content
  out     = []
  hook    = None  # ignore lines until hook is found
  #
  with open(file) as f:
    for i, line in enumerate(f):
      if hook != None and not (hook in line):  # ignore lines between START and END
        continue
      if hook != None and hook in line:  # reset hook when END found
        hook = None

      line = line.replace('<!-- $this -->', this__);
      line = line.replace('<!-- $spec -->', spec__);
      line = line.replace('<!-- $body -->', body__);

      out.append(line)

      # include table description
      if '<!-- TABLE -->' in line or '<!-- desc_table(' in line:
        hook  = end_tag  # ignore next lines until hook is found
        fresh = ora.get_output("BEGIN wiki.desc_table('{}'); END;".format(object_name))
        #
        out.append('\n'.join(fresh) + '\n')

      if '<!-- VIEW -->' in line or '<!-- desc_view(' in line:
        hook  = end_tag  # ignore next lines until hook is found
        fresh = ora.get_output("BEGIN wiki.desc_view('{}'); END;".format(object_name))
        #
        out.append('\n```sql\n{};\n```\n'.format('\n'.join(fresh).rstrip()))

      if ('<!-- SIGNATURE ' in line or '<!-- SOURCE_CODE ' in line) or '<!-- desc_spec(' in line or '<!-- desc_body(' in line:
        hook      = end_tag  # ignore next lines until hook is found
        overload  = 1
        m         = re.search(',\s*(\d+)[)]\s*-->', line)
        if m:
          overload = m.group(1) or 1

        if '<!-- SIGNATURE ' in line or '<!-- desc_spec(' in line:
          query   = "BEGIN wiki.desc_spec('{}', {}); END;".format(object_name, overload)
          fresh   = ora.get_output(query)[1]
          #print(query, len(fresh))
          if fresh and len(fresh):
            fresh = re.sub('\n    ', '\n', fresh)[4:]
            #
            out.append('\n```sql\n{}```\n'.format(fresh))

        if '<!-- SOURCE_CODE ' in line or '<!-- desc_body(' in line:
          query   = "BEGIN wiki.desc_body('{}', {}); END;".format(object_name, overload)
          fresh   = ora.get_output(query)[1]
          #print(query, len(fresh))
          if fresh and len(fresh):
            fresh = re.sub('\n    ', '\n', fresh)[4:]
            #
            out.append('<details><summary>Show code ({} lines)</summary><p>\n'.format(fresh.count('\n')))
            out.append('\n```sql\n{}```\n'.format(fresh))
            out.append('</p></details>\n')

    # check new content
    #for i, line in enumerate(out):
    #  print('{}: {}'.format(i, line.rstrip()))

  # update file
  with open(file, 'w') as f:
    f.write(''.join(out))



ora.execute('BEGIN bug.update_timer(bug.get_root_id({})); END;'.format(log_id))

print()

