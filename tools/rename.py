
import MySQLdb as mdb
import logging

if __name__ == '__main__':
    conn = mdb.connect('192.168.1.1', 'pgina', 'heslo77', 'novapgina')
    
    cur = conn.cursor(mdb.cursors.DictCursor)
    
    try:
        cur.execute("RENAME TABLE `user` TO `olduser`;")
        cur.execute("RENAME TABLE `groups` TO `oldgroup`;")
        cur.execute("RENAME TABLE `user_group` TO `oldmship`;")
        logging.info('renamed')
        conn.commit()
    except Exception, e:
        conn.rollback()
        logging.exception(e)