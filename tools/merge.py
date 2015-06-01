
import MySQLdb as mdb
import logging


def authGroupId2sysGroupId(sysGId, cur):
    cur.execute("""
    SELECT group_id FROM oldgroup WHERE group_name=(
        SELECT name FROM auth_group where id=%s
    )""", (sysGId, ) )
    return cur.fetchone()['group_id']

def createMships(user, cur):
    cur.execute("""
    SELECT `group_id` FROM oldmship where user_id=%s
    """, [user['user_id']])
    mship = set()
    for g in cur.fetchall():
        mship.add(g['group_id'])

    # projdi auth mships raci pro jistotu (mship je set kvuli duplititam)
    cur.execute("""
    SELECT group_id FROM auth_user_groups where user_id=%s
    """, [user['id']])

    for ag in cur.fetchall():
        sysGId = authGroupId2sysGroupId(ag['group_id'], cur)
        mship.add(sysGId)

    gid = user['gid'] or user['gid_id'] or None
    # kdyby byl GID none a existovali mships, tak se popne a da do GID
    if gid is None and len(mship) > 0:
        gid = mship.pop()
    elif gid is not None:
        if gid in mship:
            mship.remove(gid)

    return gid, mship

def processUser(user, cur):
    logging.info("processing %s" % user['username'])

    gid, mships = createMships(user, cur)

    if gid is None:
        logging.warn("skipping %s, has no group" % user['username'])
        return

    if not user['realname']:
        user['realname'] = "%s %s" % (user['first_name'], user['last_name'])

    cur.execute("""INSERT INTO users
    (
        id, username, realname, email, gid, password,
        status, user, hash_method, unixpwd, createdAt, updatedAt
    )
    VALUES(%s, %s, %s, %s, %s, %s, %s, %s, %s, %s, %s, %s)
    """, (
        user['user_id'],
        user['username'],
        user['realname'],
        user['email'],
        gid,
        user['o.password'],
        user['status'],
        user['user'],
        user['hash_method'],
        user['unixpwd'],
        user['date_joined'],
        user['last_login']
    ))

    for ms in mships:
        cur.execute("""
        INSERT INTO usergroup_mship
        (UserId, GroupId) VALUES (%s, %s)
        """, (user['user_id'], ms))


if __name__ == '__main__':
    logging.basicConfig(level=logging.DEBUG)
    conn = mdb.connect('192.168.1.1', 'pgina', 'heslo77', 'novapgina')

    cur = conn.cursor(mdb.cursors.DictCursor)

    cur.execute("""
    SELECT o.group_id as id, a.name as name
    FROM auth_group as a LEFT JOIN oldgroup as o ON o.group_name = a.name
    """)
    for g in cur.fetchall():
        cur.execute("""
        INSERT INTO groups (id, name) VALUES (%s, %s)
        """, (g['id'], g['name']) )

    cur.execute("""SELECT *
    FROM `auth_user` as u LEFT JOIN `olduser` as o
    ON o.user_name = u.`username`
    """)
    for u in cur.fetchall():
        try:
            processUser(u, cur)
            logging.info("user %s processed ..." % u['username'])
        except Exception, e:
            logging.error("error during %s processing:" % u['username'])
            logging.exception(e)

    # upravit sequence
    cur.execute("select max(id)+1 as m from user")
    maxUID = cur.fetchone()['m']
    cur.execute("ALTER TABLE users AUTO_INCREMENT = %s", (maxUID, ));
    cur.execute("select max(id)+1 as m from group")
    maxUID = cur.fetchone()['m']
    cur.execute("ALTER TABLE groups AUTO_INCREMENT = %s", (maxUID, ));

    conn.commit()
    logging.info("DONE ...")
