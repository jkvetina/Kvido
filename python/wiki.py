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

ora.execute('BEGIN bug.log_module(); ctx.init(\'JKVETINA\'); END;')
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
# GO THRU FILES IN TARGET DIR
#
files   = glob.glob(target)
print('TARGET:', target, len(files))
for file in sorted(files):
  if not ('-' in file.split('/')[-1]):
    continue

  # get object type and name from filename
  object_type, object_name = file.split('/')[-1].replace('.md', '').split('-')
  print('  ', object_type, object_name)

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

      out.append(line)

      # include table description
      if '<!-- TABLE -->' in line:
        hook  = '<!-- END -->'  # ignore next lines until hook is found
        fresh = ora.get_output("BEGIN wiki.desc_table('{}'); END;".format(object_name))
        #
        out.append('\n'.join(fresh) + '\n')

      if '<!-- VIEW -->' in line:
        hook  = '<!-- END -->'  # ignore next lines until hook is found
        fresh = ora.get_output("BEGIN wiki.desc_view('{}'); END;".format(object_name))
        #
        out.append('\n```sql\n{};\n```\n'.format('\n'.join(fresh).rstrip()))

      if ('<!-- SIGNATURE ' in line or '<!-- SOURCE_CODE ' in line):
        hook      = '<!-- END -->'  # ignore next lines until hook is found
        fp        = '%'
        if '<!-- SOURCE_CODE P' in line: fp = 'P'
        if '<!-- SOURCE_CODE F' in line: fp = 'F'
        #
        overload  = 1
        m         = re.search('\s(\d+)\s*-->', line)
        if m:
          overload = m.group(1) or 1

        if '<!-- SIGNATURE ' in line:
          query   = "BEGIN wiki.desc_spec('{}', '{}', {}); END;".format(object_name, fp, overload)
          fresh   = ora.get_output(query)[1]
          print(query, len(fresh))
          fresh   = re.sub('\n    ', '\n', fresh)[4:]
          #
          out.append('\n```sql\n{}```\n'.format(fresh))

        if '<!-- SOURCE_CODE ' in line:
          query   = "BEGIN wiki.desc_body('{}', '{}', {}); END;".format(object_name, fp, overload)
          fresh   = ora.get_output(query)[1]
          print(query, len(fresh))
          fresh   = re.sub('\n    ', '\n', fresh)[4:]
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

